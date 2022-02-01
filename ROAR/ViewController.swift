//
//  ViewController.swift
//  ROAR
//
//  Created by Michael Wu on 9/11/21.
//

import UIKit
import SwiftyBeaver
import ARKit
import Loaf
import CoreBluetooth
import NIO
import os
import CocoaAsyncSocket

class ViewController: UIViewController, UIGestureRecognizerDelegate, ScanQRCodeProtocol {
    
    // MARK: IBOutlet
    @IBOutlet weak var systemStatusLabel: UILabel!
    @IBOutlet weak var bleButton: UIButton!
    @IBOutlet weak var ipAddressBtn: UIButton!
    @IBOutlet weak var arSceneView: ARSCNView!
    @IBOutlet weak var throttleLabel: UILabel!
    @IBOutlet weak var steeringLabel: UILabel!
    @IBOutlet weak var saveWorldButton: UIButton!
    @IBOutlet weak var recaliberateButton: UIButton!
    private var BLEautoReconnectTimer: Timer!

    // MARK: Instance variables
    var logger: SwiftyBeaver.Type {return (UIApplication.shared.delegate as! AppDelegate).logger}
    var controlCenter: ControlCenter!
    var bluetoothPeripheral: CBPeripheral!
    var centralManager: CBCentralManager!
    
    var iOSControllerRange: ClosedRange<CGFloat> = CGFloat(-1.0)...CGFloat(1.0);
    let throttle_range = CGFloat(1000)...CGFloat(2000)
    let steer_range = CGFloat(1000)...CGFloat(2000)
    var bleTimer: Timer!
    var bluetoothDispatchWorkitem:DispatchWorkItem!
    var bleControlCharacteristic: CBCharacteristic!
    var updateThrottleSteeringUITimer: Timer!
    
    
    var vehicleStateSocket: GCDAsyncUdpSocket!
    var worldCamSocket: GCDAsyncUdpSocket!
    var depthCamSocket: GCDAsyncUdpSocket!
    var controlSocket: GCDAsyncUdpSocket!

    // MARK: overrides
    override func viewDidLoad() {
        AppInfo.load()
        super.viewDidLoad()
        self.controlCenter = ControlCenter(vc: self)
        
        if let mapData = UserDefaults.standard.value(forKey: AppInfo.get_ar_experience_name()) as? Data {
            if let map = loadMap(data: mapData) {
                self.startARSession(worldMap: map, worldOriginTransform: nil)
            } else {
                self.startARSession(worldMap: nil, worldOriginTransform: nil)
            }
        } else {
            self.startARSession(worldMap: nil, worldOriginTransform: nil)
        }

        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.controlCenter.start(shouldStartServer: true)
        setupUI()
        setupTimers()
        setupGestures()
        
        self.setupSocket()
    }
    
    func loadMap(data:Data) -> ARWorldMap? {
        do {
            guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) else { return nil }
            return worldMap
        } catch {
            return nil
        }
    }
    func setupUI() {
        self.onBLEDisconnected()
        self.ipAddressBtn.isEnabled = false
        self.ipAddressBtn.setTitle("Please Caliberate", for: .disabled)
        self.updateThrottleSteeringUI()
    }
    func setupTimers() {
        self.startWritingToBLE()
        self.BLEautoReconnectTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(autoReconnectBLE), userInfo: nil, repeats: true)
        self.updateThrottleSteeringUITimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateThrottleSteeringUI), userInfo: nil, repeats: true)
    }
    
    
    
    func setupGestures() {
        // configure left edge pan gesture
        let screenEdgePanGestureLeft = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(self.didPanningScreenLeft(_:)))
        screenEdgePanGestureLeft.edges = .left
        screenEdgePanGestureLeft.delegate = self
        self.view.addGestureRecognizer(screenEdgePanGestureLeft)
    }
    

    override func viewWillDisappear(_ animated: Bool) {
        self.BLEautoReconnectTimer.invalidate()
        self.disconnectBluetooth()
        self.controlCenter.stop()
        super.viewWillDisappear(animated)
    }
    
    
    // MARK: objc functions
    
    @objc func didPanningScreenLeft(_ recognizer: UIScreenEdgePanGestureRecognizer)  {
        if recognizer.state == .ended {
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            let vc = storyboard.instantiateViewController(withIdentifier: "MainUIViewController") as UIViewController
//            vc.modalPresentationStyle = .fullScreen
//            vc.modalTransitionStyle = .crossDissolve
//            self.present(vc, animated: true, completion: nil)
            
        }
    }
    
    @objc func updateThrottleSteeringUI() {
        self.throttleLabel.text = String(format: "Throttle: %.2f", self.controlCenter.control.throttle)
        self.steeringLabel.text = String(format: "Steering: %.2f", self.controlCenter.control.steering)
    }
    @objc func autoReconnectBLE() {
        if AppInfo.sessionData.isBLEConnected == false {
            self.onBLEDisconnected()
            self.logger.info("BLE is disconnected state. Attempting to reconnect...")
            self.centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    // MARK: IBActions
    @IBAction func onResetWorldClicked(_ sender: UIButton) {
        let alert = UIAlertController(title: "Reset AR World", message: "This will get rid of the current AR World stored in the phone. Continue?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {action in
            UserDefaults.standard.setValue(nil, forKey: AppInfo.get_ar_experience_name());
            AppInfo.sessionData.shouldCaliberate = true
            self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    @IBAction func onReCaliberateClicked(_ sender: UIButton) {
        AppInfo.sessionData.shouldCaliberate = true
        AppInfo.sessionData.isCaliberated = false
        self.ipAddressBtn.isEnabled = false
        self.ipAddressBtn.setTitle("Please Caliberate", for: .disabled)
    }
    @IBAction func onSaveWorldClicked(_ sender: UIButton) {
        self.arSceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
            else { Loaf("Can't get current world map, try moving around slowly and save again.", state: .error, sender: self).show(.short); return}
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                //make cache name function
                UserDefaults.standard.setValue(data, forKey: AppInfo.get_ar_experience_name())

                //This will emit the data in UserDefaults for AppInfo.get_ar_experience_name()
                Loaf("World Saved", state: .success, sender: self).show(.short)
            } catch {
                Loaf("Error: \(error.localizedDescription)", state: .error, sender: self).show(.short)
            }
        }

    }
    
    func onBLEConnected() {
        self.bleButton.setTitleColor(.green, for: .normal)
        self.bleButton.setTitle("BLE: \(AppInfo.bluetootConfigurations?.name ?? "No Name")", for: .normal)
    }
    
    func onBLEDisconnected() {
        self.bleButton.setTitleColor(.red, for: .normal)
        self.bleButton.setTitle("BLE Not Connected", for: .normal)
    }
    @IBAction func onIPAddressBtnClicked(_ sender: UIButton) {
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let secondViewController = storyBoard.instantiateViewController(withIdentifier: "ScanQRCode") as! ScannerViewController
        secondViewController.delegate = self
        self.present(secondViewController, animated:true, completion:nil)
    }
    
    func onQRCodeScanFinished() {
        controlCenter.restartUDP()
    }
}

