//
//  MainViewController.swift
//  SampleApp

import UIKit
import Combine
import WiliotGatewayBLEConnection

class MainViewController: UIViewController {

    private var api: WiliotGatewayBLEConnection!


    @IBOutlet weak var bluetoothIcon: UIImageView?
    @IBOutlet weak var networkIconIcon: UIImageView?
    @IBOutlet weak var statusLabel: UILabel?

    private var cancellables: Set<AnyCancellable> = []

    override func loadView() {
        super.loadView()
        // appToken and ownerID are hardcoded here because they are to be set externally without any plist files
        // as the main aim of this app is to act as a Unity plugin.
        let appToken = "NDZmNTc3ODItYzg1NC00ZGM2LTk5NzctMzdlZWMyZDgzZTVmOkR5VHNJV2JzeXJwWW9Ic0hUcjFMSHpGZVRaVG14RTh2cmU3dGFNZ21oRlk="
        let ownerID = "947302316108"
        api = WiliotGatewayBLEConnection(appToken: appToken, ownerID: ownerID)

        if api != nil {
            
            api.observeStatusChanges { [weak self] statusString in
                    self?.statusLabel?.text = statusString
                }
            
            api.connectionPublisher
                .sink { [weak self] isConnected in
                    self?.handleConnectionStatus(isConnected)
                }
                .store(in: &cancellables)
            

            api.bleActivityPublisher()
                .sink { [weak self] floatValue in
                    self?.handleBLEactivityValue(floatValue)
                }
                .store(in: &cancellables)

            
            // Request system permissions using the exposed function
            api.checkAndRequestSystemPermissions { (granted, message) in
                // Handle the result of the permission request
                if granted {
                    // Permissions granted, handle accordingly
                    print("Permission granted")
                } else {
                    // Permissions not granted, handle accordingly
                    print("Permission not granted")
                }
            }
            
            api.subscribeToMessageSentAction { [weak self] in
                    self?.blinkNetworkingIcon()
                }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        api.checkAndRequestSystemPermissions()
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
