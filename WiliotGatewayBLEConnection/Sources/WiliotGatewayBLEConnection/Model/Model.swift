import Foundation
import Combine

/// plist value reading key
private let kAPPTokenKey = "app_token"
/// plist value reading key
private let kOwnerIdKey = "owner_id"

@objc public class Model: NSObject {
    var permissionsPublisher: AnyPublisher<Bool, Never> {
        _permissionsPublisher.eraseToAnyPublisher()
    }
    
    var bluetoothPermissionsPublisher: AnyPublisher<Bool, Never> {
        _bluetoothPermissionsPublisher.eraseToAnyPublisher()
    }
    
    var cameraPermissionsPublisher: AnyPublisher<Bool, Never> {
        _cameraPermissionsPublisher.eraseToAnyPublisher()
    }
    
    var locationPermissionsPublisher: AnyPublisher<Bool, Never> {
        _locationPermissionsPublisher.eraseToAnyPublisher()
    }

    var statusPublisher: AnyPublisher<String, Never> {
        return _statusPublisher.eraseToAnyPublisher()
    }
    var connectionPublisher: AnyPublisher<Bool, Never> {
        return _mqttConnectionPublisher.eraseToAnyPublisher()
    }
    var bleActivityPublisher: AnyPublisher<Float, Never> {
        return _bleScannerPublisher.eraseToAnyPublisher()
    }
    var messageSentActionPubliosher: AnyPublisher<Void, Never> {
        return _mqttSentMessagePublisher.eraseToAnyPublisher()
    }

    private let _statusPublisher: CurrentValueSubject<String, Never> = .init("")
    private let _mqttConnectionPublisher: CurrentValueSubject<Bool, Never> = .init(false)
    private let _bleScannerPublisher: CurrentValueSubject<Float, Never> = .init(0.0)
    private let _permissionsPublisher: PassthroughSubject<Bool, Never> = .init()
    private let _bluetoothPermissionsPublisher: PassthroughSubject<Bool, Never> = .init()
    private let _locationPermissionsPublisher: PassthroughSubject<Bool, Never> = .init()
    private let _cameraPermissionsPublisher: PassthroughSubject<Bool, Never> = .init()

    private let _mqttSentMessagePublisher: PassthroughSubject<Void, Never> = .init()

    public var appToken = ""
    public var ownerId = ""
    private var gatewayService: MobileGatewayService?
    private var bleService: BLEService?
    private var blePacketsmanager: BLEPacketsManager?
    private var networkService: NetworkService?
    private var bluetoothPermissionsCompletionCancellable: AnyCancellable?
    var locationPermissionsCompletionCancellable: AnyCancellable?
    private var cameraPermissionsCompletionCancellable: AnyCancellable?


    // MARK: -
    override init() {
        super.init()
    }

    func prepare(completion: @escaping (() -> Void)) {
        if gatewayService == nil {

            let netService = NetworkService(appKey: appToken,
                                            ownerId: ownerId)

            let gwService = MobileGatewayService(ownerId: ownerId,
                                                 authTokenRequester: netService,
                                                 gatewayRegistrator: netService)

            gwService.didConnectCompletion = {[weak self] connected in
                self?._mqttConnectionPublisher.send(connected)
            }

            gwService.didStopCompletion = {[weak self] in
                self?._mqttConnectionPublisher.send(false)
            }

            gwService.authTokenCallback = {[weak self] optionalError in
                guard let self = self else {
                    return
                }

                if let error = optionalError {
                    self._statusPublisher.send(error.localizedDescription)
                    completion()
                    return
                }
                self._statusPublisher.send("Auth token received")

                completion()
            }

            self.gatewayService = gwService
            gwService.obtainAuthToken()
        }
    }

    func canStart() -> Bool {
        print("model canStart 1")
        if Permissions.instance.bluetoothCanBeUsed && Permissions.instance.locationCanBeUsed && !appToken.isEmpty && !ownerId.isEmpty && self.gatewayService?.authToken != nil {
            print("model canStart 2")
            return true
        }
        print("Gateway cannot be started. \n bluetoothCanBeUsed = \(Permissions.instance.bluetoothCanBeUsed) \n locationCanBeUsed = \(Permissions.instance.locationCanBeUsed)")
        print("model canStart 3")
        return false
    }
    
    func checkDevicePermissionsStatus() {
        Permissions.instance.checkAuthStatus()
    }

    func start() {
        _statusPublisher.send("Starting Connection and BLE scan")
        startGateway()
        startBLE()
    }
    
    // Function to check and request Camera permissions
    public func checkAndRequestCameraPermissions() {
        // Check if Camera permissions are already granted
        guard !Permissions.instance.cameraCanBeUsed else {
            handleCameraPermissionsRequestsCompletion(true)
            return
        }

        // Set up the subscription for permissions
        self.cameraPermissionsCompletionCancellable =
        Permissions.instance.$cameraCanBeUsed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] granted in
                guard let weakSelf = self else { return }

                weakSelf.handleCameraPermissionsRequestsCompletion(granted)

                if granted {
                    print("Camera Permissions granted")
                    weakSelf.cameraPermissionsCompletionCancellable = nil
                } else {
                    print("Camera Permissions not granted")
                }
            }
        // Request Camera permissions
        Permissions.instance.requestCameraAuth()
    }
    
    // Function to check and request Bluetooth permissions
    public func checkAndRequestBluetoothPermissions() {
        // Check if Bluetooth permissions are already granted
        guard !Permissions.instance.bluetoothCanBeUsed else {
            handleBluetoothPermissionsRequestsCompletion(true)
            return
        }

        // Set up the subscription for permissions
        self.bluetoothPermissionsCompletionCancellable =
        Permissions.instance.$bluetoothCanBeUsed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] granted in
                guard let weakSelf = self else { return }

                weakSelf.handleBluetoothPermissionsRequestsCompletion(granted)

                if granted {
                    print("Bluetooth Permissions granted")
                    weakSelf.bluetoothPermissionsCompletionCancellable = nil
                } else {
                    print("Bluetooth Permissions not granted")
                }
            }

        Permissions.instance.requestBluetoothAuth()
    }

    // Function to check and request Location permissions
    public func checkAndRequestLocationPermissions() {
        // Check if Location permissions are already granted
        guard !Permissions.instance.locationCanBeUsed else {
            print("INSIDE guard !Permissions.instance.locationCanBeUsed else. Early return")
            handleLocationPermissionsRequestsCompletion(true)
            return
        }

        // Set up the subscription for permissions
        self.locationPermissionsCompletionCancellable =
            Permissions.instance.$locationCanBeUsed
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("iOS locationPermissionsCompletionCancellable Combine Finished")
                    break
                case .failure(let error):
                    print("iOS locationPermissionsCompletionCancellable Combine Error: \(error)")
                }
            }, receiveValue: { granted in
                // Your logic here
                self.handleLocationPermissionsRequestsCompletion(granted)

                if granted {
                    print("Location Permissions granted")
                    self.locationPermissionsCompletionCancellable = nil
                } else {
                    print("Location Permissions not granted")
                }
            })
        

        // Request Location permission
        Permissions.instance.requestLocationAuth()
    }
    
    private func handleCameraPermissionsRequestsCompletion(_ granted: Bool) {
        _cameraPermissionsPublisher.send(granted)
        handlePermissionsRequestsCompletion(Permissions.instance.nativePermissionsGranted)
        if let permission = WiliotGatewayBLEConnection.cameraPermissionsGranted {
            print("handleCameraPermissionsRequestsCompletion value: \(granted)")
            permission(granted)
        }
        
    }

    
    private func handleBluetoothPermissionsRequestsCompletion(_ granted: Bool) {
        _bluetoothPermissionsPublisher.send(granted)
        handlePermissionsRequestsCompletion(Permissions.instance.nativePermissionsGranted)
        if let permission = WiliotGatewayBLEConnection.bluetoothPermissionsGranted {
            print("handleBluetoothPermissionsRequestsCompletion value: \(granted)")
            permission(granted)
        }
        
    }
    
    private func handleLocationPermissionsRequestsCompletion(_ granted: Bool) {
        _locationPermissionsPublisher.send(granted)
        handlePermissionsRequestsCompletion(Permissions.instance.nativePermissionsGranted)
        if let permission = WiliotGatewayBLEConnection.locationPermissionsGranted {
            print("handleLocationPermissionsRequestsCompletion value: \(granted)")
            permission(granted)
        }
    }

    private func handlePermissionsRequestsCompletion(_ granted: Bool) {
        if !granted {
            _statusPublisher.send("No required BLE or Location Permissions.instance.")
        }
        
        _statusPublisher.send("Device permissions granted: handlePermissionsRequestsCompletion")
        if let permission = WiliotGatewayBLEConnection.systemPermissionsGranted {
            print("handlePermissionsRequestsCompletion value: \(granted)")
            permission(granted)
        }
        _permissionsPublisher.send(granted)
    }

    // MARK: -

    private func startGateway() {
        guard let gatewayService = self.gatewayService,
              let authToken = gatewayService.authToken else {
            return
        }

        gatewayService.gatewayTokensCallBack = {[weak self] optionalError in
            guard let self = self else { return }

            if let error = optionalError {
                self._statusPublisher.send("Error obtaining connectionTokens: \(error)")
                return
            }

            self._statusPublisher.send("Obtained connection tokens")
            if let gwService = self.gatewayService,
               let accessToken = gwService.gatewayAccessToken {

                _ = gatewayService.startConnection(withGatewayToken: accessToken)
            }

        }

        gatewayService.registerAsGateway(userAuthToken: authToken, ownerId: ownerId)

    }

    private func startBLE() {

        _bleScannerPublisher.send(0.0)
        let bleService = BLEService()
        self.bleService = bleService

        var pacingObject: PacketsPacing?

        if let gwService = self.gatewayService {
            let pacingService = PacketsPacingService(with: WeakObject(gwService))
            pacingObject = pacingService

            gwService.setSendEventSignal {[weak self] in
                self?._mqttSentMessagePublisher.send(())
            }
        }

        let bleManager = BLEPacketsManager(pacingReceiver: pacingObject)

        self.blePacketsmanager = bleManager
        bleManager.subscribeToBLEpacketsPublisher(publisher: bleService.packetPublisher)
        bleManager.start()

        bleService.setScanningMode(inBackground: false)
        bleService.startListeningBroadcasts()
        gatewayService?.setBLEPacketsManager(blePacketsmanager)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {[unowned self] in
            _bleScannerPublisher.send(0.5)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {[unowned self] in
            _bleScannerPublisher.send(1.0)
        }
    }

}
