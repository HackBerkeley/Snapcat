//
//  Utilities.swift
//  Snapcat
//
//  Created by Luke Brody on 3/14/17.
//  Copyright © 2017 Luke Brody. All rights reserved.
//

/**
 I've made this Utilities.swift file so I don't have to code "boring" parts during the workshop.
 */

import Foundation
import CoreImage

/**
 Takes an image from the front facing camera and rotates then mirrors it.
 */

//Filters are expensive to create, so we'll keep one around to use in the below function.
fileprivate let transformFilter = CIFilter(name: "CIAffineTransform")!

func rotateImageFromCamera(image: CIImage) -> CIImage {
    /*
     The image comes in landscape, and not flipped so it looks weird and un-mirror-like.
     
     We need to rotate the image 90º clockwise, and flip it.
     
     The comment below each transform operation shows the transformation state after said operation.
     w = the original width of the image
     h = the original height of the image
     */
    
    var transform = CGAffineTransform.identity
    
    /*
     .
     .
     ._____ (w,h)
     |     |
     |_____|........
     (0,0)
     
     */
    
    transform = transform.translatedBy(x: image.extent.height, y: image.extent.width)
    
    /*
     .     _____ (h+w,w+h)
     .    |     |
     .    |_____|
     .  (h,w)
     .
     .
     .........................
     (0,0)
     */
    
    transform = transform.rotated(by: -CGFloat(M_PI_2))
    
    /*
     .     ____(h+h,w)
     .    |    |
     .    |    |
     .....|____|......
     (h,0)
     */
    
    //We're going to mirror the image so it looks like a ...mirror
    transform = transform.scaledBy(x: 1, y: -1)
    
    /*
     .
     .____ (h,w)
     |    |
     |    |
     |____|............
     (0,0)
     */
    
    //Give the transform and input image to the filter
    transformFilter.setValue(NSValue(cgAffineTransform: transform), forKey: "inputTransform")
    transformFilter.setValue(image, forKey: "inputImage")
    
    return transformFilter.outputImage!
}

/**
 We're going to extend size so that we can divide two sizes.
 This is used in FaceViewController.swift
 */

extension CGSize {
    static func /(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width/rhs.width, height: lhs.height/rhs.height)
    }
}

extension Float {

    //Gets a value in degrees as radians
    //radians = (degress / 360) * 2π
    var toRadians : Float {
        return (self / 360) * (2 * Float(M_PI))
    }
}

extension CGRect {
    func scaledSize(by size: CGSize) -> CGRect {
        var result = self
        
        result.size.height *= size.height
        result.size.width *= size.width
        
        return result
    }
}
