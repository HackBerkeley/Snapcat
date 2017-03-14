//
//  ViewController.swift
//  Snapcat
//
//  Created by Luke Brody on 3/13/17.
//  Copyright © 2017 Luke Brody. All rights reserved.
//

import UIKit
import AVFoundation

class FaceViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var filter : CatFilter!
    @IBOutlet weak var imageView: UIImageView!
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        session.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        session.stopRunning()
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        let pixelBuffer : CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        imageView.image = filter.apply(toImage: pixelBuffer)
    }

}

