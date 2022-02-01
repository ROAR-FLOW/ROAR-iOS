//
//  ARPhoto2ViewController+ARKit.swift
//  IntelRacing
//
//  Created by Michael Wu on 9/23/21.
//

import Foundation
import ARKit
extension ARPhoto2ViewController: ARSCNViewDelegate, ARSessionDelegate, ARSessionObserver {
    func startARSession(worldMap: ARWorldMap?, worldOriginTransform: SCNMatrix4? = nil ) {
        let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil)!
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = false
        configuration.worldAlignment = .gravity
        configuration.wantsHDREnvironmentTextures = false
        configuration.detectionImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 10
        
        if worldMap != nil {
            print("Start AR Session from previous recorded world")
            // load the map
            configuration.initialWorldMap = worldMap
        } else {
            print("Start AR Session from scratch")
        }
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth){
            configuration.frameSemantics.insert(.sceneDepth)
        }
        arSceneView.delegate = self
        arSceneView.session.delegate = self
        arSceneView.autoenablesDefaultLighting = true;
        
//        arSceneView.showsStatistics = true
//        arSceneView.debugOptions = [.showWorldOrigin, .showCameras, .showFeaturePoints]
        
        // Run the view's session
        arSceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction])
        print("AR Session Started")
    }
    /*
     Allow the session to attempt to resume after an interruption.
     This process may not succeed, so the app must be prepared
     to reset the session if the relocalizing status continues
     for a long time -- see `escalateFeedback` in `StatusViewController`.
     */
    /// - Tag: Relocalization
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }

//        print(node.name)
    }
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
//            print(anchor.name)
        }
    }
}
