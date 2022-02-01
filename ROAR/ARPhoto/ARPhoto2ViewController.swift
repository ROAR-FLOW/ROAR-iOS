//
//  ARPhoto2ViewController.swift
//  IntelRacing
//
//  Created by Michael Wu on 9/23/21.
//

import Foundation
import UIKit
import ARKit
import os

class ARPhoto2ViewController: UIViewController, UIGestureRecognizerDelegate, SelectContentDelegate{

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var arSceneView: ARSCNView!
    @IBOutlet weak var recordButton: UIButton!
    
    //MARK: Gestures
    var screenEdgePanGestureRight: UIScreenEdgePanGestureRecognizer!
    var screenEdgePanGestureLeft: UIScreenEdgePanGestureRecognizer!
    var screenTapGesture: UITapGestureRecognizer!
    var screenPinchGesture: UIPinchGestureRecognizer!
    var screenRotationGesture: UIRotationGestureRecognizer!
    var screenPanGesture: UIPanGestureRecognizer!
    var recordBtnLongPressGesture: UILongPressGestureRecognizer!
    
    
    // MARK: Instance Variables
    var currentSCNNode: SCNNode? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureGestureRecognizers()
        self.startARSession(worldMap: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("View will appear")
    }

    func configureGestureRecognizers() {
        // configure right edge pan gesture
        screenEdgePanGestureRight = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(self.didPanningScreenRight(_:)))
        screenEdgePanGestureRight.edges = .right
        screenEdgePanGestureRight.delegate = self
        self.view.addGestureRecognizer(screenEdgePanGestureRight)

        
        // configure left edge pan gesture
        screenEdgePanGestureLeft = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(self.didPanningScreenLeft(_:)))
        screenEdgePanGestureLeft.edges = .left
        screenEdgePanGestureLeft.delegate = self
        self.view.addGestureRecognizer(screenEdgePanGestureLeft)
        
        // configure tap gesture
        self.screenTapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.onScreenTapped(_:)))
        self.screenTapGesture.delegate = self
        self.view.addGestureRecognizer(self.screenTapGesture)
        
        // configure pinch gesture
        self.screenPinchGesture = UIPinchGestureRecognizer.init(target: self, action: #selector(onScreenPinched(_:)))
        self.screenPinchGesture.delegate = self
        self.view.addGestureRecognizer(self.screenPinchGesture)
        
        // configure rotation gesture
        self.screenRotationGesture = UIRotationGestureRecognizer.init(target: self, action: #selector(onScreenGestureRotate(_:)))
        self.screenRotationGesture.delegate = self
        self.view.addGestureRecognizer(self.screenRotationGesture)
        
        // configure pan
        self.screenPanGesture = UIPanGestureRecognizer.init(target: self, action: #selector(onScreenPanned(_:)))
        self.screenPanGesture.delegate = self
        self.view.addGestureRecognizer(self.screenPanGesture)
        
        
        self.recordBtnLongPressGesture = UILongPressGestureRecognizer.init(target: self, action: #selector(onRecordButtonLongPressed))
        self.recordButton.addGestureRecognizer(self.recordBtnLongPressGesture)
    }

    
    @objc func onScreenPanned(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .changed {
            if let node = self.currentSCNNode {
                let point: CGPoint = recognizer.translation(in: self.arSceneView)
                let x: Float = 0.005 * sign(Float(point.x))
                let y: Float = -0.005 * sign(Float(point.y))
                node.localTranslate(by: SCNVector3(x, y, 0))

                
            }
        }
    }
    
    @objc func onScreenGestureRotate(_ recognizer: UIRotationGestureRecognizer) {
        if recognizer.state == .changed {
            if let node = self.currentSCNNode {
                let quat = simd_quatd(angle: Double(recognizer.rotation), axis: simd_double3(0, 1, 0))
                let scn_quat = SCNVector4.init(x: Float(quat.vector.x), y: Float(quat.vector.y), z: Float(quat.vector.z), w: Float(quat.vector.w))
                node.rotate(by: scn_quat, aroundTarget: node.worldPosition)
            }
        }
    }
    
    @objc func onScreenPinched(_ recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .changed {
            if let node = self.currentSCNNode {
                let scale = (Float(recognizer.scale)-1) * 0.05
                let x = node.scale.x + scale > 0 ? node.scale.x + scale :  node.scale.x
                let y = node.scale.y + scale > 0 ? node.scale.y + scale :  node.scale.y
                let z = node.scale.z + scale > 0 ? node.scale.z + scale :  node.scale.z
        
                node.scale = SCNVector3(x, y, z)
            }
        }
    }
    

    
    @objc func onScreenTapped(_ recognizer: UITapGestureRecognizer){
        if recognizer.state == .ended {
            let valid_hits = findValidHits(recognizer: recognizer)
            if valid_hits.count > 0 {
                let first_hit = valid_hits[0]
                if self.currentSCNNode == nil {
                    // going from selecting nothing to seleting something
                    self.currentSCNNode = findMostParentNode(node:first_hit.node)
                    self.instructionLabel.text = "Selected: \(self.currentSCNNode?.name ?? "nil")"
                }
                else if isValidSelectedNode(node: first_hit.node) {
                    // remove item
                    self.currentSCNNode?.removeFromParentNode()
                    self.instructionLabel.text = "Please Tap to add new object"
                    self.currentSCNNode = nil
                } else {
                    // swap item
                    self.currentSCNNode = findMostParentNode(node:first_hit.node)
                    self.instructionLabel.text = "Selected: \(self.currentSCNNode?.name ?? "nil")"
                }
            } else {
                // when there is no hit
                if self.currentSCNNode == nil {
                    let popOverVC = UIStoryboard(name: "ARPhoto2", bundle: nil).instantiateViewController(identifier: "ARPhoto2PopupViewController") as! ARPhoto2PopupViewController
                    popOverVC.modalTransitionStyle = .crossDissolve
                    popOverVC.selectContentDelegate = self
                    present(popOverVC, animated: true, completion: nil)
                } else {
                    // deselect item
                    self.currentSCNNode = nil
                    self.instructionLabel.text = "Please Tap to add new object"
                }
            }
        }
    }
    
    func findMostParentNode(node:SCNNode?) -> SCNNode? {
        /*
         recurse up to find the most parent node. ex:
         Optional("primitive_0")
         Optional("model_Dragon_Mesh_1483")
         Optional("Root_M")
         Optional("DeformationSystem")
         Optional("Main")
         Optional("Group")
         Optional("RootNode")
         Optional("Geom")
         Optional("Dragon_Idle")
         Optional("dragon")
         */
        if node == nil {
            return nil
        }
        if node?.parent == nil {
            return node
        }
        
        var curr:SCNNode = node!
        while true {
            if curr.parent == nil {
                break // safety check
            }
            if curr.parent != nil && curr.parent?.name == nil {
                break // this is the actual break condition
            }

            curr = curr.parent!
        }
        return curr
    }
    
    func isValidSelectedNode(node:SCNNode) -> Bool {
        /*
         recurse up to find a node that is equal to self.currSCNNode's name
         */
        if self.currentSCNNode == nil {
            return false
        }
        
        var curr = node
        while true {
            if curr.parent == nil {
                break
            }
            if curr.name == self.currentSCNNode?.name {
                return true
            }
            curr = curr.parent!
        }
        return false
    }
    
    func findValidHits(recognizer: UITapGestureRecognizer) -> [SCNHitTestResult] {
        let results:[SCNHitTestResult] = arSceneView.hitTest(recognizer.location(in: self.arSceneView), options:[.ignoreHiddenNodes:true, .categoryBitMask: 1, .boundingBoxOnly: true])
        var valid_hits:[SCNHitTestResult] = []
        for result in results {
            if result.node.name != nil {
                valid_hits.append(result)
            }
        }
        return valid_hits
    }
    
    func addNewNodeFromFile(filename: String, name: String) -> SCNNode? {
        let modelURL = Bundle.main.url(forResource: filename, withExtension: nil)
        guard let node = SCNReferenceNode(url: modelURL!) else {return nil}
        let cam_pos = (self.arSceneView.pointOfView?.position)!
        let cam_rot = self.arSceneView.pointOfView?.eulerAngles
        
        let node_pos = SCNVector3(cam_pos.x + (-1 * sin(cam_rot?.y ?? 0)), cam_pos.y - 0.5, cam_pos.z - 1.5)
        node.name = name
        node.categoryBitMask = 1
        node.worldPosition = node_pos
          // Add the node to the scene
        self.arSceneView.scene.rootNode.addChildNode(node)
        
        SCNTransaction.begin()
        node.load()
//        print("added node with identifier", node.name)
        SCNTransaction.commit()
        return node
    }
    func onContentSelectionMade(filePath: String, name:String){
        // create new node
        self.currentSCNNode = self.addNewNodeFromFile(filename: filePath, name: name)
        self.instructionLabel.text = "Selected: \(self.currentSCNNode?.name ?? "nil")"
    }
    func onContentSelectionCanceled() {
        
    }
    

    
    @IBAction func onRestartTapped(_ sender: UIButton) {
        self.startARSession(worldMap: nil)
        for n in self.arSceneView.scene.rootNode.childNodes {
            n.removeFromParentNode()
        }
        self.currentSCNNode = nil
        self.instructionLabel.text = "Tap to select or place an object"
    }
    
    @objc func didPanningScreenRight(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        if recognizer.state == .ended {
            print("Right edge ended")
        }
        
    }
    
    @objc func didPanningScreenLeft(_ recognizer: UIScreenEdgePanGestureRecognizer)  {
        if recognizer.state == .ended {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "MainUIViewController") as UIViewController
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            self.present(vc, animated: true, completion: nil)
        }
    }
}
