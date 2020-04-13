//
//  PhotoResponse.swift
//  Virtual Tourist
//
//  Created by Filipe Degrazia on 01/04/20.
//  Copyright © 2020 FilipeDegrazia. All rights reserved.
//

import Foundation

struct PhotosResponse: Codable {
  let photos: InnerPhotosResponse
}

struct InnerPhotosResponse: Codable {
  let photo: [PhotoResponse]
  let pages: Int
}

struct PhotoResponse: Codable {
  let id: String
  let secret: String
  let server: String
  let farm: Int
}
