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


    /* Function makes first request to get a random page, then it makes a request to get an image with the random page */
    func getImageFromFlickrBySearch(searchString text:String) {

        let methodArguments = [
            "method": VLTFlickerClient.Methods.search,
            "api_key": VLTFlickerClient.Constants.ApiKey,
            "text": text,
            "safe_search": SAFE_SEARCH,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK,
            "per_page": 20,
        ]


        let session = NSURLSession.sharedSession()
        let urlString = VLTFlickerClient.Constants.BaseURL + VLTFlickerClient.escapedParameters(methodArguments as! [String : AnyObject])
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)

        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
            } else {

                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary

                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {

                    if let totalPages = photosDictionary["pages"] as? Int {

                        /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
                        let pageLimit = min(totalPages, 40)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        self.getImageFromFlickrBySearchWithPage(methodArguments as! [String : AnyObject], pageNumber: randomPage)

                    } else {
                        println("Cant find key 'pages' in \(photosDictionary)")
                    }
                } else {
                    println("Cant find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
    }


    func getImageFromFlickrBySearchWithPage(methodArguments: [String : AnyObject], pageNumber: Int) {

        /* Add the page to the method's arguments */
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber

        let session = NSURLSession.sharedSession()
        let urlString = VLTFlickerClient.Constants.BaseURL + VLTFlickerClient.escapedParameters(withPageDictionary)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)

        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
            } else {
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary

                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {

                    var totalPhotosVal = 0
                    if let totalPhotos = photosDictionary["total"] as? String {
                        totalPhotosVal = (totalPhotos as NSString).integerValue
                    }

                    if totalPhotosVal > 0 {
                        if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {

                            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                            let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]

                            let photoTitle = photoDictionary["title"] as? String
                            let imageUrlString = photoDictionary["url_m"] as? String
                            let imageURL = NSURL(string: imageUrlString!)

                            if let imageData = NSData(contentsOfURL: imageURL!) {
                                //                                dispatch_async(dispatch_get_main_queue(), {
                                //                                    self.defaultLabel.alpha = 0.0
                                //                                    self.photoImageView.image = UIImage(data: imageData)
                                //
                                //                                    if methodArguments["bbox"] != nil {
                                //                                        self.photoTitleLabel.text = "\(self.getLatLonString()) \(photoTitle!)"
                                //                                    } else {
                                //                                        self.photoTitleLabel.text = "\(photoTitle!)"
                                //                                    }
                                //
                                //                                })
                            } else {
                                println("Image does not exist at \(imageURL)")
                            }
                        } else {
                            println("Cant find key 'photo' in \(photosDictionary)")
                        }
                    } else {
                        //                        dispatch_async(dispatch_get_main_queue(), {
                        //                            self.photoTitleLabel.text = "No Photos Found. Search Again."
                        //                            self.defaultLabel.alpha = 1.0
                        //                            self.photoImageView.image = nil
                        //                        })
                    }
                } else {
                    println("Cant find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
    }



}