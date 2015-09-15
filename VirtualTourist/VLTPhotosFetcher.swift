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
        VLTFlickerClient.sharedInstance().getphotosOfLocation(pin.lat.floatValue, longitude: pin.lon.floatValue) { (response, error) -> Void in
            // Handle the error case
            var notificationObject = [String: AnyObject]()
            if let error = error {
                println("Error searching for actors: \(error.localizedDescription)")
                 notificationObject = ["error": 1,"finished":1]
                return
            }
            if let photos = response  as? [[String : AnyObject]] {
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
