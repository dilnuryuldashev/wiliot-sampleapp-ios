import Combine
import Foundation

public class WiliotGatewayBLEConnection {
    
    private let model: Model
    private var cancellables: Set<AnyCancellable> = []

    public init(appToken: String, ownerID: String) {
        model = Model()
        model.appToken = appToken
        model.ownerId = ownerID
    }
    
    public func completionLogMessage(status: Bool, message: String) {
        print("Completion message:\n + Status: \(status)\n + Message: \(message)")
    }
    
    
    public var connectionPublisher: AnyPublisher<Bool, Never> {
        model.connectionPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    
    public func bleActivityPublisher() -> AnyPublisher<Float, Never> {
        model.bleActivityPublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    
    public func observeStatusChanges(completion: @escaping (String) -> Void) {
        model.statusPublisher
            .receive(on: DispatchQueue.main)
            .sink { statusString in
                completion(statusString)
            }
            .store(in: &cancellables)
    }
    
    public func subscribeToMessageSentAction(completion: @escaping () -> Void) {
        model.messageSentActionPubliosher
            .receive(on: DispatchQueue.main)
            .sink { _ in
                completion()
            }
            .store(in: &cancellables)
    }

    
    public func checkAndRequestSystemPermissions(completion: @escaping (Bool, String) -> Void) {
        model.permissionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    self.connectToGatewayService(completion: completionLogMessage)
                    completion(true, "Permissions granted.")
                } else {
                    completion(false, "Permissions not granted.")
                }
            }
            .store(in: &cancellables)
    }

    public func connectToGatewayService(completion: @escaping (Bool, String) -> Void) {
        model.prepare {
            guard self.model.canStart() else {
                completion(false, "Unable to start. Required data or permissions missing.")
                return
            }
            self.model.start()
            completion(true, "Connection started successfully.")
        }
    }
    


    public func checkAndRequestSystemPermissions() {
        model.checkAndRequestSystemPermissions()
        // Handle the completion of permission requests and return the result to MainViewController.swift
        // For simplicity, in this example, we are returning "granted" directly.
        //completion(true, "Permissions granted.")
    }
}
