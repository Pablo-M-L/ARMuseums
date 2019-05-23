//
//  Exteensions.swift
//  ARMuseums
//
//  Created by admin on 23/05/2019.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation
import SceneKit

extension SCNNode{
    var width: Float{
        return (boundingBox.max.x - boundingBox.min.x) * scale.x
    }
    var height: Float{
        return (boundingBox.max.y - boundingBox.min.y) * scale.y
    }
    
    //mover el pivote
    func pivotToTopLeft(){
         let (min, max) = boundingBox
         pivot = SCNMatrix4MakeTranslation(min.x, (max.y-min.y) + min.y, 0)
        
    }
    
    func pivotToTopCenter(){
        let (min, max) = boundingBox
        pivot = SCNMatrix4MakeTranslation((max.x - min.x)/2, min.y + (max.y - min.y), 0)
    }
    
    func pivotToTopRight(){
        let (min, max) = boundingBox
        pivot = SCNMatrix4MakeTranslation(min.y + (max.y - min.y), (max.y-min.y) + min.y, 0)
    }
    
}
