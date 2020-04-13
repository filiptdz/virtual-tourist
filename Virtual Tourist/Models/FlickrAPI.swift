//
//  FlickrAPI.swift
//  Virtual Tourist
//
//  Created by Filipe Degrazia on 01/04/20.
//  Copyright © 2020 FilipeDegrazia. All rights reserved.
//

import Foundation
import MapKit

class FlickrAPI {
  static let apiKey = "8d39da98ddfccd08ed29a03bab37a89b"
  
  class func getPhotosAPIURL(from location: CLLocationCoordinate2D, pageCount: Int) -> URL {
    let latDelta = 0.05
    let longDelta = 0.05
    let latMax = location.latitude + latDelta
    let latMin = location.latitude - latDelta
    let longMax = location.longitude + longDelta
    let longMin = location.longitude - longDelta
    let maxPage = pageCount > 16 ? 16 : pageCount
    let page = pageCount == 0 ? 1 : Int.random(in: 1...maxPage)
    return URL(string: "https://api.flickr.com/services/rest?api_key=\(FlickrAPI.apiKey)&method=flickr.photos.search&bbox=\(longMin),\(latMin),\(longMax),\(latMax)&format=json&page=\(page)")!
  }
  
  class func getPhotoURL(from photo: PhotoResponse) -> URL {
    return URL(string: "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret)_q.jpg")!
  }
  
  class func getPhotos(from location: CLLocationCoordinate2D, pageCount: Int, completion: @escaping (PhotoList?, Error?) -> Void) {
    let task = URLSession.shared.dataTask(with: FlickrAPI.getPhotosAPIURL(from: location, pageCount: pageCount)) { (data, response, error) in
      guard let data = data else {
        DispatchQueue.main.async {
          completion(nil, error)
        }
        return
      }
      do {
        let objectData = try JSONDecoder().decode(PhotosResponse.self, from: data.subdata(in: 14..<(data.count - 1)))
        var urlList: [URL] = []
        for photo in objectData.photos.photo {
          urlList.append(getPhotoURL(from: photo))
        }
        DispatchQueue.main.async {
          completion(PhotoList(pages: objectData.photos.pages, photos: urlList), nil)
        }
      } catch {
        DispatchQueue.main.async {
          completion(nil, error)
        }
      }
    }
    task.resume()
  }
  
  class func loadCellImage(object: Photo, dataController: DataController) {
    let photoID = object.objectID
    dataController.performBackgroundTask { context in
      let photo = context.object(with: photoID) as! Photo
      if let imageData = try? Data(contentsOf: photo.url!) {
        photo.data = imageData
        try? context.save()
      }
    }
  }
}
