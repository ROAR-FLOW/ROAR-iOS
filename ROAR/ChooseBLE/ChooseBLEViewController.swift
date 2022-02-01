//
//  ChooseBLEViewController.swift
//  ROAR
//
//  Created by Michael Wu on 11/6/21.
//

import Foundation
import UIKit
import SwiftyBeaver
import CoreBluetooth
import Loaf
import SwiftUI


class ChooseBLEViewController: UIViewController {
    
    
    // MARK: private variables
    var logger: SwiftyBeaver.Type {return (UIApplication.shared.delegate as! AppDelegate).logger}
    var bluetoothPeripheral: CBPeripheral!
    var centralManager: CBCentralManager!
    var bleControlCharacteristic: CBCharacteristic!
    var wifiMenu: UIMenu!
    
    @IBOutlet weak var chooseBLEButton: UIButton!
    @IBOutlet weak var throttleTextField: UITextField!
    @IBOutlet weak var steeringTextField: UITextField!
    @IBOutlet weak var sendControlButton: UIButton!
    @IBOutlet weak var newBLENameTextField: UITextField!
    @IBOutlet weak var requestBLENameChangeButton: UIButton!
    @IBOutlet weak var WifiSSIDButton: UIButton!
    @IBOutlet weak var WifiPasswordButton: UITextField!
    @IBOutlet weak var WifiSwitchButton: UIButton!
    
    
    // MARK: override functions
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        AppInfo.load()
        self.hideKeyboardWhenTappedAround()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    func setupUI() {

        
        var menuItems: [UIAction] {
            return [
                self.generateUIAction(name: "Test"),
            ]
        }
        wifiMenu = UIMenu(title: "Select Wifi", image: nil, identifier: nil, options: [], children: menuItems)
        // TODO, we might need to just have the user input wifi credentials manually
        // https://medium.com/@Chandrachudh/connecting-to-preferred-wifi-without-leaving-the-app-in-ios-11-11f04d4f5bd0
        // https://stackoverflow.com/questions/36303123/how-to-programmatically-connect-to-a-wifi-network-given-the-ssid-and-password
        WifiSSIDButton.menu = wifiMenu
        WifiSSIDButton.showsMenuAsPrimaryAction = true
    }
    
    func generateUIAction(name: String) -> UIAction {
        return UIAction(title: name, image: nil, state: .on, handler: {
            _ in self.WifiSSIDButton.setTitle(name, for: .normal)
        })
    }
    
    
    
    @IBAction func onWifiPasswordEditDidBegin(_ sender: UITextField) {
        UIView.animate(withDuration: 0.7, animations: {
            let originalTransform = self.view.transform
            let newTransform = originalTransform.translatedBy(x: 0.0, y: -250.0)
            self.view.transform = newTransform
         })
        
    }
    @IBAction func onWifiPasswordEditDidEnd(_ sender: UITextField) {
        UIView.animate(withDuration: 0.7, animations: {
            let originalTransform = self.view.transform
            let newTransform = originalTransform.translatedBy(x: 0.0, y: 250.0)
            self.view.transform = newTransform
         })
    }
    @IBAction func onSendControlBtnClicked(_ sender: UIButton) {
        let throttle_str = self.throttleTextField.text ?? "0"
        let steering_str = self.steeringTextField.text ?? "0"
        if self.checkControl(val: throttle_str) && self.checkControl(val: steering_str) {
            let throttle = Float(throttle_str)!
            let steering = Float(steering_str)!
            self.writeToBluetoothDevice(throttle: CGFloat(throttle), steering: CGFloat(steering))
            Loaf.init("(\(throttle), \(steering)) sent", state: .info, location: .bottom, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show(.short)
        } else {
            Loaf.init("Please make sure controls are in (-1, 1)", state: .error, location: .bottom, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show(.long, completionHandler: nil)
        }
    }
    @IBAction func onBLENameChangeBtn(_ sender: UIButton) {
        
    }
    @IBAction func onSSIDClicked(_ sender: UIButton) {
     
    }
    
    @IBAction func onRequestWifiClicked(_ sender: UIButton) {
    }
    
    private func checkControl(val: String) -> Bool {
        if let val_f = Float(val) {
            return -1 <= val_f && val_f <= 1
        } else {
            return false
        }
    }
}
