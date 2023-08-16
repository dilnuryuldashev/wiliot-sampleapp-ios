import Foundation

@_cdecl("initialize")
public func initialize(appToken: String, ownerID: String) {
    WiliotGatewayBLEConnection.initialize(appToken: appToken, ownerID: ownerID)
}

@_cdecl("observeStatusChanges")
public func observeStatusChanges() {
    WiliotGatewayBLEConnection.observeStatusChanges().sink { statusString in
            // Handle the received statusString
            print("Received status: \(statusString)")
    }.store(in: &WiliotGatewayBLEConnection.cancellables)
}

@_cdecl("connectionPublisher")
public func connectionPublisher() {
    // Call the connectionPublisher method and handle the received value
    WiliotGatewayBLEConnection.connectionPublisher.sink { isConnected in
        if isConnected {
            print("Connected")
        } else {
            print("Not connected")
        }
    }.store(in: &WiliotGatewayBLEConnection.cancellables)
}

@_cdecl("bleActivityPublisher")
public func bleActivityPublisher() {
    // Call the static bleActivityPublisher method from WiliotGatewayBLEConnection
    WiliotGatewayBLEConnection.bleActivityPublisher().sink { floatValue in
        // Process the received value
        print("Received ble activity value: \(floatValue)")
    }.store(in: &WiliotGatewayBLEConnection.cancellables)
}

@_cdecl("checkAndRequestSystemPermissions")
public func checkAndRequestSystemPermissions() {
    // Request system permissions using the exposed function
    WiliotGatewayBLEConnection.checkAndRequestSystemPermissions { (granted, message) in
        // Handle the result of the permission request
        if granted {
            // Permissions granted, handle accordingly
            print("Permission granted")
        } else {
            // Permissions not granted, handle accordingly
            print("Permission not granted")
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
