//
//  Map.swift
//  VirtualTourist
//
//  Created by Moath_Othman on 9/10/15.
//  Copyright (c) 2015 Moba. All rights reserved.
//

import Foundation
import CoreData
@objc(Map)

class Map: NSManagedObject {


    struct Keys {
        static let centerX = "centerX"
        static let centerY = "centerY"
        static let lonDistance = "lonDistance"
        static let latDistance = "latDistance"
    }

    
    @NSManaged var lonDistance: NSNumber
    @NSManaged var latDistance: NSNumber
    @NSManaged var centerX: NSNumber
    @NSManaged var centerY: NSNumber

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

 
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Map", inManagedObjectContext: context)!
        super.init(entity: entity,insertIntoManagedObjectContext: context)
    
        centerX = (dictionary[Keys.centerX] as? Float)!
        centerY = (dictionary[Keys.centerY] as? Float)!
        lonDistance = (dictionary[Keys.lonDistance] as? Float)!
        latDistance = (dictionary[Keys.latDistance] as? Float)!

    }

    class func fetchMapObject(context: NSManagedObjectContext) -> Map? {
        let error: NSErrorPointer = nil
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Map")
        // Execute the Fetch Request
        let results: [AnyObject]?
        do {
            results = try context.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error.memory = error1
            results = nil
        }
        // Check for Errors
        if error != nil {
            print("Error in fectchAllActors(): \(error)")
        }
        // Return the results, cast to an array of Person objects
        return results?.last as? Map
    }
    
}
