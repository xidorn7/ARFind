//
//  GameViewController.swift
//  ARFindTest
//
//  Created by Andrew Mendez on 11/16/16.
//  Copyright (c) 2016 Andrew Mendez. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import AVFoundation

class GameViewController: UIViewController {

    
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    let motionManager = CMMotionManager()
    let videoView = UIView()
    var boxNode : SCNNode!
    var pointer : SCNNode!
    var xStep:Float = 0
    var cameraNode:SCNNode!
    var direction:Bool = true
    // If we find a device we'll store it here for later use
    var captureDevice : AVCaptureDevice?
    let screenWidth = UIScreen.mainScreen().bounds.size.width
    var finalAxes : SCNVector4!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view, typically from a nib.
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        print("Capture device found")
                        beginSession()
                    }
                }
                
            }
        }
        print("Smoking Gun")
        
        self.view.addSubview(videoView)
        
        
        //set up scenekit
        
        //create a SceneView with a clear background color and add it as a subview of self.view
        let sceneView = SCNView()
        
        sceneView.delegate = self
        sceneView.playing = true
        
        sceneView.frame = self.view.bounds
        sceneView.backgroundColor = UIColor.clearColor()
        //previewLayer!.frame = self.view.bounds
        //sceneView.opaque=true;
        
        videoView.addSubview(sceneView)
        
        
        //self.view.addSubview(sceneView)
        
        // create a new scene
        let scene = SCNScene()
        //            scene.background.contents=previewLayer
        sceneView.scene = scene
//        let boxGeometry = SCNBox(width: 1.0, height: 2.0, length: 4.0, chamferRadius: 0.0)
//        let boxNode = SCNNode(geometry: boxGeometry)
//        boxNode.name = "box"
//        scene.rootNode.addChildNode(boxNode)
        
        let pointerScene = SCNScene(named: "pointer.dae")
        
         pointer = pointerScene?.rootNode.childNodeWithName("pointer", recursively: true)

        let box = SCNBox(width:4.0,height:4.0,length:4.0,chamferRadius:0.05)
        boxNode = SCNNode(geometry:box)
        boxNode.position = SCNVector3(0.0,50.0,-10.0)
        box.firstMaterial?.diffuse.contents = UIColor.orangeColor()
//        scene.rootNode.addChildNode(boxNode)
//        let boxFollow = pointerScene?.rootNode.childNodeWithName("box", recursively: true)
        
       print(pointer?.position)
       print(pointer?.orientation)
        //take normalize distance
        var normDist = normalizeDifference((pointer?.position)!, b: boxNode.position)
         print(normDist)
//        if normDist.z == 0.0{
//            normDist.z = 1.0
//        }
        
        let axes = SCNVector3((pointer?.rotation.x)!,(pointer?.rotation.y)!,(pointer?.rotation.z)!)
      print(axes)

        let axis = cross(axes, right: normDist )
//
        //print(axis)

//        pointer?.eulerAngles = axis

        let alpha = dot(axes, b: normDist  )
        print(alpha)
        let quat = createQuatFromAxisAndRotation(axis, angle: alpha)
       print(quat.x,quat.y,quat.z)
//        pointer?.rotation = SCNVector4Make(0, 1, 0, alpha)
//        pointer?.orientation = quat
//
//        pointer!.constraints = [SCNLookAtConstraint(target:boxNode)]
//        let temp = pointer!.rotation.z
//        pointer!.rotation.z = pointer!.rotation.y
//        pointer!.rotation.y = temp
//        pointer!.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float(M_PI))
        //add animation to box
        
//        let action1 = SCNAction.moveByX(20.0, y: 0.0, z: 0, duration: 3)
//        
//         //let action1 = SCNAction.rotateByAngle(3, aroundAxis: SCNVector3(0,1,0), duration: 10.0)
//        let action2 = SCNAction.moveByX(-20.0, y: 0.0, z: 0, duration: 3)
//        
//         //let action2 = SCNAction.rotateByAngle(-360, aroundAxis: SCNVector3(0,1,0), duration: 3.0)
//        let seq = SCNAction.sequence([action1,action2])
//        let seqAction = SCNAction.repeatActionForever(seq)
//        boxNode.runAction(seqAction)
        
        // create and add a camera to the scene
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0,0,-14)
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.addChildNode(pointer!)
        pointer!.position = SCNVector3(0,0,-10)

        // place the camera
//        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        cameraNode.camera!.zFar = 200
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 20, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        sceneView.autoenablesDefaultLighting = true
        
        
        guard motionManager.deviceMotionAvailable else {
            fatalError("Device motion is not available")
        }
        
        // Action
        
        //change interval for sensitivity
        
        //tutorial: http://iosdeveloperzone.com/2016/05/02/using-scenekit-and-coremotion-in-swift/
        
        //quaternion here:https://gist.github.com/travisnewby/96ee1ac2bc2002f1d480
        //http://stackoverflow.com/questions/31823012/cameranode-rotate-as-ios-device-moving
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0

        motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) {
            [weak self](data: CMDeviceMotion?, error: NSError?) in
            
            guard let data = data else { return }
            
//            let attitude: CMAttitude = data.attitude
////            pointer!.eulerAngles = SCNVector3Make(
////                Float(attitude.pitch-((130*M_PI)/180)),
////                Float(attitude.yaw), Float(attitude.roll))
//            pointer!.rotation.y = Float(attitude.yaw)
            
            let a = data.attitude.quaternion
            //print(Float(a.z)*180/Float(M_PI))
            let aq = GLKQuaternionMake(Float(a.x), Float(a.y), Float(a.z), Float(a.w))
            
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float(0), 1, 0, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            
            self!.finalAxes = SCNVector4(x: q.x, y: q.y, z: q.z, w: q.w)
            
            self!.pointer!.orientation.z = -self!.finalAxes.y
            self?.cameraNode.orientation = self!.finalAxes
            //        self?.cameraNode.eulerAngles = SCNVector3Make(Float(attitude.roll - M_PI/2.0), Float(attitude.yaw), Float(attitude.pitch))
        }
        
        //sceneView.allowsCameraControl = true
        
        //            //now you could begin to build your scene with the device's camera video as your background
        ////            let scene = SCNScene()
        //
        ////            let boxGeometry = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 1.0)
        ////            let boxNode = SCNNode(geometry: boxGeometry)
        ////            scene.rootNode.addChildNode(boxNode)
        ////            sceneView.scene = scene
        //
        //            //create scene
        //            let scene = SCNScene();
        //            sceneView.scene = scene;
        //
        //            // create an SCNCamera object and an SCNNode instance
        //            //assign the SCNCamera object to the camera property of cameraNode
        //            let camera = SCNCamera();
        //            let cameraNode = SCNNode();
        //            cameraNode.camera=camera;
        //            cameraNode.position = SCNVector3(-3.0, 3.0, 3.0);
        //
        //            //you create an SCNLight object and a SCNNode named lightNode
        //            let light = SCNLight();
        //            //light type distributes light evenly
        //            //in all directions from a point in 3D space.
        //            light.type = SCNLightTypeOmni;
        //
        //
        //            let lightNode = SCNNode();
        //            lightNode.light = light;
        //            lightNode.position = SCNVector3(x:1.5,y:1.5,z:1.5);
        //
        //            let cubeGeometry = SCNBox(width: 1.0, height: 1.0, length:1.0, chamferRadius: 0.0);
        //            let cubeNode = SCNNode(geometry: cubeGeometry);
        //
        //            let planeGeometry = SCNPlane(width: 5.0, height: 5.0);
        //            let planeNode = SCNNode(geometry: planeGeometry);
        //            //changing euler angles property to rotate plane backwards by 90 degrees
        //            //rotation angles are calculated in radians, so use functions below
        //            planeNode.eulerAngles = SCNVector3(x: GLKMathDegreesToRadians(-90), y: 0, z: 0);
        //            planeNode.position = SCNVector3(x: 0, y: -0.5, z: 0);
        //
        //            //now add color/material to cube and plane
        //            let redMaterial = SCNMaterial();
        //            //diffuse property of a material determines how it appears when under direct light.
        //
        //            //NOTE:  many other acceptable object types to assign to this property, such as UIImage, CALayer, and even a SpriteKit texture (SKTexture).
        //            redMaterial.diffuse.contents = UIColor.redColor();
        //            cubeGeometry.materials = [redMaterial];
        //
        //            let greenMaterial = SCNMaterial();
        //            greenMaterial.diffuse.contents = UIColor.greenColor();
        //            planeGeometry.materials = [greenMaterial];
        //
        //
        //
        //
        //            //code to always have camera look at cube
        //            let constraint = SCNLookAtConstraint(target: cubeNode );
        //
        //            //To ensure that the camera will remain parallel with the horizon and viewport, your device's screen in this case. This is done by disabling rotation along the roll axis, the axis pointing from the camera to the constraint's target.
        //            constraint.gimbalLockEnabled = true;
        //            cameraNode.constraints = [constraint]
        //
        //            scene.rootNode.addChildNode(lightNode)
        //            scene.rootNode.addChildNode(cameraNode)
        //            scene.rootNode.addChildNode(cubeNode)
        //            //scene.rootNode.addChildNode(planeNode)
    }
    
    
    
    
    
    func normalizeDifference (a:SCNVector3,b:SCNVector3) -> SCNVector3 {
        
        //take difference
        let difference = SCNVector3(x:b.x-a.x, y:b.y-a.y, z:b.z-a.z)
        var magnitude = difference.x*difference.x
        magnitude += difference.y*difference.y
        magnitude += difference.z*difference.z
        magnitude = sqrt(Float(magnitude))
        
        return SCNVector3(difference.x/magnitude ,difference.y/magnitude , difference.z/magnitude)
        
    }
    
    func dot (a:SCNVector3,b:SCNVector3) -> Float {
        
        return a.x * b.x + a.y * b.y + a.z * b.z
        
    }
    
    func cross (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        
        let x = left.y*right.z - left.z*right.y
        let y = left.z*right.x - left.x*right.z
        let z = left.x*right.y - left.y*right.x
        
        return SCNVector3(x: x, y: y, z: z)
    }
    
    func createQuatFromAxisAndRotation(axis:SCNVector3,angle:Float) -> SCNVector4 {
        
        var q = SCNVector4()
        
        q.x = axis.x * Float(sin(angle/2.0))
        q.y = axis.y * Float(sin(angle/2.0))
        q.z = axis.z * Float(sin(angle/2.0))
        q.w = Float(cos(angle/2.0))
        
        return q
    }
    
     func multQuat(left: SCNMatrix4, right: SCNVector4) -> SCNVector4 {
    let x = left.m11*right.x + left.m21*right.y + left.m31*right.z
    let y = left.m12*right.x + left.m22*right.y + left.m32*right.z
    let z = left.m13*right.x + left.m23*right.y + left.m33*right.z
    
    return SCNVector4(x: x, y: y, z: z, w: right.w * left.m44)
    }
    
    
    
    
    
    func configureDevice() {
        if let device = captureDevice {
            do {
                try device.lockForConfiguration()
                device.focusMode = .AutoFocus
                device.unlockForConfiguration()
            } catch let error as NSError {
                print(error.code)
            }
        }
        
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        let screenSize = previewLayer!.bounds.size
        let frameSize:CGSize = view.frame.size
        if let touchPoint = touches.first {
            
            let location:CGPoint = touchPoint.locationInView(self.view)
            
            let x = location.x / frameSize.width
            let y = 1.0 - (location.x / frameSize.width)
            
            let focusPoint = CGPoint(x: x, y: y)
            
            print("POINT : X: \(x), Y: \(y)")
            
            
            let captureDevice = (AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) as! [AVCaptureDevice]).filter{$0.position == .Back}.first
            
            if let device = captureDevice {
                do {
                    try device.lockForConfiguration()
                    
                    let support:Bool = device.focusPointOfInterestSupported
                    
                    if support  {
                        
                        print("focusPointOfInterestSupported: \(support)")
                        
                        device.focusPointOfInterest = focusPoint
                        
                        // device.focusMode = .ContinuousAutoFocus
                        device.focusMode = .AutoFocus
                        // device.focusMode = .Locked
                        
                        device.unlockForConfiguration()
                        
                        print("Focus point was set successfully")
                    }
                    else{
                        print("focusPointOfInterestSupported is not supported: \(support)")
                    }
                }
                catch {
                    // just ignore
                    print("Focus point error")
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if let touch = touches.first{
            print("\(touch)")
        }
        super.touchesEnded(touches, withEvent: event)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if let touch = touches.first{
            print("\(touch)")
        }
        super.touchesMoved(touches, withEvent: event)
    }
    
    
    func beginSession() {
        
        configureDevice()
        
        try! captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        // Cannot invoke initializer for type 'AVCaptureDeviceInput' with an argument list of type '(device: AVCaptureDevice?, error: inout NSError?)'
        
        //        let cameraVideoLayer = AVCaptureVideoPreviewLayer.layerWithSession(captureSession) as AVCaptureVideoPreviewLayer
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        
        //        self.view.layer.addSublayer(previewLayer!)
        // 11/15/2016
        //KEY, create UIView, add sublayer to it, and add subview to main view
        
        
        videoView.frame = self.view.bounds
        previewLayer?.frame = self.view.layer.frame
        previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoView.layer.addSublayer(previewLayer!)
        captureSession.startRunning()
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    
}

extension GameViewController: SCNSceneRendererDelegate {
    // 2
    func renderer(renderer: SCNSceneRenderer, updateAtTime time:
        NSTimeInterval) {
           
            
            xStep+=0.05
            //boxNode.position.x += 0.05
            //boxNode.position = SCNVector3Make(Float(xStep), boxNode.position.y, boxNode.position.z)
            print(pointer!.rotation )
            if (direction){
                
                boxNode.position.x+=0.3
                
            }
            else if(!direction){
                boxNode.position.x-=0.3

            }
            
            if(boxNode.position.x < 0 || boxNode.position.x > 20.00){
                direction = !direction
            }
            
            var normDist = normalizeDifference((pointer?.position)!, b: boxNode.position)
            //print(normDist)
            //        if normDist.z == 0.0{
            //            normDist.z = 1.0
            //        }
            
            //let axes = SCNVector3((pointer?.orientation.x)!,(pointer?.orientation.y)!,(pointer?.orientation.z)!)
            if((finalAxes) != nil){
            let axes = SCNVector3(finalAxes.x,finalAxes.y,finalAxes.z)
            
            //print(axes)
            
            //let axis = cross(axes, right: normDist )
            //print(axes)
            let angle = dot(axes, b: normDist)
//            let offset = SCNVector4(0,0,1,-angle)
            //pointer!.rotation.x = cos(angle) - sin(angle)
            //let quat = createQuatFromAxisAndRotation(axes, angle: angle)

//            pointer!.rotation.x = cos(angle) + sin(angle)
            
            //pointer!.rotation.z = -angle * 0.8
//            let quat = createQuatFromAxisAndRotation(axes, angle: angle)
            
            
            //pointer!.rotation = SCNVector4(0,0,1,xStep)
            //pointer!.rotation = SCNVector4(axes.x+offset.x,pointer!.rotation.y,axes.z+offset.z,0.0)
            }
    }
    
}
