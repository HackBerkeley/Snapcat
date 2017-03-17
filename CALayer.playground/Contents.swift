import UIKit
//This framework is going to let us show views right in the playground.
import PlaygroundSupport

/*
 CALayer
 
 We're going to use CALayer's to implement the face mask, so let's mess around with them
 */

let view = UIView(frame: CGRect(x: 0, y:0, width: 400, height: 300))

PlaygroundPage.current.liveView = view

view.layer.backgroundColor = UIColor.blue.cgColor

//We'll call view.layer our "rootLayer"
let rootLayer = view.layer

let campanile = CALayer()
campanile.backgroundColor = UIColor.green.cgColor
campanile.frame = CGRect(x: 100, y: 100, width: 100, height: 200)

//We can add sublayers to other layers
rootLayer.addSublayer(campanile)

//We can give layers an image by setting their "contents" as a cgImage
campanile.contents = UIImage(named: "Campanile.JPG")!.cgImage

//The position of a layer is mapped to its center
campanile.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)

//We can rotate a layer by applying a "transform"
campanile.transform = CATransform3DMakeRotation(CGFloat(M_PI_2), 0, 0, 1)