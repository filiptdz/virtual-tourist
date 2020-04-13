//
//  PhotoViewController.swift
//  Virtual Tourist
//
//  Created by Filipe Degrazia on 31/03/20.
//  Copyright © 2020 FilipeDegrazia. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var collectionView: UICollectionView!
  
  var pin: Pin!
  var dataController: DataController!
  var fetchedResultsController: NSFetchedResultsController<Photo>!

  override func viewDidLoad() {
    super.viewDidLoad()
    
    collectionView.delegate = self
    collectionView.dataSource = self
    
    setupMapView()
    getPhotos()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    fetchedResultsController = nil
  }

  func setupMapView() {
    let region = MKCoordinateRegion(center: pin.coordinates, span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 10))
    mapView.setRegion(region, animated: true)
    let pinAnnotation = MKPointAnnotation()
    pinAnnotation.coordinate = pin.coordinates
    mapView.addAnnotation(pinAnnotation)
    mapView.isUserInteractionEnabled = false
    mapView.delegate = self
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

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return fetchedResultsController.fetchedObjects?.count ?? 0
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
    if fetchedResultsController.object(at: indexPath).data == nil {
      cell.imageView.image = UIImage(named: "placeholder")
      FlickrAPI.loadCellImage(object: fetchedResultsController.object(at: indexPath), dataController: dataController)
    } else {
      cell.imageView.image = UIImage(data: fetchedResultsController.object(at: indexPath).data!)
    }
    return cell
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = (collectionView.frame.width - 10 * 2) / 3
    return CGSize(width: width, height: width)
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let itemToDelete = fetchedResultsController.object(at: indexPath)
    dataController.viewContext.delete(itemToDelete)
    try? dataController.viewContext.save()
  }
  
  func getPhotos() {
    let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
    let predicate = NSPredicate(format: "pin == %@", pin)
    fetchRequest.predicate = predicate
    let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
    fetchedResultsController.delegate = self
    
    do {
      try fetchedResultsController.performFetch()
      if fetchedResultsController.fetchedObjects?.count == 0 {
        remotePhotosRequest()
      }
    } catch {
      fatalError(error.localizedDescription)
    }
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch type {
    case .insert:
      collectionView.insertItems(at: [newIndexPath!])
      break
    case .update:
      collectionView.reloadItems(at: [indexPath!])
      break
    case .delete:
      collectionView.deleteItems(at: [indexPath!])
      break
    default:
      break
    }
  }
  
  func remotePhotosRequest() {
    FlickrAPI.getPhotos(from: pin.coordinates, pageCount: Int(pin.pages)) { (photoList, error) in
      for photo in self.fetchedResultsController.fetchedObjects! {
        self.pin.removeFromPhotos(photo)
        try? self.dataController.viewContext.save()
      }
      
      guard let photoList = photoList else {
        let alert = UIAlertController(title: "Error", message: "Could not load photos. Please check your connection and try again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
        return
      }
      
      self.pin.pages = Int16(photoList.pages)
      try? self.dataController.viewContext.save()
      
      let pinID = self.pin.objectID
      self.dataController.performBackgroundTask { context in
        let innerPin = context.object(with: pinID) as! Pin
        for url in photoList.photos {
          let photo = Photo(context: context)
          photo.url = url
          photo.pin = innerPin
          innerPin.addToPhotos(photo)
        }
        try? context.save()
      }
    }
  }

  @IBAction func newCollectionPressed(_ sender: Any) {
    remotePhotosRequest()
  }
}
