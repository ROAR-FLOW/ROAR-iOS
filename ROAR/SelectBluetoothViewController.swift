//
//  SelectBluetoothViewController.swift
//  ROAR
//
//  Created by Michael Wu on 9/11/21.
//

import Foundation
import UIKit
import CoreBluetooth
import SwiftyBeaver
import JGProgressHUD

class SelectBluetoothViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    var logger: SwiftyBeaver.Type {return (UIApplication.shared.delegate as! AppDelegate).logger}
    @IBOutlet weak var bluetoothTableView: UITableView!

    var centralManager: CBCentralManager!
    var detectedDevices: [String: UUID] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        AppInfo.bluetootConfigurations = BluetoothConfigurations()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        setupTableView()

    }
    func setupTableView() {
        bluetoothTableView.register(UITableViewCell.self, forCellReuseIdentifier: "BluetoothDevices")
        bluetoothTableView.dataSource = self
        bluetoothTableView.delegate = self
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detectedDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BluetoothDevices")! as UITableViewCell
        cell.textLabel?.text = Array(detectedDevices.keys)[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let keyName = Array(self.detectedDevices.keys)[indexPath.row]
        centralManager.stopScan()
        AppInfo.bluetootConfigurations = BluetoothConfigurations(name: keyName, uuid: self.detectedDevices[keyName]!)
        self.logger.info("BLE \(String(describing: AppInfo.bluetootConfigurations?.name)) -> \(String(describing: AppInfo.bluetootConfigurations?.uuid?.uuidString)) selected")
        self.onExit()

        
    }
    
    func onExit() {
        AppInfo.save()
        self.dismiss(animated: true, completion: nil)
    }
}
extension SelectBluetoothViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    /*
     Responsible for Bluetooth device discovery
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            self.logger.info("central.state is .unknown")
        case .resetting:
            self.logger.info("central.state is .resetting")
        case .unsupported:
            self.logger.info("central.state is .unsupported")
        case .unauthorized:
            self.logger.info("central.state is .unauthorized")
        case .poweredOff:
            self.logger.info("central.state is .poweredOff")
        case .poweredOn:
            self.logger.info("central.state is .poweredOn")
            let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey:
                                          NSNumber(value: false)]
            centralManager.scanForPeripherals(withServices: nil, options: options)
            let hud = JGProgressHUD()
            hud.textLabel.text = "Loading"
            hud.show(in: self.view)
            hud.dismiss(afterDelay: 1.0)
        @unknown default:
            self.logger.error("unknown")
        }
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if RSSI.intValue < -15 && RSSI.intValue > -35 {
            // Reject any where the value is above reasonable range
            // Reject if the signal strength is too low to be close enough (Close is around -22dB)
            return
        }
        if advertisementData["kCBAdvDataLocalName"] != nil {
            self.logger.info("Detected device \(advertisementData["kCBAdvDataLocalName"] as! String)")
            detectedDevices[advertisementData["kCBAdvDataLocalName"] as! String] = peripheral.identifier
            bluetoothTableView.reloadData()
        }
    }
    
}
