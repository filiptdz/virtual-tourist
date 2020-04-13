//
//  Pin+Extensions.swift
//  Virtual Tourist
//
//  Created by Filipe Degrazia on 01/04/20.
//  Copyright © 2020 FilipeDegrazia. All rights reserved.
//

import MapKit

extension Pin {
  var coordinates: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
  }
}
