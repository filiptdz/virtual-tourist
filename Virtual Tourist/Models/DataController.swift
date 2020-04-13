//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Filipe Degrazia on 31/03/20.
//  Copyright © 2020 FilipeDegrazia. All rights reserved.
//

import Foundation
import CoreData

class DataController {
  let persistentContainer: NSPersistentContainer
  
  var viewContext: NSManagedObjectContext {
    return persistentContainer.viewContext
  }
  
  let backgroundContext: NSManagedObjectContext!
  
  init(modelName: String) {
    persistentContainer = NSPersistentContainer(name: modelName)
    
    backgroundContext = persistentContainer.newBackgroundContext()
  }
  
  func configureContexts() {
    viewContext.automaticallyMergesChangesFromParent = true
    backgroundContext.automaticallyMergesChangesFromParent = true
    
    backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
  }
  
  func load() {
    persistentContainer.loadPersistentStores { (storeDescription, error) in
      guard error == nil else {
        fatalError(error!.localizedDescription)
      }
      self.configureContexts()
    }
  }
  
  func performBackgroundTask(block: @escaping (NSManagedObjectContext) -> Void) {
    persistentContainer.performBackgroundTask(block)
  }
}
