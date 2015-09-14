//
//  Photo.swift
//  VirtualTourist
//
//  Created by Moath_Othman on 8/31/15.
//  Copyright (c) 2015 Moba. All rights reserved.
//

import Foundation
import CoreData
import UIKit
@objc(Photo)

class Photo: NSManagedObject {

    struct Keys {
        static let Title = "title"
        static let ImagePath = "url_m"
        static let Pins = "pin"
        static let ID = "id"
    }

    @NSManaged var title: String
    @NSManaged var url_m: String
    @NSManaged var id: String
    @NSManaged var pin: Pin

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {

        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!

        super.init(entity: entity,insertIntoManagedObjectContext: context)

        title = dictionary[Keys.Title] as! String
        id = dictionary[Keys.ID] as! String
        url_m = (dictionary[Keys.ImagePath] as? String)!
    }
    var image: UIImage? {
        get {
            return ImageCache.sharedInstance().imageWithIdentifier(url_m.lastPathComponent)
        }
        set {
            ImageCache.sharedInstance().storeImage(newValue, withIdentifier: url_m.lastPathComponent)
        }
    }

}
