//
//  Pin.swift
//  VirtualTourist
//
//  Created by Moath_Othman on 9/2/15.
//  Copyright (c) 2015 Moba. All rights reserved.
//

import Foundation
import CoreData
@objc(Pin)
class Pin: NSManagedObject {


    struct Keys_PIN {
        static let Lat = "lat"
        static let Lon = "lon"
    }



    @NSManaged var lat: NSNumber
    @NSManaged var lon: NSNumber
    @NSManaged var photos: NSSet
    @NSManaged var isPhotosDownloaded: NSNumber
    @NSManaged var totalPages: NSNumber

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {

        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!

        super.init(entity: entity,insertIntoManagedObjectContext: context)

        lat = dictionary[Keys_PIN.Lat] as! Float
        lon = dictionary[Keys_PIN.Lon] as! Float
    }



    
}
