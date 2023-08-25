//
//  BLEPacketsManager.swift

import Foundation
import Combine

class BLEPacketsManager {
    private var cancellables: Set<AnyCancellable> = []

    private lazy var accelerationService: MotionAccelerationService = {
        let service = MotionAccelerationService(accelerationUpdateInterval: 1.0)
        return service
    }()

    private lazy var locationService: LocationService = LocationService()

    var pacingReceiver: PacketsPacing?

    init(pacingReceiver: PacketsPacing?) {
        self.pacingReceiver = pacingReceiver
    }

    func subscribeToBLEpacketsPublisher(publisher: AnyPublisher<BLEPacket, Never>) {
        publisher.sink {[weak self] packet in
            self?.handleBLEPacket(packet)
        }.store(in: &cancellables)
    }

    func start() {
        tryToStartAccelerometerUpdates()
        startLocationService()
    }
    // MARK: - Setup
    private func tryToStartAccelerometerUpdates() {
        do {
            try accelerationService.startUpdates()
        } catch let error {
            if let handledError = error as? ValueReadingError {
                switch handledError {
                case .notFound:
                    break
                case .invalidValue(let optionalMessage):
                    print("PixelService accelerometer is already working: \(optionalMessage ?? "-")")
                case .missingRequiredValue(let optionalMessage):
                    print("PixelService accelerometer not availableError: \(optionalMessage ?? "-")")
                }
            } else {
                print("PixelService Unknown error while trying to start accelerometer updates: \(error)")
            }
        }
    }

    private func startLocationService() {
        locationService.startLocationUpdates()
        locationService.startRanging()
    }

    private func stopLocationService() {
        locationService.stopLocationUpdates()
        locationService.stopRanging()
    }

    private func handleBLEPacket(_ packet: BLEPacket) {
        let data: Data = packet.data

        if BeaconDataReader.isBeaconDataGWtoBridgeMessage(data) || BeaconDataReader.isBeaconDataBridgeToGWmessage(data) {
            return
        }

        handlePixelPacket(packet)
    }

    private func handlePixelPacket(_ blePacket: BLEPacket) {
//        print("BLEPacketsManager: \(blePacket.data.hexEncodedString(options: .upperCase)) - from - \(blePacket.uid.uuidString)")

        let accelerationData = self.accelerationService.currentAcceleration
        var location: Location?
        if let clLocaton = locationService.lastLocation {
            location = Location(latitude: clLocaton.coordinate.latitude, longtitude: clLocaton.coordinate.longitude)
        }
        
        let payloadStr = blePacket.data.hexEncodedString(options: .upperCase)
        if let payloadJSONString = createPayloadJSONString(payloadValue: payloadStr) {
            // Use the payloadJSONString as needed, like sending it in a network request
            //print("payload string: \(payloadJSONString)")
            sendPacketsToLivingweb(payloadString: payloadJSONString) { externalId, error in
                if let externalId = externalId {
                    //print("External ID: \(externalId)")
                    if externalId == "unknown" {
                            // Handle the case when externalId is "unknown"
                            //print("External ID is unknown")
                        } else {
                            // Handle the case when externalId is a valid value
                            print("Resolve API Asset ID: \(externalId)")
                        }
                } else if let error = error {
                    print("Error: \(error)")
                } else {
                    print("Unknown error occurred.")
                }
            }
        }
        
        let bleUUID = blePacket.uid

        let packet = TagPacketData(payload: payloadStr,
                            timestamp: blePacket.timeStamp,
                            location: location,
                            acceleration: accelerationData,
                            bridgeId: nil,
                            groupId: nil,
                            sequenceId: 0,
                            nfpkt: nil,
                            rssi: blePacket.rssi)

        pacingReceiver?.receivePacketsByUUID([bleUUID: packet])
    }
    

}
