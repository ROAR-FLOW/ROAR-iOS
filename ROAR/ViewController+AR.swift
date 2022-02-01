//
//  ViewController+AR.swift
//  ROAR
//
//  Created by Michael Wu on 9/11/21.
//

import Foundation
import ARKit
extension ViewController:  ARSCNViewDelegate, ARSessionDelegate, ARSessionObserver{
    func startARSession(worldMap: ARWorldMap?, worldOriginTransform: SCNMatrix4? = nil ) {
        let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil)!
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = false
        configuration.worldAlignment = .gravity
        configuration.wantsHDREnvironmentTextures = false
        configuration.detectionImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 1
//        print(ARWorldTrackingConfiguration.supportedVideoFormats)
        if let format = ARWorldTrackingConfiguration.supportedVideoFormats.last  {
            configuration.videoFormat = format
        }
        if worldMap != nil {
            self.logger.info("Start AR Session from previous recorded world")
            // load the map
            configuration.initialWorldMap = worldMap
        } else {
            self.logger.info("Start AR Session from scratch")
        }
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth){
            configuration.frameSemantics.insert(.sceneDepth)
        }
        self.arSceneView.delegate = self
        self.arSceneView.session.delegate = self
        self.arSceneView.autoenablesDefaultLighting = true;
        
        self.arSceneView.showsStatistics = true
        self.arSceneView.debugOptions = [.showWorldOrigin, .showCameras, .showFeaturePoints]
        
        // Run the view's session
        self.arSceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction])
        self.logger.info("AR Session Started")
    }
    
    func restartArSession() {
        self.arSceneView.session.pause()
        self.startARSession(worldMap: nil)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
            case ARCamera.TrackingState.normal:
                self.systemStatusLabel.textColor = .green
                self.systemStatusLabel.text = "Tracking is normal"
                AppInfo.sessionData.isTracking = true
            case ARCamera.TrackingState.limited(.relocalizing):
                self.systemStatusLabel.textColor = .red
                self.systemStatusLabel.text = "Attempting to relocalize"
                AppInfo.sessionData.isTracking = false
            case ARCamera.TrackingState.limited(.excessiveMotion):
                self.systemStatusLabel.textColor = .red
                self.systemStatusLabel.text = "Excessive motion detected."
                AppInfo.sessionData.isTracking = false
            case ARCamera.TrackingState.limited(.initializing):
                self.systemStatusLabel.textColor = .red
                self.systemStatusLabel.text = "Tracking service is initializing"
                AppInfo.sessionData.isTracking = false
            case ARCamera.TrackingState.limited(.insufficientFeatures):
                self.systemStatusLabel.textColor = .red
                self.systemStatusLabel.text = "Not enough feature points"
                AppInfo.sessionData.isTracking = false
            default:
                self.systemStatusLabel.textColor = .red
                self.systemStatusLabel.text = "Not Available"
                AppInfo.sessionData.isTracking = false
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        controlCenter.updateBackCam(frame: frame)
        controlCenter.updateTransform(pointOfView: self.arSceneView.pointOfView!)
        if frame.sceneDepth != nil {
            controlCenter.updateWorldCamDepth(frame:frame)
        }
    }
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if AppInfo.sessionData.shouldCaliberate == true || AppInfo.sessionData.isCaliberated == false{
            for anchor in anchors {
                guard let imageAnchor = anchor as? ARImageAnchor else { continue }
                if imageAnchor.name == "BerkeleyLogo" || imageAnchor.name == "roar_car" {
                    session.setWorldOrigin(relativeTransform: imageAnchor.transform)
                    AppInfo.sessionData.isCaliberated = true
                    AppInfo.sessionData.shouldCaliberate = false
                    self.ipAddressBtn.isEnabled = true
                    self.ipAddressBtn.setTitle(findIPAddr(), for: .normal)
                }
            }
        }
    }
}
