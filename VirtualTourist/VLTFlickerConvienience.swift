//
//  VLTFlickerConvienience.swift
//  VirtualTourist
//
//  Created by Moath_Othman on 8/27/15.
//  Copyright (c) 2015 Moba. All rights reserved.
//

import Foundation


let SAFE_SEARCH = "1"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"


extension VLTFlickerClient {

    func getphotosOfLocation(latitude: Float,longitude: Float, completionHandler: CommonAPICompletionHandler) {
        getphotosOfLocation(latitude, longitude: longitude, page: 1, completionHandler: completionHandler)
    }

    func getphotosOfLocation(latitude: Float,longitude: Float,page: Int, completionHandler: CommonAPICompletionHandler) {
        let methodArguments = [
            "method": VLTFlickerClient.Methods.search,
            "api_key": VLTFlickerClient.Constants.ApiKey,
            "lat": latitude,
            "lon": longitude,
            "accuracy": 3,
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "page":page,
            "per_page":20,
            "sort": randomSorting(),
        ]

        taskForMethodParameters(methodArguments as! [String : AnyObject], completionHandler: { (response, error) -> Void in
            print("response is \(response)" )

            if let photosDictionary = response!.valueForKey("photos") as? [String:AnyObject] {

                if let pages = photosDictionary["photo"] as? [AnyObject] {
                    completionHandler(response: pages, error: nil)
                } else {
                    println("Cant find key 'pages' in \(photosDictionary)")
                }
            } else {
                println("Cant find key 'photos' in \(response)")
            }
            
        })
    }


    func taskForImageWithURL(url: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {

         let url = NSURL(string: url)!
         println(url)

        let request = NSURLRequest(URL: url)

        let task = session.dataTaskWithRequest(request) {data, response, downloadError in

            if let error = downloadError {
                completionHandler(imageData: nil, error: error)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }

        task.resume()

        return task
    }

    func randomSorting() -> String{
        let sortTypes = ["date-posted-asc",
            "date-posted-desc",
            "date-taken-asc",
            "date-taken-desc",
            "interestingness-desc",
            "interestingness-asc",
            "relevance",
        ]
        let randomPhotoIndex = Int(arc4random_uniform(UInt32(sortTypes.count)))
        return sortTypes[randomPhotoIndex]
    }

}