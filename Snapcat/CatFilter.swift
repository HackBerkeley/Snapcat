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
    
    let features : [Feature : UIImage]
    
    init(name: String) {
        
        var features = [Feature : UIImage]()
        
        //If any of these image loads fails, the entry in the dictionary is simply not set.
        for feature in [Feature.face, .mouth, .leftEye, .rightEye] {
            features[feature] =  UIImage(named: name + feature.rawValue)
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
