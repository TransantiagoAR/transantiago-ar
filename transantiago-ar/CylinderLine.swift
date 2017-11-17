//
//  CylinderLine.swift
//  transantiago-ar
//
//  Created by Nicolás Gebauer on 16-11-17.
//  Copyright © 2017 Nicolás Gebauer. All rights reserved.
//

import SceneKit

class CylinderLine: SCNNode {
  
  init (parent: SCNNode,//Needed to line to your scene
    v1: SCNVector3,//Source
    v2: SCNVector3,//Destination
    radius: CGFloat,// Radius of the cylinder
    radSegmentCount: Int, // Number of faces of the cylinder
    color: UIColor )// Color of the cylinder
  {
    super.init()
    
    //Calcul the height of our line
    let  height = v1.distance(receiver: v2)
    
    //set position to v1 coordonate
    position = v1
    
    //Create the second node to draw direction vector
    let nodeV2 = SCNNode()
    
    //define his position
    nodeV2.position = v2
    //add it to parent
    parent.addChildNode(nodeV2)
    
    //Align Z axis
    let zAlign = SCNNode()
    zAlign.eulerAngles.x = Float(CGFloat(Double.pi/2))
    
    //create our cylinder
    let cyl = SCNCylinder(radius: radius, height: CGFloat(height))
    cyl.radialSegmentCount = radSegmentCount
    cyl.firstMaterial?.diffuse.contents = color
    
    //Create node with cylinder
    let nodeCyl = SCNNode(geometry: cyl )
    nodeCyl.position.y = -height/2
    zAlign.addChildNode(nodeCyl)
    
    //Add it to child
    addChildNode(zAlign)
    
    //set constraint direction to our vector
    constraints = [SCNLookAtConstraint(target: nodeV2)]
  }
  
  override init() {
    super.init()
  }
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}

private extension SCNVector3{
  func distance(receiver:SCNVector3) -> Float{
    let xd = receiver.x - self.x
    let yd = receiver.y - self.y
    let zd = receiver.z - self.z
    let distance = Float(sqrt(xd * xd + yd * yd + zd * zd))
    
    if (distance < 0){
      return (distance * -1)
    } else {
      return (distance)
    }
  }
}

