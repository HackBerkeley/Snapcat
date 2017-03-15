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

extension CGRect {
    func centered(at center: CGPoint, scaledBy scaled: CGSize) -> CGRect {
        var result = self
        
        result.size.width *= scaled.width
        result.size.height *= scaled.height
        
        result.origin.x = center.x - (result.width / 2)
        result.origin.y = center.y - (result.height / 2)
        
        return result
        
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
    
    func transform(featureImage: CIImage, toBounds bounds: CGRect, rotation: CGFloat?) -> CIImage {
        var transform = transformFromRect(from: featureImage.extent, toRect: bounds)
        
        if let rotation = rotation {
            transform = transform.translatedBy(x: bounds.width / 2, y: bounds.height / 2)
            
            let rotationRadians = (CGFloat(rotation) / 360) * CGFloat(2 * M_PI)
            
            transform = transform.rotated(by: -rotationRadians)
            transform = transform.translatedBy(x: -bounds.width / 2, y: -bounds.height / 2)
        }
        
        //we should transform the image to the bounds, by scaling it
        transformFilter.setValue(NSValue(cgAffineTransform: transform), forKey: "inputTransform")
        
        transformFilter.setValue(featureImage, forKey: "inputImage")
        
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
        
        func compositeFeature(image: CIImage) {
            compositeFilter.setValue(withFeatures, forKey: "inputBackgroundImage")
            compositeFilter.setValue(image, forKey: "inputImage")
            
            withFeatures = compositeFilter.value(forKey: "outputImage") as! CIImage
        }
        
        //in the rotate image, find features
        for feature in faceRecognizer.features(in: rotated) {
            switch feature.type {
            case CIFeatureTypeFace:
                
                let faceFeature = feature as! CIFaceFeature
                
                //if we have a image for the face bounds, draw it
                if let boundsImage = features[.face] {
                    
                    let transformed = self.transform(featureImage: boundsImage, toBounds: faceFeature.bounds, rotation: faceFeature.hasFaceAngle ? CGFloat(faceFeature.faceAngle) : nil)
                    
                    compositeFeature(image: transformed)
                    
                }
                
                //if we have a mouth image, draw it as well
                if let mouthImage = features[.mouth], faceFeature.hasMouthPosition {
                    
                    let mouthBounds = faceFeature.bounds.centered(at: faceFeature.mouthPosition, scaledBy: CGSize(width: 0.5, height: 0.2))
                    
                    let transformed = self.transform(featureImage: mouthImage, toBounds: mouthBounds, rotation: faceFeature.hasFaceAngle ? CGFloat(faceFeature.faceAngle) : nil)
                    
                    compositeFeature(image: transformed)
                    
                }
                
                //if we have a mouth image, draw it as well
                if let leftEyeImage = features[.leftEye], faceFeature.hasLeftEyePosition {
                    
                    let leftEyeBounds = faceFeature.bounds.centered(at: faceFeature.leftEyePosition, scaledBy: CGSize(width: 0.2, height: 0.2))
                    
                    let transformed = self.transform(featureImage: leftEyeImage, toBounds: leftEyeBounds, rotation: faceFeature.hasFaceAngle ? CGFloat(faceFeature.faceAngle) : nil)
                    
                    compositeFeature(image: transformed)
                    
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
