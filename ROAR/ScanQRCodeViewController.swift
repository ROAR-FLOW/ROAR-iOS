import AVFoundation
import UIKit
import Loaf
import CocoaAsyncSocket
import JGProgressHUD
class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: ScanQRCodeProtocol? = nil
    var is_connected: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            find(raw_string: stringValue)
        }
    }
    
    func find(raw_string: String) {
        
        guard let result = split_raw_string(raw_string: raw_string) else {
            Loaf.init("Unable to parse result \(raw_string)", state: .error, location: .bottom, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show(.short, completionHandler: {_ in
                self.captureSession.startRunning()
            })
            return
        }
        
        if validateIpAddress(ipToValidate: result.ip_address) {
            perform_handshake(ip_address: result.ip_address, port: result.port)
        }
    }
    
    func split_raw_string(raw_string: String) -> (ip_address: String, port: UInt16)? {
        let result = raw_string.components(separatedBy: ",")
        if result.count < 2 {
            return nil
        } else {
            let ip_addr = result[0]
            guard let port = UInt16(result[1]) else {return nil}
            return (ip_addr, port)
        }
    }


    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    
    func perform_handshake(ip_address:String, port: UInt16){
        
        let mSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        do {
            try mSocket.connect(toHost: ip_address, onPort: port)
            
            let hud = JGProgressHUD()
            hud.textLabel.text = "Connecting...."
            hud.show(in: self.view)
            hud.dismiss(afterDelay: 2)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    if self.is_connected == false {
                         Loaf.init("No Response", state: .error, location: .bottom, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show(.short, completionHandler: {_ in
                             self.captureSession.startRunning()
                         })
                        mSocket.disconnect()
                    } else {
                        AppInfo.pc_address = ip_address
                        AppInfo.save()
                        self.dismiss(animated: true, completion: {self.delegate?.onQRCodeScanFinished()})
                        mSocket.disconnect()
                    }
            })
            
        } catch let error {
            print(error)
        }
    }
}

extension ScannerViewController: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        is_connected = true
    }
}
