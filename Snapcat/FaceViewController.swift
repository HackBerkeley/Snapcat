//
//  ViewController.swift
//  Snapcat
//
//  Created by Luke Brody on 3/13/17.
//  Copyright © 2017 Luke Brody. All rights reserved.
//

import UIKit
import AVFoundation

class FaceLayer : CALayer {
    
    override init() {
        super.init()
        
        addSublayer(mouth)
        addSublayer(leftEye)
        addSublayer(rightEye)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(filter : CatFilter) {
    
        contents = filter.features[.face]?.cgImage
        mouth.contents = filter.features[.mouth]?.cgImage
        leftEye.contents = filter.features[.leftEye]?.cgImage
        rightEye.contents = filter.features[.rightEye]?.cgImage
    }
    
    let mouth = CALayer()
    let leftEye = CALayer()
    let rightEye = CALayer()
    
    func process(feature: CIFaceFeature) {
        bounds = feature.bounds
    }
    
}

class FaceViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var filter : CatFilter! {
        didSet {
            faceLayer.contents = filter.features[.face]?.cgImage
            mouthLayer.contents = filter.features[.mouth]?.cgImage
            leftEyeLayer.contents = filter.features[.leftEye]?.cgImage
            rightEyeLayer.contents = filter.features[.rightEye]?.cgImage
        }
    }
    
    
    let (context, detector) : (CIContext, CIDetector) = {
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: context, options: [
            CIDetectorTracking: true,
            CIDetectorNumberOfAngles: 5
            ])!
        
        return (context, detector)
    }()
    
    //We need the output so we can set ourselves as delegate after
    lazy var session : AVCaptureSession = {
        //Get the front facing camera
        let device = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front)!
        let input = try! AVCaptureDeviceInput(device: device)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: .main)
        
        let result = AVCaptureSession()
            
        result.addInput(input)
        result.addOutput(output)
        
        return result
    }()
    
    let faceLayer = CALayer()
    let mouthLayer = CALayer()
    let leftEyeLayer = CALayer()
    let rightEyeLayer = CALayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.layer.addSublayer(faceLayer)
        
        faceLayer.addSublayer(mouthLayer)
        faceLayer.addSublayer(leftEyeLayer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        session.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        session.stopRunning()
    }
    
    private let transformFilter = CIFilter(name: "CIAffineTransform")!
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        let pixelBuffer : CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        let image = CIImage(cvImageBuffer: pixelBuffer)
        
        /*
         The image comes in landscape, and not flipped so it looks weird and un-mirror-like.
         
         We need to rotate the image 90º clockwise, and flip it.
         
         The comment below each transform operation shows the transformation state after said operation.
         w = the original width of the image
         h = the original height of the image
         */
        
        var transform = CGAffineTransform.identity
        
        /*
          _____ (w,h)
         |     |
         |_____|
         (0,0)
         
         */
        
        transform = transform.translatedBy(x: image.extent.height, y: image.extent.width)
        
        /*
          _____ (h+w,w+h)
         |     |
         |_____|
         (h,w)
         x
         (0,0)
         */
        
        transform = transform.rotated(by: -CGFloat(M_PI_2))
        
        /*
          ____(h+h,w)
         |    |
         |    |
         |____|
         (h,0)
         */
        
        //We're going to mirror the image so it looks like a ...mirror
        transform = transform.scaledBy(x: 1, y: -1)
        
        /*
         ____ (h,w)
         |    |
         |    |
         |____|
         (0,0)
         */
        
        transformFilter.setValue(NSValue(cgAffineTransform: transform), forKey: "inputTransform")
        
        //first, rotate the image because it comes in landscape
        transformFilter.setValue(image, forKey: "inputImage")
        
        let rotated = transformFilter.value(forKey: "outputImage") as! CIImage
        
        let cgImage = context.createCGImage(rotated, from: rotated.extent)
        
        view.layer.contents = cgImage
        
        //find faces in the image
        let features = detector.features(in: rotated)
        
        let uiTransform = CGAffineTransform(translationX: 0, y: view.layer.frame.height).scaledBy(x: view.layer.frame.width/rotated.extent.width, y: -view.layer.frame.height/rotated.extent.height)
        
        //only handle one feature
        if features.count > 0 {
            let faceFeature = features[0] as! CIFaceFeature
            
            let faceRect = faceFeature.bounds.applying(uiTransform)
            
            faceLayer.opacity = 1
            
            faceLayer.frame = faceRect
            
            if faceFeature.hasFaceAngle {
                
                let rotateRadians = (CGFloat(faceFeature.faceAngle) / 360) * (2 * CGFloat(M_PI))
                
                faceLayer.transform = CATransform3DMakeRotation(rotateRadians, 0, 1, 1)
            } else {
                faceLayer.transform = CATransform3DIdentity
            }
            
            //if we have the mouth
            if faceFeature.hasMouthPosition {
                mouthLayer.opacity = 1
                
                //set the mouth's position as the mouth position translated to ui space then translated into facelayer space
                
                let position = view.layer.convert(faceFeature.mouthPosition.applying(uiTransform), to: faceLayer)
                
                var frame = faceLayer.frame
                
                frame.size.width *= 0.5
                frame.size.height *= 0.2
                
                mouthLayer.frame = frame
                
                mouthLayer.position = position
                
                
            } else {
                mouthLayer.opacity = 0
            }
            
            //if we have the left eye
            if faceFeature.hasLeftEyePosition {
                leftEyeLayer.opacity = 1
                
                let position = view.layer.convert(faceFeature.leftEyePosition.applying(uiTransform), to: faceLayer)
                
                var frame = faceLayer.frame
                
                frame.size.width *= 0.2
                frame.size.height *= 0.2
                
                leftEyeLayer.frame = frame
                
                leftEyeLayer.position = position
            } else {
                leftEyeLayer.opacity = 0
            }

            
        } else {
            faceLayer.opacity = 0
        }
    }

}

