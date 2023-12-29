import Foundation

@_cdecl("initialize")
public func initialize(appToken: UnsafePointer<CChar>?, ownerID: UnsafePointer<CChar>?) {
    let token = String(cString: appToken!)
    let id = String(cString: ownerID!)
    WiliotGatewayBLEConnection.initialize(appToken: token, ownerID: id)
}

@_cdecl("openAppSettings")
public func openAppSettings() {
    WiliotGatewayBLEConnection.openAppSettings()
}

@_cdecl("observeStatusChanges")
public func observeStatusChanges() {
    WiliotGatewayBLEConnection.observeStatusChanges()
        .receive(on: DispatchQueue.main)
        .sink { statusString in
            // Handle the received statusString
            print("Received status: \(statusString)")
    }.store(in: &WiliotGatewayBLEConnection.cancellables)
}

@_cdecl("connectionPublisher")
public func connectionPublisher() {
    // Call the connectionPublisher method and handle the received value
    WiliotGatewayBLEConnection.connectionPublisher
        .receive(on: DispatchQueue.main)
        .sink { isConnected in
        if isConnected {
            WiliotGatewayBLEConnection.gatewayConnectionEstablished!(true)
            print("Gateway Connected")
        } else {
            WiliotGatewayBLEConnection.gatewayConnectionEstablished!(false)
            print("Gateway not connected")
        }
    }.store(in: &WiliotGatewayBLEConnection.cancellables)
}

@_cdecl("checkDevicePermissionsStatus")
public func checkDevicePermissionsStatus() {
    // iOS 17 CLLOcationManagerDelegate is not talking to Unity
    // after updating the Location Permissions
    // That's why, we manually request the location
    // permission state when the app is resumed
    // Meaning the location pop-up window is closed
    WiliotGatewayBLEConnection.checkDevicePermissionsStatus()
}


@_cdecl("bleActivityPublisher")
public func bleActivityPublisher() {
    // Call the static bleActivityPublisher method from WiliotGatewayBLEConnection
    WiliotGatewayBLEConnection.bleActivityPublisher()
        .receive(on: DispatchQueue.main)
        .sink { floatValue in
        // Process the received value
        print("Received ble activity value: \(floatValue)")
        
        if floatValue > 0 {
            // Successfull Bluetooth connection
            print("Bluetooth Connected")
            WiliotGatewayBLEConnection.bluetoothConnectionEstablished!(true)
        } else {
            // Not connected
            print("Bluetooth Not Connected")
            WiliotGatewayBLEConnection.bluetoothConnectionEstablished!(false)
        }
    }.store(in: &WiliotGatewayBLEConnection.cancellables)
}

@_cdecl("checkAndRequestBluetoothPermissions")
public func checkAndRequestBluetoothPermissions() {
    // Request system permissions using the exposed function
    WiliotGatewayBLEConnection.checkAndRequestBluetoothPermissions();
}

@_cdecl("checkAndRequestLocationPermissions")
public func checkAndRequestLocationPermissions() {
    // Request system permissions using the exposed function
    WiliotGatewayBLEConnection.checkAndRequestLocationPermissions();
}

@_cdecl("checkAndRequestCameraPermissions")
public func checkAndRequestCameraPermissions() {
    // Request system permissions using the exposed function
    WiliotGatewayBLEConnection.checkAndRequestCameraPermissions();
}

@_cdecl("subscribeToPermissionUpdates")
public func subscribeToPermissionUpdates() {
    // Request system permissions using the exposed function
    WiliotGatewayBLEConnection.subscribeToPermissionUpdates { (granted, message) in
        // Handle the result of the permission request
        if granted {
            // Permissions granted, handle accordingly
            print("Permission granted")
            //WiliotGatewayBLEConnection.systemPermissionsGranted!(true)
        } else {
            // Permissions not granted, handle accordingly
            print("Permission not granted")
            //WiliotGatewayBLEConnection.systemPermissionsGranted!(false)
        }
    }
}

@_cdecl("subscribeToBluetoothPermissionUpdates")
public func subscribeToBluetoothPermissionUpdates() {
    // Request system permissions using the exposed function
    WiliotGatewayBLEConnection.subscribeToBluetoothPermissionUpdates { (granted, message) in
        // Handle the result of the permission request
        if granted {
            // Permissions granted, handle accordingly
            print("WiliotGatewayBLEConnectionBridge Bluetooth Permission granted")
            //WiliotGatewayBLEConnection.bluetoothPermissionsGranted!(true)
        } else {
            // Permissions not granted, handle accordingly
            print("WiliotGatewayBLEConnectionBridge Bluetooth Permission not granted")
            //WiliotGatewayBLEConnection.bluetoothPermissionsGranted!(false)
        }
    }
}

@_cdecl("subscribeToLocationPermissionUpdates")
public func subscribeToLocationPermissionUpdates() {
    // Request system permissions using the exposed function
    WiliotGatewayBLEConnection.subscribeToLocationPermissionUpdates { (granted, message) in
        // Handle the result of the permission request
        if granted {
            // Permissions granted, handle accordingly
            print("WiliotGatewayBLEConnectionBridge Location Permission granted")
            //WiliotGatewayBLEConnection.locationPermissionsGranted!(true)
        } else {
            // Permissions not granted, handle accordingly
            print("WiliotGatewayBLEConnectionBridge Location  Permission not granted")
            //WiliotGatewayBLEConnection.locationPermissionsGranted!(false)
        }
    }
}

@_cdecl("subscribeToCameraPermissionUpdates")
public func subscribeToCameraPermissionUpdates() {
    // Request system permissions using the exposed function
    WiliotGatewayBLEConnection.subscribeToCameraPermissionUpdates { (granted, message) in
        // Handle the result of the permission request
        if granted {
            // Permissions granted, handle accordingly
            print("WiliotGatewayBLEConnectionBridge Camera Permission granted")
            //WiliotGatewayBLEConnection.locationPermissionsGranted!(true)
        } else {
            // Permissions not granted, handle accordingly
            print("WiliotGatewayBLEConnectionBridge Camera  Permission not granted")
            //WiliotGatewayBLEConnection.locationPermissionsGranted!(false)
        }
    }
}

@_cdecl("connectToGatewayService")
public func connectToGatewayService() {
    // Request system permissions using the exposed function
    WiliotGatewayBLEConnection.connectToGatewayService { (granted, message) in
        // Handle the result of the permission request
        if granted {
            // Permissions granted, handle accordingly
            print("Gateway Connection Established")
        } else {
            // Permissions not granted, handle accordingly
            print("Gateway Connection NOT Established")
        }
    }
}

@_cdecl("subscribeToMessageSent")
public func subscribeToMessageSent() {
    WiliotGatewayBLEConnection.subscribeToMessageSentAction {
            print("sent Tags Info at: \(Date())")
        }
}

@_cdecl("cancelAllSubscriptions")
public func cancelAllSubscriptions() {
    WiliotGatewayBLEConnection.cancelAllSubscriptions()
}

@_cdecl("tagIDResolved")
public func tagIDResolved(tagIDResolvedDelegate: @convention(c) @escaping (UnsafePointer<CChar>, Int) -> Void) {
    ResolveAPI.tagIDResolved = tagIDResolvedDelegate
}

@_cdecl("bluetoothConnectionEstablished")
public func bluetoothConnectionEstablished(bluetoothConnectionEstablishedDelegate: @convention(c) @escaping (Bool) -> Void) {
    WiliotGatewayBLEConnection.bluetoothConnectionEstablished = bluetoothConnectionEstablishedDelegate
}

@_cdecl("gatewayConnectionEstablished")
public func gatewayConnectionEstablished(gatewayConnectionEstablishedDelegate: @convention(c) @escaping (Bool) -> Void) {
    WiliotGatewayBLEConnection.gatewayConnectionEstablished = gatewayConnectionEstablishedDelegate
}

@_cdecl("locationPermissionsGranted")
public func locationPermissionsGranted(locationPermissionsGrantedDelegate: @convention(c) @escaping (Bool) -> Void) {
    WiliotGatewayBLEConnection.locationPermissionsGranted = locationPermissionsGrantedDelegate
}

@_cdecl("bluetoothPermissionsGranted")
public func bluetoothPermissionsGranted(bluetoothPermissionsGrantedDelegate: @convention(c) @escaping (Bool) -> Void) {
    WiliotGatewayBLEConnection.bluetoothPermissionsGranted = bluetoothPermissionsGrantedDelegate
}

@_cdecl("cameraPermissionsGranted")
public func cameraPermissionsGranted(cameraPermissionsGrantedDelegate: @convention(c) @escaping (Bool) -> Void) {
    WiliotGatewayBLEConnection.cameraPermissionsGranted = cameraPermissionsGrantedDelegate
}

@_cdecl("systemPermissionsGranted")
public func systemPermissionsGranted(systemPermissionsGrantedDelegate: @convention(c) @escaping (Bool) -> Void) {
    WiliotGatewayBLEConnection.systemPermissionsGranted = systemPermissionsGrantedDelegate
}

