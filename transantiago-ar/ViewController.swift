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
import MapKit

let BusColors: [UIColor] = [.red, .green, .blue, .black, .brown, .cyan, .magenta, .purple]
let BusAltitude: [Double] = [-3, -2.75, -2.5, -2.25, -2, -1.75, -1.5, -1.25, -1, -0.75]

class EtaNode {
  let node: LocationAnnotationNode
  
  init(node: LocationAnnotationNode) {
    self.node = node
  }
}

class Bus {
  let pid: String
  var journeys: [(Double, Double)] = []
  var etas: [String] = []
  let color: UIColor
  let altitude: Double
  
  init(pid: String, color: UIColor, altitude: Double) {
    self.pid = pid
    self.color = color
    self.altitude = altitude
  }
}

class BusNode {
  let pid: String
  let node: LocationAnnotationNode
  let color: UIColor
  
  init(pid: String, node: LocationAnnotationNode, color: UIColor) {
    self.pid = pid
    self.node = node
    self.color = color
  }
}

class BusStopBus {
  let pid: String
  var etas: [String] = []
  
  init(pid: String) {
    self.pid = pid
  }
}

class BusStop {
  let stop: String
  var buses: [BusStopBus] = []
  
  init(stop: String) {
    self.stop = stop
  }
}

class ViewController: UIViewController, SceneLocationViewDelegate {
  
  let sceneLocationView = SceneLocationView()
  var didSetUser = false
  var didSetNode = false
  var fetchingBuses = false
  var processingSign = false
  
  var latestCiImage: CIImage?
  var latestPosition: CGPoint?
  var visionRequests = [VNRequest]()
  let dispatchQueueML = DispatchQueue(label: "com.hw.dispatchqueueml")
  let targetIdentifiers = "scoreboard street sign"
  
  var etaNode: EtaNode?
  var busesNodes: [BusNode] = []
  var buses: [Bus] = []
  var busStop: BusStop?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    sceneLocationView.showAxesNode = false
    sceneLocationView.showsStatistics = true
    sceneLocationView.run()
    view.addSubview(sceneLocationView)
    sceneLocationView.locationDelegate = self
    
    guard let selectedModel = try? VNCoreMLModel(for: Inceptionv3().model) else { fatalError("Could not load model") }
    let classificationRequest = VNCoreMLRequest(model: selectedModel, completionHandler: classificationCompleteHandler)
    classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOption.centerCrop // Crop from centre of images and scale to appropriate size.
    visionRequests = [classificationRequest]
    loopCoreMLUpdate()
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(gestureRecognize:)))
    view.addGestureRecognizer(tapGesture)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    sceneLocationView.frame = view.bounds
  }
  
  func loadBuses() {
    guard !fetchingBuses else { return print("busy fetching buses") }
    fetchingBuses = true
    let userLocation = sceneLocationView.currentLocation()
    let url = "https://f8059c21.ngrok.io/journey?lat=\(userLocation!.coordinate.latitude)&lon=\(userLocation!.coordinate.longitude)"
    print("requesting: \(url)")
    Alamofire.request(url).responseJSON { response in
      var buses: [Bus] = []
      guard response.error == nil else { self.fetchingBuses = false; return print("error: \(response.error.debugDescription)") }
      let json = response.result.value as! NSArray
      for itemAny in json {
        let item = itemAny as! NSDictionary
        let pid = item["pid"] as! String
        let bus = Bus(pid: pid, color: BusColors[buses.count], altitude: BusAltitude[buses.count])
        buses.append(bus)
        let etas = item["etas"] as! NSArray
        for etaAny in etas {
          let eta = etaAny as! String
          bus.etas.append(eta)
        }
        let journeys = item["journeys"] as! NSArray
        for journeysStartStopAny in journeys {
          let journeyStartStop = journeysStartStopAny as! NSArray
          for journeyPointAny in journeyStartStop {
            let journeyPoint = journeyPointAny as! NSArray
            let journey = (journeyPoint[0] as! Double, journeyPoint[1] as! Double)
            bus.journeys.append(journey)
          }
        }
      }
      self.fetchingBuses = false
      guard buses.count > 0 else { return print("no buses...") }
      print("found buses: \(buses.count), an eta: \(buses[0].etas)")
      self.buses = buses
      DispatchQueue.main.async { self.renderBuses() }
    }
  }
  
  func renderBuses() {
    let image = UIImage(named: "pin")!
    
    if let etaNode = self.etaNode { sceneLocationView.removeLocationNode(locationNode: etaNode.node) }
    for busNode in self.busesNodes {
      sceneLocationView.removeLocationNode(locationNode: busNode.node)
    }
    
    var locations: [CLLocation] = []
    var busesNodes: [BusNode] = []
    for bus in buses {
      for journey in bus.journeys {
        let coordinate = CLLocationCoordinate2D(latitude: journey.0, longitude: journey.1)
        let location = CLLocation(coordinate: coordinate, altitude: bus.altitude)
        let node = LocationAnnotationNode(location: location, image: UIImage())
        node.scaleRelativeToDistance = true
        let busNode = BusNode(pid: bus.pid, node: node, color: bus.color)
        busesNodes.append(busNode)
        
        if bus.pid == buses[0].pid {
          locations.append(location)
        }
      }
    }
    
    self.busesNodes = busesNodes
    for i in 0..<busesNodes.count {
      let busNode = busesNodes[i]
      sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: busNode.node)
      guard i > 0 && busesNodes[i-1].pid == busNode.pid else { continue }
      drawPath(node1: busesNodes[i-1].node, node2: busNode.node, color: busNode.color)
    }
    
    let userLocation = sceneLocationView.currentLocation()!
    locations.sort() { l1, l2 in l1.distance(from: userLocation) < l2.distance(from: userLocation) }
    if (locations.count > 1) {
      let busItems = buses.map() { bus in PopUpViewItem(name: bus.pid, eta: bus.etas[0], color: bus.color) }
      let busTable = PopupTableView(items: busItems)
      let busImage = busTable.image()
      let c1 = locations[0].coordinate
      let c2 = locations[1].coordinate
      let c = CLLocationCoordinate2D(latitude: (c1.latitude+c2.latitude)/2, longitude: (c1.longitude+c2.longitude)/2)
      let location = CLLocation(coordinate: c, altitude: 0)
      self.etaNode = EtaNode(node: LocationAnnotationNode(location: location, image: busImage))
      sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: etaNode!.node)
    }
  }
  
  @objc func handleTap(gestureRecognize: UITapGestureRecognizer) {
    loadBuses()
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
    let context = CIContext.init(options: nil)
    let cgImage = context.createCGImage(latestCiImage!, from: latestCiImage!.extent)!
    let image = UIImage.init(cgImage: cgImage)
    let imageRepresentation = UIImageJPEGRepresentation(image, 0.95)!
    let imageData = imageRepresentation as NSData
    let base64String = imageData.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
    let coordinate = sceneLocationView.currentLocation()!.coordinate
    let parameters: Parameters = [ "base64": base64String, "lat": coordinate.latitude, "lon": coordinate.longitude ]
    let url = "https://3ab5ea6f.ngrok.io/sign"
    print("requesting: \(url)")
    Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
      print("json:")
      print(response.result.value)
      let json = response.result.value as! NSDictionary
      let stop = json["stop"] as! String
      let busStop = BusStop(stop: stop)
      for journeyAny in json["journies"] as! NSArray {
        let journey = journeyAny as! NSDictionary
        let pid = journey["pid"] as! String
        let busStopBus = BusStopBus(pid: pid)
        busStop.buses.append(busStopBus)
        let etas = journey["ETA"] as! NSArray
        for etaAny in etas {
          let eta = etaAny as! String
          busStopBus.etas.append(eta)
        }
      }
      print("found sign buses: \(busStop.buses.count)")
      self.busStop = busStop
      DispatchQueue.main.async { self.renderBusStop() }
      self.processingSign = false
    }
  }
  
  func renderBusStop() {
    print("TODO: renderBusStop()")
    print(latestPosition)
  }
  
  func drawPath(node1: LocationAnnotationNode, node2: LocationAnnotationNode, color: UIColor) {
    let node = sceneLocationView.sceneNode!
    let cylinder = CylinderLine(parent: node, v1: node1.position, v2: node2.position, radius: 0.1, radSegmentCount: 48, color: color)
    node.addChildNode(cylinder)
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
    if error != nil { return print("Error: " + (error?.localizedDescription)!) }
    guard let observations = request.results else { return print("No results") }
    
    if let observation = observations[0] as? VNClassificationObservation {
      let identifier = observation.identifier
      if targetIdentifiers.contains(identifier) {
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
      loadBuses()
    }
    didSetUser = true
  }
  
  func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
    
  }
  
  func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
    
  }
  
  func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
    if (didSetUser && !didSetNode) {
      loadBuses()
    }
    didSetNode = true
  }
  
  func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
    
  }
  
}
