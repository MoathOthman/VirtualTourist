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

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {

        let entity =  NSEntityDescription.entity(forEntityName: "Photo", in: context)!
        super.init(entity: entity,insertInto: context)
        title = dictionary[Keys.Title] as! String
        id = dictionary[Keys.ID] as! String
        url_m = (dictionary[Keys.ImagePath] as? String)!
    }
    var image: UIImage? {
        get {
            return ImageCache.sharedInstance().imageWithIdentifier((url_m as NSString).lastPathComponent)
        }
        set {
            ImageCache.sharedInstance().storeImage(newValue, withIdentifier: (url_m as NSString).lastPathComponent)
        }
    }
    override func prepareForDeletion() {
        let path = ImageCache.sharedInstance().pathForIdentifier((self.url_m as NSString).lastPathComponent)
        if FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch _ {
            }
        }
    }
}
