//
//  CatFace.swift
//  Snapcat
//
//  Created by Luke Brody on 3/13/17.
//

import Foundation
import UIKit

/**
 This CatFace class represents a "filter" that the user can put over their face.
 
 This is the main Model object in our app.
 */

//TODO: implement CatFace here

/**
 CIFaceFeature (https://developer.apple.com/reference/coreimage/cifacefeature) is the class given to us by CIDetector (the face detector class) to represent a face.
 We're going to extend it so we can get (or find out that the nonexistence of) each feature on the face based on our previously defined FeatureType
 */
extension CIFaceFeature {
    
    func getFeaturePosition(feature: CatFace.FeatureType) -> CGPoint? {
        switch feature {
        case .mouth:
            if hasMouthPosition {
                return mouthPosition
            }
        case .leftEye:
            if hasLeftEyePosition {
                return leftEyePosition
            }
        case .rightEye:
            if hasRightEyePosition {
                return rightEyePosition
            }
        }
        return nil
    }
    
}
