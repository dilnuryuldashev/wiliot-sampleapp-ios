//
//  Permissions.swift
//  Wiliot Mobile
//
//  Created by Ivan Yavorin on 03.05.2022.
//

import Foundation
import CoreLocation
import CoreBluetooth
import Combine

class Permissions: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let instance = Permissions()
    var isLocationPermissionsErrorNeedManualSetup: Bool = false {
        willSet {
            objectWillChange.send()
        }
    }

    var locationAlwaysGranded: Bool = false
    var locationWhenInUseGranted: Bool = false
    @Published var locationCanBeUsed: Bool = false
    @Published var bluetoothCanBeUsed: Bool = false

    /// to be binded in the toggling the gateway mode
    //@Published private(set) var bluetoothPermissionsGranted: Bool = false
    //@Published private(set) var locationPermissionsGranted: Bool = false

    var pLocationCanBeUsed: Bool {
        locationAlwaysGranded || locationWhenInUseGranted
    }

    private lazy var cbManager: CBCentralManager = CBCentralManager()
    var locationManager: CLLocationManager?
    private lazy var cbDelegate: CBCentralManagerDelegateObject = CBCentralManagerDelegateObject()
    //private lazy var locDelegate: CBLocationManagerDelegateObject = CBLocationManagerDelegateObject()
    var stateStr = ""

    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        checkAuthStatus()
    }


    // MARK: -
    func checkAuthStatus() {

        #if targetEnvironment(simulator)
        locationAlwaysGranded = true
        locationWhenInUseGranted = true
        locationCanBeUsed = true
        bluetoothCanBeUsed = true
        gatewayPermissionsGranted = true
        updateGatewayPermissionsGranted()
        return
        #endif

        if let manager = locationManager {
            
            switch manager.authorizationStatus {
                
            case .notDetermined:
                stateStr += "checkAuthStatus: location notDetermined && "
                locationAlwaysGranded = false
                locationWhenInUseGranted = false
            case .restricted:
                stateStr += "checkAuthStatus: location restricted && "
                locationAlwaysGranded = false
                locationWhenInUseGranted = false
            case .denied:
                stateStr += "checkAuthStatus: location denied && "
                locationAlwaysGranded = false
                locationWhenInUseGranted = false
            case .authorizedAlways:
                stateStr += "checkAuthStatus: location authorizedAlways && "
                locationAlwaysGranded = true
                locationWhenInUseGranted = true
            case .authorizedWhenInUse:
                stateStr += "checkAuthStatus: location authorizedWhenInUse && "
                locationWhenInUseGranted = true
            @unknown default:
                stateStr += "checkAuthStatus: location unknown && "
                locationAlwaysGranded = false
                locationWhenInUseGranted = false
            }
            
            locationCanBeUsed = pLocationCanBeUsed
        }

        let btState = CBCentralManager.authorization
        
        switch btState {
        case .notDetermined:
            stateStr += "checkAuthStatus: bluetooth notDetermined"
            bluetoothCanBeUsed = false
        case .restricted:
            stateStr += "checkAuthStatus: bluetooth restricted"
            bluetoothCanBeUsed = false
        case .denied:
            stateStr += "checkAuthStatus: bluetooth denied"
            bluetoothCanBeUsed = false
        case .allowedAlways:
            stateStr += "checkAuthStatus: bluetooth allowedAlways"
            bluetoothCanBeUsed = true
        @unknown default:
            stateStr += "checkAuthStatus: bluetooth fatalError"
            fatalError()
        }
        
        print("checkauth str: \(stateStr)")
        //locationPermissionsGranted = locationCanBeUsed
        //bluetoothPermissionsGranted = bluetoothCanBeUsed
    }

    func requestBluetoothAuth() {
        cbDelegate.delegate = self

        cbManager.delegate = cbDelegate
        cbManager.scanForPeripherals(withServices: nil)
    }

    func requestLocationAuth() {

        let status = locationManager?.authorizationStatus
        isLocationPermissionsErrorNeedManualSetup = false
        stateStr = ""
        switch status {
        case .notDetermined:
            stateStr += "location notDetermined"
            locationWhenInUseGranted = false
            locationAlwaysGranded = false
            locationManager?.delegate = self
            locationManager?.requestWhenInUseAuthorization()
        case .restricted:
            stateStr += "location restricted"
            locationWhenInUseGranted = false
            locationAlwaysGranded = false
            isLocationPermissionsErrorNeedManualSetup = true
            return
        case .denied:
            stateStr += "location denied"
            locationWhenInUseGranted = false
            locationAlwaysGranded = false
            isLocationPermissionsErrorNeedManualSetup = true
            return
        case .authorizedAlways:
            stateStr += "location always allow"
            locationAlwaysGranded = true
            return
        case .authorizedWhenInUse:
            stateStr += "location authorizedWhenInUse"
            locationWhenInUseGranted = true
            locationManager?.requestAlwaysAuthorization()
        case .none:
            stateStr += "location none"
            locationWhenInUseGranted = false
            locationAlwaysGranded = false
            return
        @unknown default:
            print("locationManagerAuthStateDidChange fatal error! value = \(String(describing: status))")
            stateStr += "location fatalError"
            fatalError()
        }

        locationCanBeUsed = locationWhenInUseGranted || locationAlwaysGranded

        print("locationManagerAuthStateDidChange str: \(stateStr)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("iOS: locationManager didChangeAuthorization deprecated version, before switch")
        switch status {
        case .notDetermined:
            stateStr += "location notDetermined"
            locationWhenInUseGranted = false
            locationAlwaysGranded = false
//            locationCanBeUsed = false
        case .restricted:
            stateStr += "location restricted"
            locationWhenInUseGranted = false
            locationAlwaysGranded = false
//            locationCanBeUsed = false
        case .denied:
            stateStr += "location denied"
            locationWhenInUseGranted = false
            locationAlwaysGranded = false
//            locationCanBeUsed = false
        case .authorizedAlways:
            stateStr += "location always allow"
            locationAlwaysGranded = true
        case .authorizedWhenInUse:
            stateStr += "location authorizedWhenInUse"
            locationWhenInUseGranted = true
        @unknown default:
            print("locationManagerAuthStateDidChange fatal error! value = \(manager.authorizationStatus)")
            stateStr += "location fatalError"
            //fatalError()
        }

        locationCanBeUsed = locationWhenInUseGranted || locationAlwaysGranded

        print("locationManagerAuthStateDidChange str: \(stateStr)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("iOS: locationManagerDidChangeAuthorization before switch")
        switch manager.authorizationStatus {
        case .notDetermined:
            stateStr += "location notDetermined"
            locationWhenInUseGranted = false
            locationAlwaysGranded = false
//            locationCanBeUsed = false
        case .restricted:
            stateStr += "location restricted"
            locationWhenInUseGranted = false
            locationAlwaysGranded = false
//            locationCanBeUsed = false
        case .denied:
            stateStr += "location denied"
            locationWhenInUseGranted = false
            locationAlwaysGranded = false
//            locationCanBeUsed = false
        case .authorizedAlways:
            stateStr += "location always allow"
            locationAlwaysGranded = true
        case .authorizedWhenInUse:
            stateStr += "location authorizedWhenInUse"
            locationWhenInUseGranted = true
        @unknown default:
            print("locationManagerAuthStateDidChange fatal error! value = \(manager.authorizationStatus)")
            stateStr += "location fatalError"
            //fatalError()
        }

        locationCanBeUsed = locationWhenInUseGranted || locationAlwaysGranded

        print("locationManagerAuthStateDidChange str: \(stateStr)")
        //locationPermissionsGranted = locationCanBeUsed
        //bluetoothPermissionsGranted = bluetoothCanBeUsed
        
    }

}

extension Permissions: CBCentralManagerStateDelegate {
    func bluetoothDidChangeAuthState(_ state: CBManagerAuthorization) {
        switch state {
        case .notDetermined:
            stateStr += "bluetooth notDetermined"
            self.bluetoothCanBeUsed = false
        case .restricted:
            stateStr += "bluetooth restricted"
            self.bluetoothCanBeUsed = false
        case .denied:
            stateStr += "bluetooth denied"
            self.bluetoothCanBeUsed = false
        case .allowedAlways:
            stateStr += "bluetooth allowedAlways"
            self.bluetoothCanBeUsed = true
        @unknown default:
            stateStr += "bluetooth fatalError"
            fatalError()
        }

        print("bluetoothDidChangeAuthState str: \(stateStr)")
        //locationPermissionsGranted = locationCanBeUsed
        //bluetoothPermissionsGranted = bluetoothCanBeUsed
    }
}

// MARK: - BLE Delegate
protocol CBCentralManagerStateDelegate: AnyObject {
    func bluetoothDidChangeAuthState(_ state: CBManagerAuthorization)
}

@objc class CBCentralManagerDelegateObject: NSObject {
    weak var delegate: CBCentralManagerStateDelegate?
}

extension CBCentralManagerDelegateObject: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {

        let overallState = CBCentralManager.authorization
        delegate?.bluetoothDidChangeAuthState(overallState)
    }

    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        let uids: [CBUUID] = (dict[CBCentralManagerRestoredStateScanServicesKey] as? [CBUUID]) ?? [CBUUID]()
        print("Permissions centralManager willRestoreState -> uids: \(uids)")
    }
}

