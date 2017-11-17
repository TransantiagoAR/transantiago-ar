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
import Vision
import Alamofire

class ViewController: UIViewController, SceneLocationViewDelegate {
  
  let sceneLocationView = SceneLocationView()
  var userLocation: CLLocation?
  var didSetUser = false
  var didSetNode = false
  var latestHitCenter: SCNVector3?
  
  var processingSign = false
  var latestCiImage: CIImage?
  var latestPosition: CGPoint?
  var visionRequests = [VNRequest]()
  let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml")
  let targetIdentifiers = "scoreboard street sign"
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneLocationView.showAxesNode = false
    sceneLocationView.showsStatistics = true
    sceneLocationView.run()
    view.addSubview(sceneLocationView)
    sceneLocationView.locationDelegate = self
    
    guard let selectedModel = try? VNCoreMLModel(for: Inceptionv3().model) else { // (Optional) This can be replaced with other models on https://developer.apple.com/machine-learning/
      fatalError("Could not load model. Ensure model has been drag and dropped (copied) to XCode Project from https://developer.apple.com/machine-learning/ . Also ensure the model is part of a target (see: https://stackoverflow.com/questions/45884085/model-is-not-part-of-any-target-add-the-model-to-a-target-to-enable-generation ")
    }
    let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
    classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
    visionRequests = [classificationRequest]
    loopCoreMLUpdate()
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
    
//    let coordinate2 = CLLocationCoordinate2D(latitude: 37.787293, longitude: -122.408160)
//    let location2 = CLLocation(coordinate: coordinate2, altitude: -2)
//    let annotationNode2 = LocationAnnotationNode(location: location2, image: image2)
    
    let coordinate3 = CLLocationCoordinate2D(latitude: 37.786934, longitude: -122.408026)
    let location3 = CLLocation(coordinate: coordinate3, altitude: -2)
    let annotationNode3 = LocationAnnotationNode(location: location3, image: image)
    
    annotationNode1.scaleRelativeToDistance = true
    //    annotationNode2.scaleRelativeToDistance = true
    annotationNode3.scaleRelativeToDistance = true
    
    sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode1)
//    sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode2)
    sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: annotationNode3)
    
//    drawPath(node1: annotationNode1, node2: annotationNode2)
//    drawPath(node1: annotationNode2, node2: annotationNode3)
    //    let userNode = LocationAnnotationNode(location: sceneLocationView.currentLocation(), image: image)
    //    drawPath(node1: annotationNode3, node2: userNode)
  }
  
  func drawPath(node1: LocationAnnotationNode, node2: LocationAnnotationNode) {
    let node = sceneLocationView.sceneNode!
    let cylinder = CylinderLine(parent: node, v1: node1.position, v2: node2.position, radius: 0.1, radSegmentCount: 48, color: .green)
    node.addChildNode(cylinder)
  }
  
  //  func getValidDistance() -> SCNVector3 {
  //    print("getValidDistance")
  //    let screenCentre = CGPoint(x: sceneLocationView.bounds.midX, y: sceneLocationView.bounds.midY)
  //    let arHitTestResults = sceneLocationView.hitTest(screenCentre, types: [.featurePoint])
  //    if let closestResult = arHitTestResults.first {
  //      if closestResult.distance < 0.4 {
  //        return getValidDistance()
  //      }
  //      let transform = closestResult.worldTransform
  //      return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
  //    } else {
  //      return getValidDistance()
  //    }
  //  }
  
  //      guard let savedBounds = self.bounds else { return }
  //      let screenCentre = CGPoint(x: savedBounds.midX, y: savedBounds.midY)
  //      let arHitTestResults = self.sceneLocationView.hitTest(screenCentre, types: [.featurePoint])
  //      if let closestResult = arHitTestResults.first {
  //        if closestResult.distance < 0.5 {
  //          return self.recognizedSign()
  //        }
  //        let transform = closestResult.worldTransform
  //        self.latestHitCenter = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
  //
  //        let items = [PopUpViewItem(name: "n1", eta: "5 min"), PopUpViewItem(name: "n2", eta: "1 min")]
  //        let table = PopupTableView(items: items)
  //        let image = table.image()
  //
  //        let plane = SCNPlane(width: image.size.width / 1000, height: image.size.height / 1000)
  //        plane.firstMaterial!.diffuse.contents = image
  //        plane.firstMaterial!.lightingModel = .constant
  //
  //        let annotationNode = SCNNode()
  //        annotationNode.geometry = plane
  //        annotationNode.position = self.latestHitCenter!
  //
  //        let billboardConstraint = SCNBillboardConstraint()
  //        billboardConstraint.freeAxes = SCNBillboardAxis.Y
  //        let constraints = [billboardConstraint]
  //
  //        annotationNode.constraints = constraints
  //
  //        self.sceneLocationView.sceneNode!.addChildNode(annotationNode)
  
  func foundSign() {
    guard !processingSign else { return print("processing...") }
    processingSign = true
    print("sign START")
    let context = CIContext.init(options: nil)
    let cgImage = context.createCGImage(latestCiImage!, from: latestCiImage!.extent)!
    let image = UIImage.init(cgImage: cgImage)
    guard let imageRepresentation = UIImageJPEGRepresentation(image, 0.8) else {
      print("imageRepresentation nil")
      return processingSign = false
    }
    let imageData = imageRepresentation as NSData
    let base64String = imageData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
    let parameters: Parameters = [ "base64": base64String ]
    print("### POSTING")
    Alamofire.request("https://3ab5ea6f.ngrok.io/sign", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
      print("Response JSON")
      print(response.error ?? "no error")
      print(response.result.value ?? "no value")
      print("sign DONE")
      self.processingSign = false
    }
  }
  
  // MARK: - CoreML
  
  func loopCoreMLUpdate() {
    dispatchQueueML.async {
      self.updateCoreML()
      sleep(1)
      self.loopCoreMLUpdate()
    }
  }
  
  func classificationCompleteHandler(request: VNRequest, error: Error?) {
    // Catch Errors
    if error != nil {
      print("Error: " + (error?.localizedDescription)!)
      return
    }
    guard let observations = request.results else {
      print("No results")
      return
    }
    
    if let observation = observations[0] as? VNClassificationObservation {
      let identifier = observation.identifier
      print(identifier)
      if targetIdentifiers.contains(identifier) {
//        print("Found: \(identifier)")
        foundSign()
      }
    }
  }
  
  func updateCoreML() {
    guard let pixbuff = (sceneLocationView.session.currentFrame?.capturedImage) else { return }
    let ciImage = CIImage(cvPixelBuffer: pixbuff)
    latestCiImage = ciImage
    DispatchQueue.main.async {
      self.latestPosition = CGPoint(x: self.sceneLocationView.bounds.midX, y: self.sceneLocationView.bounds.midY)
    }
    let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    do {
      try imageRequestHandler.perform(self.visionRequests)
    } catch {
      print(error)
    }
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


