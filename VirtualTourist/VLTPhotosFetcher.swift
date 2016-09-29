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
    class func fetchPhotosForPin(_ pin: Pin, context: NSManagedObjectContext) {
        
        var pages = pin.totalPages.intValue
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
                 notificationObject = ["error": 1 as AnyObject,"finished":1 as AnyObject]
                return
            }
            if let pages = response?.value(forKey: "pages") as? Int {
                pin.totalPages = NSNumber(value: pages)
            }
            if let photos = response?.value(forKey: "photos")  as? [[String : AnyObject]] {
                pin.photos = NSSet(array: photos.map() {
                    Photo(dictionary: $0, context: context)
                    })
                CoreDataStackManager.sharedInstance().saveContext()
                if photos.count == 0 {
                    notificationObject = ["error": 1 as AnyObject,"finished":1 as AnyObject]
                } else {
                    notificationObject = ["error": 0 as AnyObject,"finished":1 as AnyObject]
                }
            } else {
                    notificationObject = ["error": 1 as AnyObject,"finished":1 as AnyObject]
            }
            pin.isPhotosDownloaded = true
            NotificationCenter.default.post(name: Notification.Name(rawValue: FETCHING_PHOTOS_FOR_PIN), object: notificationObject)

        }

    }

    func callAPIAndSaveToDB() {
            }

}
