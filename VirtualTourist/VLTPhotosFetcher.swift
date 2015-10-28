//
//  VLTPhotosFetcher.swift
//  VirtualTourist
//
//  Created by Moath_Othman on 9/15/15.
//  Copyright (c) 2015 Moba. All rights reserved.
//

import UIKit
import CoreData
let FETCHING_PHOTOS_FOR_PIN = "FETCHING FINISHED"
class VLTPhotosFetcher: NSObject {
    class func fetchPhotosForPin(pin: Pin, context: NSManagedObjectContext) {
        
        var pages = pin.totalPages.integerValue
        if pages != 0 {
            pages = Int(arc4random_uniform(UInt32(pages)))
        } else {
            pages = 1
        }
        VLTFlickerClient.sharedInstance().getphotosOfLocation(pin.lat.floatValue, longitude: pin.lon.floatValue,page: pages) { (response, error) -> Void in
            // Handle the error case
            var notificationObject = [String: AnyObject]()
            if let error = error {
                print("Error searching for actors: \(error.localizedDescription)")
                 notificationObject = ["error": 1,"finished":1]
                return
            }
            if let pages = response?.valueForKey("pages") as? Int {
                pin.totalPages = pages
            }
            if let photos = response?.valueForKey("photos")  as? [[String : AnyObject]] {
                pin.photos = NSSet(array: photos.map() {
                    Photo(dictionary: $0, context: context)
                    })
                CoreDataStackManager.sharedInstance().saveContext()
                if photos.count == 0 {
                    notificationObject = ["error": 1,"finished":1]
                } else {
                notificationObject = ["error": 0,"finished":1]
                }
            } else {
                notificationObject = ["error": 1,"finished":1]
            }
            pin.isPhotosDownloaded = true
            NSNotificationCenter.defaultCenter().postNotificationName(FETCHING_PHOTOS_FOR_PIN, object: notificationObject)

        }

    }

    func callAPIAndSaveToDB() {
            }

}
