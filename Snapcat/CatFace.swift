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
class CatFace {
    
    let name : String //The name of the face. It shows up in the table view, and is used to load files for the face's image assets.
    let faceMaskImage : UIImage //This is the main face mask for the face.
    
    /**
     An enum in Swift, like in other languages, is a type of variable with discrete choices.
     enums can have "raw values" that their members correspond to. In this case we'll use the raw values to load image files corresponding to each feature.
     */
    enum FeatureType : String {
        case mouth = "Mouth"
        case leftEye = "LeftEye"
        case rightEye = "RightEye"
    }
    
    /**
     This is a dictionary. It relates feature types to images that correspond to that feature.
     For example, featureImages[FeatureType.mouth] == <a mouth image>
     
     In our CatFace class, we require this dictionary to have an entry for each feature type.
    */
    let featureImages : [FeatureType : UIImage]
    
    /**
     This is an initializer for the CatFace class. It takes in one argument.
    */
    init(name: String) {
        
        //We store the name given to the class instance
        self.name = name
        
        //We read the faceImage named "<name>Face"
        self.faceMaskImage = UIImage(named: name + "Face")!
        
        
        var featureImages = [FeatureType : UIImage]()
        
        //Read images for all the features
        for feature in [FeatureType.mouth, .leftEye, .rightEye] {
            featureImages[feature] = UIImage(named: name + feature.rawValue)!
        }
        
        self.featureImages = featureImages
    }
    
    /**
     The face recognition doesn't give us a size for the mouth or eyes, so we need to calculate that size based on the graphics' proprtions to each other.
     That's where this method comes into play.
    */
    func featureProportion(feature: FeatureType) -> CGSize {
        let featureImage = featureImages[feature]!
        
        return featureImage.size / faceMaskImage.size
    }
    
    /**
     Here's a list of all the faces we're using.
     'static' means it's a member of the class, rather than any instance of the class.
    */
    static let faces = [
        CatFace(name: "Test"),
        CatFace(name: "Whiskers"),
        CatFace(name: "Big Eyes"),
        CatFace(name: "Fish")
    ]
}

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
