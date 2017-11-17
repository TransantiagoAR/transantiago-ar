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

class ViewController: UIViewController, ARSCNViewDelegate, SceneLocationViewDelegate {
  
  let sceneLocationView = SceneLocationView()
  var userLocation: CLLocation?
  var didSetUser = false
  var didSetNode = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneLocationView.showAxesNode = true
    sceneLocationView.showsStatistics = true
    sceneLocationView.run()
    view.addSubview(sceneLocationView)
    sceneLocationView.locationDelegate = self
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    sceneLocationView.frame = view.bounds
  }
  
  func myRender() {
    let image = UIImage(named: "pin")!
    
    let items = [PopUpViewItem(name: "n1", eta: "5 min"), PopUpViewItem(name: "n2", eta: "1 min")]
    let table = PopupTableView(items: items)
    let image2 = table.image()
    
    let coordinate1 = CLLocationCoordinate2D(latitude: 37.787354, longitude: -122.408096)
    let location1 = CLLocation(coordinate: coordinate1, altitude: -2)
    let annotationNode1 = LocationAnnotationNode(location: location1, image: image)
    
    let coordinate2 = CLLocationCoordinate2D(latitude: 37.787293, longitude: -122.408160)
    let location2 = CLLocation(coordinate: coordinate2, altitude: -2)
    let annotationNode2 = LocationAnnotationNode(location: location2, image: image2)
    
    let coordinate3 = CLLocationCoordinate2D(latitude: 37.786934, longitude: -122.408026)
    let location3 = CLLocation(coordinate: coordinate3, altitude: -2)
    let annotationNode3 = LocationAnnotationNode(location: location3, image: image)
    
    annotationNode1.scaleRelativeToDistance = true
    annotationNode2.scaleRelativeToDistance = true
    annotationNode3.scaleRelativeToDistance = true
  
    sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode1)
    sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode2)
    sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode3)
    
    drawPath(node1: annotationNode1, node2: annotationNode2)
    drawPath(node1: annotationNode2, node2: annotationNode3)
    let userNode = LocationAnnotationNode(location: sceneLocationView.currentLocation(), image: image)
    drawPath(node1: annotationNode3, node2: userNode)
  }
  
  func drawPath(node1: LocationAnnotationNode, node2: LocationAnnotationNode) {
    let node = sceneLocationView.sceneNode!
    let cylinder = CylinderLine(parent: node, v1: node1.position, v2: node2.position, radius: 0.1, radSegmentCount: 48, color: .green)
    node.addChildNode(cylinder)
  }
  
  // MARK: - ARSCNViewDelegate

  func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
    glLineWidth(20)
  }
  
  // MARK: - SceneLocationViewDelegate
  
  func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
    if (!didSetUser && didSetNode) {
      myRender()
    }
    didSetUser = true
  }
  
  func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
    
  }
  
  func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
    
  }
  
  func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
    if (didSetUser && !didSetNode) {
      myRender()
    }
    didSetNode = true
  }
  
  func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
    
  }
  
}


