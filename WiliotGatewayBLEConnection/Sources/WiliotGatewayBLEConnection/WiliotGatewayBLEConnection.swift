import Combine
import UIKit
import Foundation

public class WiliotGatewayBLEConnection {
    
    private static var model: Model = Model()
    public static var cancellables: Set<AnyCancellable> = []
    public static var bluetoothConnectionEstablished: ((Bool) -> Void)?
    public static var gatewayConnectionEstablished: ((Bool) -> Void)?
    public static var systemPermissionsGranted: ((Bool) -> Void)?

    // Open the app settings to see what the app has access to
    // And to enable/disable those permissions
    public static func openAppSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    // We are using hardcoded values for now
    public static func initialize(appToken: String, ownerID: String) {
        model.appToken = appToken
        model.ownerId = ownerID
    }
    
    public static func cancelAllSubscriptions() {
        WiliotGatewayBLEConnection.cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }
    
    public static func completionLogMessage(status: Bool, message: String) {
        print("Completion message:\n + Status: \(status)\n + Message: \(message)")
    }
    
    public static var connectionPublisher: AnyPublisher<Bool, Never> {
        model.connectionPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    public static func bleActivityPublisher() -> AnyPublisher<Float, Never> {
        model.bleActivityPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public static func observeStatusChanges() -> AnyPublisher<String, Never> {
        return model.statusPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    public static func subscribeToMessageSentAction(completion: @escaping () -> Void) {
        model.messageSentActionPubliosher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                completion()
            }
            .store(in: &cancellables)
    }

    public static func subscribeToPermissionUpdates(completion: @escaping (Bool, String) -> Void) {
        print("Calling subscribeToPermissionUpdates")
        model.permissionsPublisher
            .sink { granted in
                if granted {
                    connectToGatewayService(completion: completionLogMessage)
                    print("subscribeToPermissionUpdates: Permissions granted.")
                    completion(true, "Permissions granted.")
                } else {
                    completion(false, "Permissions not granted.")
                    print("subscribeToPermissionUpdates: Permissions NOT granted.")
                }
            }
            .store(in: &WiliotGatewayBLEConnection.cancellables)
    }

    public static func connectToGatewayService(completion: @escaping (Bool, String) -> Void) {
        model.prepare {
            guard self.model.canStart() else {
                completion(false, "Unable to start. Required data or permissions missing.")
                return
            }
            self.model.start()
            completion(true, "Connection started successfully.")
        }
    }
    
    public static func checkAndRequestSystemPermissions() {
        model.checkAndRequestSystemPermissions()
        // Handle the completion of permission requests and return the result to MainViewController.swift
        // For simplicity, in this example, we are returning "granted" directly.
        // completion(true, "Permissions granted.")
    }
}
