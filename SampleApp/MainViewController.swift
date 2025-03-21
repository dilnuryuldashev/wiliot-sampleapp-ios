//
//  MainViewController.swift
//  SampleApp

import UIKit
import Combine
import WiliotGatewayBLEConnection

class MainViewController: UIViewController {

    @IBOutlet weak var bluetoothIcon: UIImageView?
    @IBOutlet weak var networkIconIcon: UIImageView?
    @IBOutlet weak var statusLabel: UILabel?

    private var cancellables: Set<AnyCancellable> = []

    override func loadView() {
        super.loadView()
        // appToken and ownerID are hardcoded here because they are to be set externally without any plist files
        // as the main aim of this app is to act as a Unity plugin.
        let appToken = "MmE1NjQ0MDctMmQ5Yy00NWJjLTk2MzktNjE1ZjUzM2QxZjBiOkxZU2ZIc0pzQjJiNG8yVS1oNTlBM1h1VGUtd3ZFY3A5SGgtZnpQaHB0TnM="
        let ownerID = "201409513381"
        WiliotGatewayBLEConnection.initialize(appToken: appToken, ownerID: ownerID)

        if true {

            WiliotGatewayBLEConnection.observeStatusChanges()
                        .sink(receiveValue: { statusString in
                            // Handle the received statusString
                            print("Received status: \(statusString)")
                        }).store(in: &cancellables)
            
            WiliotGatewayBLEConnection.connectionPublisher
                .sink { [weak self] isConnected in
                    self?.handleConnectionStatus(isConnected)
                }
                .store(in: &cancellables)
            

            WiliotGatewayBLEConnection.bleActivityPublisher()
                .sink { [weak self] floatValue in
                    self?.handleBLEactivityValue(floatValue)
                }
                .store(in: &cancellables)

            
            // Request system permissions using the exposed function
            WiliotGatewayBLEConnection.subscribeToPermissionUpdates { (granted, message) in
                // Handle the result of the permission request
                if granted {
                    // Permissions granted, handle accordingly
                    print("Permission granted")
                } else {
                    // Permissions not granted, handle accordingly
                    print("Permission not granted")
                }
            }
            
            WiliotGatewayBLEConnection.subscribeToMessageSentAction { [weak self] in
                    self?.blinkNetworkingIcon()
                }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        WiliotGatewayBLEConnection.checkAndRequestBluetoothPermissions()
        WiliotGatewayBLEConnection.checkAndRequestLocationPermissions()


    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    private func handleConnectionStatus(_ isConnected: Bool) {
        if isConnected {
            networkIconIcon?.image = UIImage(systemName: "icloud.and.arrow.up.fill")
            networkIconIcon?.tintColor = .systemGreen
            statusLabel?.text = "Connected"
        } else {
            networkIconIcon?.image = UIImage(systemName: "xmark.icloud")
            networkIconIcon?.tintColor = .lightGray
            statusLabel?.text = "Not connected"
        }
    }

    private func handleBLEactivityValue(_ value: Float) {
        if value > 0 {
            if #available(iOS 16.0, *) {
                bluetoothIcon?.image = UIImage(systemName: "antenna.radiowaves.left.and.right", variableValue: Double(value))
            } else {
                // Fallback on earlier versions
                bluetoothIcon?.image = UIImage(systemName: "antenna.radiowaves.left.and.right")
            }
            bluetoothIcon?.tintColor = .systemBlue
        } else {
            bluetoothIcon?.image = UIImage(systemName: "antenna.radiowaves.left.and.right.slash")
            bluetoothIcon?.tintColor = .lightGray
        }
    }
    

    private func blinkNetworkingIcon() {
        statusLabel?.text = "sent Tags Info at: \(Date())"

        UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState]) {[unowned self] in
            networkIconIcon?.alpha = 0.7

        } completion: {  _ in
            UIView.animate(withDuration: 0.2, delay: 0.1, animations: {[unowned self] in
                networkIconIcon?.alpha = 1.0
            }, completion: nil )

        }
    }

}
