//
//  ViewController.swift
//  Snapcat
//
//  Created by Luke Brody on 3/13/17.
//  Copyright © 2017 Luke Brody. All rights reserved.
//

import UIKit
import AVFoundation

/**
 The FaceViewController runs the scene in our app where the aciton happens.
 It's reponsibilities include:
 - Setting up the camera
 - Detecting faces
 - Moving the images that compose the CatFace
 
 Since it is a view controller, it subclasses UIViewController.
 FaceViewController adopts the AVCaptureVideoDataOutputSampleBufferDelegate (https://developer.apple.com/reference/avfoundation/avcapturevideodataoutputsamplebufferdelegate) protocol since it needs to recieve video buffers.
 
 The view heirarchy of FaceViewController is as follows:
 
                  view
                    |
                view.layer
                    |
                faceMaskLayer
                    |
                featureLayers
 */

class FaceViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //TODO: Add all the face element layers
    
    /**
     We're showing one CatFace filter.
     
     When it's changed ('didSet') we should change the contents of the faceMaskLayer, as well as any face feature layers.
    */
    //TODO: Implement this
    
    /**
     Here we initialize the gpuContext, which managed all our computations (rotation, findingFaces) on the GPU.
     We're also going to create the CIDetector (https://developer.apple.com/reference/coreimage/cidetector) that's going to find faces.
    */
    //TODO: Add the CIDetector to find faces
    private let gpuContext = CIContext()
    
    /**
     This is the 'capture session' that represent's our app's use of the camera hardware.
     We're going to initialize it in a 'lazy var' since it needs to use `self` and `let` declarations need to be initialized with self, which would lead to a dependency loop.
    */
    private lazy var session : AVCaptureSession = {
        //Get the front facing camera
        let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front)!
        let input = try! AVCaptureDeviceInput(device: device)
        
        //Set up an ouptut so we can get data from the camera
        //We 'delegate' ourselves as the 'delegate' to this output, so we recieve data in the captureOutput method.
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: .main)
        
        let result = AVCaptureSession()
            
        result.addInput(input)
        result.addOutput(output)
        
        return result
    }()
    
    /**
     This method is called by UIKit when the view is first loaded from the storyboard.
     Traditionally, we set up views here.
     The only thing that needs to happen is adding the faceMaskLayer to the view's given layer.
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //TODO: Add the faceMask
    }
    
    /**
     This method gets called by UIKit when our view appears to the user, for example when we select an entry from our previous table view and it gets pushed to the screen.
     We'll start running the whole video capture session here.
    */
    override func viewDidAppear(_ animated: Bool) {
        session.startRunning()
    }
    
    /**
     Likewise, this is called when the user navigates away from the view, or the app closes.
     We should pause the video capture session, so it doesn't use system resources uneccessarily.
    */
    override func viewWillDisappear(_ animated: Bool) {
        session.stopRunning()
    }
    
    /**
     This function moves around our layers (faceMaskLayer, featureLayers) based on a face feature.
     It uses a transformation (CGAffineTransform) to move from coordinates in the camera image to coordinates in the user interace.
     */
    private func moveFaceLayers(basedOn faceFeature: CIFaceFeature, transformFromDetectorToUI uiTransform: CGAffineTransform) {
        
        //Get the bounds from the face feature, and then convert them from coordinates in the image from the camera to coordinates in the user interface
        let faceRect = faceFeature.bounds.applying(uiTransform)
        
        //Move the faceMaskLayer to this location
        //TODO
        
        //If the faceFeature has a face rotation angle, rotate the face mask by that amount.
        //Otherwise, just pass an identity transform with no rotation
        let rotationTrasnformation : CATransform3D = {
            if faceFeature.hasFaceAngle {
                //The CIFaceFeature gives us an angle in degrees (for some reason), so we should convert it to radians.
                return CATransform3DMakeRotation(CGFloat(faceFeature.faceAngle.toRadians), 0, 1, 1)
            } else {
                return CATransform3DIdentity
            }
        }()
            
        //TODO: Rotate the face mask
        
        /*
         TODO: Iterate through all the sub-features, and their layers
         
         - see if that feature was detected in the face, if it was we have a positiion
            - if it was, make it visible
            - move the sub-layer to that positiion
            - scale the sub-layer to be proportional to the face layer
         - otherwise make invisible
        */
        
    }
    
    func transformToView(from image: CIImage) -> CGAffineTransform {
        /*
         This is transform from the image to the UI. First, we transform by the UI
         When I refer to the UI, I generally mean view.layer
         
         img.w = Camera Image With
         img.h = Camera Image Height
         
         ui.w = view.layer.frame.width
         ui.h = view.layer.frame.height
         
         The pictures represent the state of the transform after the previous line executes.
         The letters in the image identify each corner.
         */
        
        var uiTransform = CGAffineTransform.identity
        
        /*
         .
         .
         .____(img.w, img.h)
         |a  b|
         |    |
         |    |
         |c__d|.......
         (0,0)
         */
        
        uiTransform = uiTransform.translatedBy(x: 0, y: view.layer.frame.height)
        
        /*
         .____ (img.w, img.h + ui.h)
         |a  b|
         |    |
         |    |
         |c__d|
         .(0, ui.h)
         .................
         */
        
        uiTransform = uiTransform.scaledBy(x: view.layer.frame.width/image.extent.width, y: -view.layer.frame.height/image.extent.height)
        
        /*
         .
         .__ (ui.w, ui.h)
         |cd|
         |ab|........
         (0,0)
         */
        
        return uiTransform
    }
    
    /**
     The we've told the AVCaptureVideoDataOutput to call this method when it has a new buffer ready (`output.setSampleBufferDelegate(self, queue: .main)` in session setup)
    */
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        //Get the video part of the buffer. Sometimes this might have audio, but not today
        let pixelBuffer : CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        //Transfer the image to the GPU
        let image = CIImage(cvImageBuffer: pixelBuffer)
        
        //The image comes in in landscape and not mirrored. Rotate and flip it. See Utilities.swift
        let rotated = rotateImageFromCamera(image: image)
        
        //Render the image back so we can display it in view.layer
        let cgImage = gpuContext.createCGImage(rotated, from: rotated.extent)
        
        //make a transform where we can put in a coordinate in the image and get out a coordinate in `view` on the screen
        let uiTransform = transformToView(from: rotated)
        
        //We begin a CATransaction, or an interaction with CALayers by changing their properties
        //The changes only get committed on CATransaction.commit()
        CATransaction.begin()
        //There's a 0.25 second animation by default. Let's turn that off. Mess with this number to see different animation durations
        CATransaction.setAnimationDuration(0)
        
        //Display the image from the camera
        view.layer.contents = cgImage
        
        /*
         TODO:
         
         - get the face features from the image
         - if there are faces, make our layers visible and move them (moveFaceLayers), otherwise, make them invisible
        */
        
        CATransaction.commit()
    }

}

