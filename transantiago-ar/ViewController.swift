//
//  ViewController.swift
//  transantiago-ar
//
//  Created by Nicolás Gebauer on 16-11-17.
//  Copyright © 2017 Nicolás Gebauer. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import ARCL
import CoreLocation

class ViewController: UIViewController, ARSCNViewDelegate {
  
  let sceneLocationView = SceneLocationView()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneLocationView.showAxesNode = true
    sceneLocationView.showsStatistics = true
    sceneLocationView.run()
    view.addSubview(sceneLocationView)
    
    let coordinate = CLLocationCoordinate2D(latitude: 37.786915, longitude: -122.408154)
    let location = CLLocation(coordinate: coordinate, altitude: 0)
    let image = UIImage(named: "pin")!
    
    let annotationNode = LocationAnnotationNode(location: location, image: image)
    sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    sceneLocationView.frame = view.bounds
  }
  
}
