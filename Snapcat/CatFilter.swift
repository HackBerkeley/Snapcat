//
//  CatFilter.swift
//  Snapcat
//
//  Created by Luke Brody on 3/13/17.
//  Copyright © 2017 Luke Brody. All rights reserved.
//

import Foundation
import UIKit
import CoreImage

//http://stackoverflow.com/questions/10720569/is-there-a-way-to-calculate-the-cgaffinetransform-needed-to-transform-a-view-fro
func transformFromRect(from: CGRect, toRect to: CGRect) -> CGAffineTransform {
    let transform = CGAffineTransform(translationX: to.midX - from.midX, y: to.midY - from.midY)
    return transform.scaledBy(x: to.width/from.width, y: to.height/from.height)
}

extension CGAffineTransform {
    mutating func rotateAroundCenter(byRadians angle: CGFloat, resultantSize) {
        self = self.translatedBy(x: faceFeature.bounds.width / 2, y: faceFeature.bounds.height / 2)
        self = self.rotated(by: angle)
        self = self.translatedBy(x: -faceFeature.bounds.width / 2, y: -faceFeature.bounds.height / 2)
    }
}

class CatFilter {
    
    let name : String
    
    enum Feature : String {
        case face = "Face"
        case mouth = "Mouth"
        case leftEye = "LeftEye"
        case rightEye = "RightEye"
    }
    
    let features : [Feature : CIImage]
    
    init(name: String) {
        
        var features = [Feature : CIImage]()
        
        //If any of these image loads fails, the entry in the dictionary is simply not set.
        for feature in [Feature.face, .mouth, .leftEye, .rightEye] {
            if let image = UIImage(named: name + feature.rawValue) {
                features[feature] = CIImage(image: image)
            }
        }
        
        self.features = features
        self.name = name
    }
    
    static let filters = [
        CatFilter(name: "Test")
    ]
    
    private let transformFilter = CIFilter(name: "CIAffineTransform")!
    
    private let cropFilter = CIFilter(name: "CICrop")!
    
    private let compositeFilter = CIFilter(name: "CISourceOverCompositing")!
    
    private let faceRecognizer = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [
        CIDetectorTracking: true,
        CIDetectorNumberOfAngles: 5
        ])!
    
    func transform(image: CIImage, fromRect: CGRect, toRect: CGRect, rotateBy angle: CGFloat, scaleBy scale: CGSize) -> CIImage {
        var transform = transformFromRect(from: fromRect, toRect: toRect)
        
        transform = transform.translatedBy(x: toRect.width / 2, y: toRect.height / 2)
        transform = transform.rotated(by: angle)
        transform = transform.scaledBy(x: scale.width, y: scale.height)
        transform = transform.translatedBy(x: -toRect.width / 2, y: -toRect.height / 2)
        
        transformFilter.setValue(NSValue(cgAffineTransform: transform), forKey: "inputTransform")
        transformFilter.setValue(image, forKey: "inputImage")
        
        return transformFilter.outputImage!
    }
    
    func apply(toImage pixelBuffer: CVImageBuffer) -> UIImage {
        
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
        
        var withFeatures = rotated
        
        //in the rotate image, find features
        for feature in faceRecognizer.features(in: rotated) {
            switch feature.type {
            case CIFeatureTypeFace:
                
                let faceFeature = feature as! CIFaceFeature
                
                //if we have a image for the face bounds, draw it
                if let boundsImage = features[.face] {
                    
                    var transform = transformFromRect(from: boundsImage.extent, toRect: faceFeature.bounds)
                    
                    if faceFeature.hasFaceAngle {
                        transform = transform.translatedBy(x: faceFeature.bounds.width / 2, y: faceFeature.bounds.height / 2)
                        
                        let rotationRadians = (CGFloat(faceFeature.faceAngle) / 360) * CGFloat(2 * M_PI)
                        
                        transform = transform.rotated(by: -rotationRadians)
                        transform = transform.translatedBy(x: -faceFeature.bounds.width / 2, y: -faceFeature.bounds.height / 2)
                    }
                    
                    //we should transform the image to the bounds, by scaling it
                    transformFilter.setValue(NSValue(cgAffineTransform: transform), forKey: "inputTransform")
                    
                    transformFilter.setValue(boundsImage, forKey: "inputImage")
                    
                    //composite the image onto rotate
                    compositeFilter.setValue(withFeatures, forKey: "inputBackgroundImage")
                    compositeFilter.setValue(transformFilter.value(forKey: "outputImage"), forKey: "inputImage")
                    
                    withFeatures = compositeFilter.value(forKey: "outputImage") as! CIImage
                }
            default:
                break
            }
        }
        
        //always crop the result to the original image size
        let vector = CIVector(cgRect: rotated.extent)
        cropFilter.setValue(vector, forKey: "inputRectangle")
        cropFilter.setValue(withFeatures, forKey: "inputImage")
        
        let cropped = cropFilter.value(forKey: "outputImage") as! CIImage
        
        return UIImage(ciImage: cropped)
    }
}

/**
 https://developer.apple.com/library/content/documentation/GraphicsImaging/Reference/CoreImageFilterReference/
 */
let filter = CIFilter(name: "CIComicEffect")!

func apply(filter _: CatFilter, to image: UIImage) -> UIImage {
    let ciImage = CIImage(image: image)!
    filter.setDefaults()
    filter.setValue(ciImage, forKey: "inputImage")
    let ciOutput = filter.value(forKey: "outputImage") as! CIImage
    return UIImage(ciImage: ciOutput)
}
