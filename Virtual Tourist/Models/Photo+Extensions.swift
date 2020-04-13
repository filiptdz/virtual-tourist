//
//  Photo+Extensions.swift
//  Virtual Tourist
//
//  Created by Filipe Degrazia on 01/04/20.
//  Copyright © 2020 FilipeDegrazia. All rights reserved.
//

import Foundation

extension Photo {
  public override func awakeFromInsert() {
    super.awakeFromInsert()
    creationDate = Date()
  }
}
