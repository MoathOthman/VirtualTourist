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
    @NSManaged var isPinMoved: NSNumber

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {

        let entity =  NSEntityDescription.entity(forEntityName: "Pin", in: context)!

        super.init(entity: entity,insertInto: context)

        lat =  dictionary[Keys_PIN.Lat] as! NSNumber
        lon =  dictionary[Keys_PIN.Lon] as! NSNumber
    }



    
}
