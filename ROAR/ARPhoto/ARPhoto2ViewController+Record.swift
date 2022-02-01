//
//  ARPhoto2ViewController+Record.swift
//  IntelRacing
//
//  Created by Michael Wu on 9/24/21.
//

import Foundation
import SwiftUI
import AVFoundation
import ReplayKit
import Loaf
extension ARPhoto2ViewController:RPPreviewViewControllerDelegate {
    
    func startRecording() {
        let recorder = RPScreenRecorder.shared()

        recorder.startRecording{ (error) in
            if let unwrappedError = error {
                print(unwrappedError.localizedDescription)
            } else {
                print("recording started")
            }
        }
    }
    
    func stopRecording() {
            let recorder = RPScreenRecorder.shared()
            recorder.stopRecording { [unowned self] (preview, error) in
            if let unwrappedPreview = preview {
                unwrappedPreview.previewControllerDelegate = self
                self.present(unwrappedPreview, animated: true)
            }
            }
        }

    
    @objc func onRecordButtonLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            self.recordButton.backgroundColor = .red
            self.recordButton.contentScaleFactor = 1.5
            startRecording()
        case .ended:
            self.recordButton.backgroundColor = .none
            stopRecording()
        default:
            break
        }
        
    }
    @IBAction func onRecordButtonPressed(_ sender: Any) {
        let uiImage = self.arSceneView.snapshot()
        UIImageWriteToSavedPhotosAlbum(uiImage, self, #selector(onImageSaved), nil)
    }
    
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        dismiss(animated: true)
    }
    @objc func onImageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        Loaf("image saved", state: .success, location: .top, presentingDirection: .left, dismissingDirection: .right, sender: self).show(.short)
        // TODO: @Bobby, could you please make a pop up view that preview the image?
    }
}
