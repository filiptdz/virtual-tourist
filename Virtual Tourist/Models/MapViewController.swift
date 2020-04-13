//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Filipe Degrazia on 26/03/20.
//  Copyright © 2020 FilipeDegrazia. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MKPinPointAnnotation: MKPointAnnotation {
  var pin: Pin?
}

class MapViewController: UIViewController, MKMapViewDelegate {
  @IBOutlet weak var mapView: MKMapView!
  
  var dataController: DataController!

  override func viewDidLoad() {
    super.viewDidLoad()
    mapView.delegate = self
    loadLocation()
    loadPins()
    
    let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressMap(gestureRecognizer:)))
    mapView.addGestureRecognizer(longPressGestureRecognizer)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: animated)
  }

  func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
    saveLocation(region: mapView.region)
  }
  
  func getFirstLocation(context: NSManagedObjectContext) -> MapLocation? {
    let fetchRequest: NSFetchRequest<MapLocation> = MapLocation.fetchRequest()
    if let locations = try? context.fetch(fetchRequest), locations.indices.contains(0) {
      return locations[0]
    }
    return nil
  }
  
  func saveLocation(region: MKCoordinateRegion) {
    dataController.performBackgroundTask { context in
      let location = self.getFirstLocation(context: context) ?? MapLocation(context: context)
      location.latitude = region.center.latitude
      location.longitude = region.center.longitude
      location.latitudeDelta = region.span.latitudeDelta
      location.longitudeDelta = region.span.longitudeDelta
      try? context.save()
    }
  }
  
  func loadLocation() {
    if let location = getFirstLocation(context: dataController.viewContext) {
      let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
      let span = MKCoordinateSpan(latitudeDelta: location.latitudeDelta, longitudeDelta: location.longitudeDelta)
      mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
    }
  }
  
  @IBAction func onLongPressMap(gestureRecognizer: UIGestureRecognizer) {
    let touchLocation = gestureRecognizer.location(in: mapView)
    let coordinates = mapView.convert(touchLocation, toCoordinateFrom: mapView)
    let pin = savePin(coordinates: coordinates)
    let newAnnotation = MKPinPointAnnotation()
    newAnnotation.coordinate = coordinates
    newAnnotation.pin = pin
    mapView.addAnnotation(newAnnotation)
  }
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard annotation is MKPointAnnotation else { return nil }

    let identifier = "Annotation"
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

    if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView!.canShowCallout = true
    } else {
        annotationView!.annotation = annotation
    }

    return annotationView
  }
  
  func savePin(coordinates: CLLocationCoordinate2D) -> Pin {
    let pin = Pin(context: dataController.viewContext)
    pin.latitude = coordinates.latitude
    pin.longitude = coordinates.longitude
    try? dataController.viewContext.save()
    return pin
  }
  
  func loadPins() {
    let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
    if let pinsData = try? dataController.viewContext.fetch(fetchRequest) {
      for pinData in pinsData {
        let annotation = MKPinPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pinData.latitude, longitude: pinData.longitude)
        annotation.pin = pinData
        mapView.addAnnotation(annotation)
      }
    }
  }
  
  func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    let photosController = storyboard?.instantiateViewController(withIdentifier: "PhotoViewController") as! PhotoViewController
    let annotation = view.annotation! as! MKPinPointAnnotation
    photosController.pin = annotation.pin
    photosController.dataController = dataController
    navigationController?.pushViewController(photosController, animated: true)
  }
}

