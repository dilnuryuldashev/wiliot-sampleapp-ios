//
//  BLEPacketsManager.swift

import Foundation
import Combine
import UIKit

class BLEPacketsManager: NSObject {
    private var cancellables: Set<AnyCancellable> = []

    private lazy var accelerationService: MotionAccelerationService = {
        let service = MotionAccelerationService(accelerationUpdateInterval: 1.0)
        return service
    }()
    
    lazy var locationService: LocationService = LocationService()

    var pacingReceiver: PacketsPacing?

    init(pacingReceiver: PacketsPacing?) {
        self.pacingReceiver = pacingReceiver
    }
    
    // We talk to Resolve API to resolve Bluetooth packets into tag IDs
    let resolveAPI: ResolveAPI = ResolveAPI()

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
        
        let payloadStr = blePacket.data.hexEncodedString(options: .upperCase)
        print("BLEPacketsManager payloadStr: \(payloadStr)")
        

        //triggerNotification(for: blePacket)

        // We create a short JSON string containing the packet ID
        // Then, we send it over to the Resolve API
        // When we get a resoled tag ID, we publish it
        // to the listeners of ResolveAPI.tagIDResolved
        if let payloadJSONString = resolveAPI.createPayloadJSONString(payloadValue: payloadStr) {
            // Use the payloadJSONString as needed, like sending it in a network request
            resolveAPI.sendPacketToResolveAPI(payloadString: payloadJSONString) { externalId, error in
                if let externalId = externalId {
                    // Resolve API returns unknown
                    // if the packet was not resolved
                    // If it was, we get back a tag ID
                    if externalId != "unknown" {
                        // print("Resolver ID: \(externalId)")
                        // We can print the returned ID for debugging purposes
                        // Or we can take its value use it for other purposes such as below
                        // where we publish ti to the listeners of ResolveAPI.tagIDResolved
                        self.resolveAPI.publishResolvedTagId(message: externalId)
                        // Determine if this is a specific packet that should trigger a notification
                        self.triggerNotification(for: externalId)

                        if self.shouldTriggerNotification(for: blePacket) {
                            print("shouldTriggerNotification: true")
                        }
                        else {
                            print("shouldTriggerNotification: false")
                        }
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
                            sequenceId: 0,
                            nfpkt: 1, // was set to nil before
                            rssi: blePacket.rssi)

        pacingReceiver?.receivePacketsByUUID([bleUUID: packet])
    }
    
    private func shouldTriggerNotification(for packet: BLEPacket) -> Bool {
        // Add logic to determine if a notification should be triggered
        // For example, check the group ID or other specific data in the packet
        let groupIdRange = 2..<5
        let groupIdData = packet.data.subdata(in: groupIdRange)
        let groupIdString = groupIdData.hexEncodedString()
        
        return groupIdString == "0000ec" // Example condition
    }
    
    private func triggerNotification(for packetStr: String) {
        let currentTime = Date()
        let userDefaults = UserDefaults.standard
        let lastNotificationKey = "lastNotification_\(packetStr)"
        
        if let lastNotificationTime = userDefaults.object(forKey: lastNotificationKey) as? Date {
            let timeInterval = currentTime.timeIntervalSince(lastNotificationTime)
            
            // Check if an hour (3600 seconds) has passed since the last notification
            if timeInterval < 3600 {
                return
            }
        }
        
        // Update the last notification time
        userDefaults.set(currentTime, forKey: lastNotificationKey)
        
        let content = UNMutableNotificationContent()
        content.title = "BLE Packet Received"
        content.body = "Payload: \(packetStr)"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error triggering notification: \(error)")
            }
        }
    }
}
