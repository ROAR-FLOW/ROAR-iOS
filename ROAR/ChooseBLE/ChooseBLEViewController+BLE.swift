//
//  ChooseBLEViewController+BLE.swift
//  ROAR
//
//  Created by Michael Wu on 11/6/21.
//

import Foundation
import CoreBluetooth
import UIKit

extension ChooseBLEViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOff:
                self.logger.info("Central is powered off")
            case .poweredOn:
                self.logger.info("Central is ON, scanning for services...")
                self.centralManager.scanForPeripherals(withServices: nil, options: nil)
            case .resetting:
                self.logger.info("Central is reseeting")
            case .unauthorized:
                self.logger.info("Central is in unauthorized state")
            case .unsupported:
                self.logger.info("Central is not supported")
            case .unknown:
                self.logger.info("Central is in an unknown state")
            @unknown default:
                self.logger.info("Central is in an unknown state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("found peripheral \(peripheral.identifier). Desired peripheral UUID: \(String(describing: AppInfo.bluetootConfigurations?.uuid))")
        if peripheral.identifier == AppInfo.bluetootConfigurations?.uuid{
            self.logger.info("Peripheral with selected BLE UUID found: \(AppInfo.bluetootConfigurations?.name ?? "No Name")")
            self.bluetoothPeripheral = peripheral
            self.centralManager.stopScan()
            self.centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        self.logger.info("Connection event occured")
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        self.logger.info("Connected to \(AppInfo.bluetootConfigurations?.name ?? "No Name")")
        self.chooseBLEButton.setTitle(AppInfo.bluetootConfigurations?.name ?? "No Name", for: .normal)
        self.chooseBLEButton.setTitleColor(.green, for: .normal)
        AppInfo.sessionData.isBLEConnected = true
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.logger.info("failed to connect")
        self.chooseBLEButton.setTitle("Choose BLE", for: .normal)
        self.chooseBLEButton.setTitleColor(.blue, for: .normal)
        AppInfo.sessionData.isBLEConnected = false
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.logger.info("Disconnected : \(AppInfo.bluetootConfigurations?.name ?? "No Name")")
        self.chooseBLEButton.setTitle("Choose BLE", for: .normal)
        self.chooseBLEButton.setTitleColor(.blue, for: .normal)
        AppInfo.sessionData.isBLEConnected = false
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
            case .poweredOff:
                self.logger.info("Peripheral is powered off")
            case .poweredOn:
                self.logger.info("Peripheral is ON, scanning for services...")
                self.centralManager.scanForPeripherals(withServices: nil, options: nil)
            case .resetting:
                self.logger.info("Peripheral is reseeting")
            case .unauthorized:
                self.logger.info("Peripheral is in unauthorized state")
            case .unsupported:
                self.logger.info("Peripheral is not supported")
            case .unknown:
                self.logger.info("Peripheral is in an unknown state")
            @unknown default:
                self.logger.info("Peripheral is in an unknown state")
            }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for char in characteristics {
                print("discovered characteristic with UUID: \(char.uuid)")
                if char.uuid.uuidString == "19B10011-E8F2-537E-4F6C-D104768A1214" {
                    bleControlCharacteristic = char
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func writeToBluetoothDevice(throttle: CGFloat, steering: CGFloat){
        let currThrottleRPM = throttle.map(from: CGFloat(-1.0)...CGFloat(1.0), to: CGFloat(1000)...CGFloat(2000))
        var currSteeringRPM = steering.map(from: CGFloat(-1.0)...CGFloat(1.0), to: CGFloat(1000)...CGFloat(2000))
        
        currSteeringRPM = currSteeringRPM.clamped(to: 1000...2000)
        
        
        let message: String = "(" + String(Int(currThrottleRPM)) + "," + String(Int(currSteeringRPM)) + ")"
        if self.bluetoothPeripheral != nil {
            sendMessage(peripheral: self.bluetoothPeripheral, message: message)
        }
    }
    
    func sendMessage(peripheral: CBPeripheral, message: String) {
        if bleControlCharacteristic != nil {
            peripheral.writeValue(message.data(using: .utf8)!, for: bleControlCharacteristic, type: .withoutResponse)
        }
        
    }
    
}
