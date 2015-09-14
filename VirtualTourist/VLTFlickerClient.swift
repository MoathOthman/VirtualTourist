//
//  VLTFlickerClient.swift
//  VirtualTourist
//
//  Created by Moath_Othman on 8/27/15.
//  Copyright (c) 2015 Moba. All rights reserved.
//

import UIKit

class VLTFlickerClient: NSObject {
    typealias CommonAPICompletionHandler =  (response: AnyObject?,error : NSError?) -> Void

    /* Shared session */
    var session: NSURLSession

    /* Configuration object */

    /* Authentication state */
    var sessionID : String? = nil
    var userID : String? = nil
    var isLoggedIn: Bool {
        get{
            return NSUserDefaults.standardUserDefaults().boolForKey("isLoggedIn");
        }
        set {
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: "isLoggedIn")
        }
    }
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }




   

    func taskForMethodParameters(parameters: [String : AnyObject], completionHandler: CommonAPICompletionHandler) -> NSURLSessionDataTask {

        /* 1. Set the parameters */
        var mutableParameters = parameters

        /* 2/3. Build the URL and configure the request */
        let urlString = Constants.BaseURL + VLTFlickerClient.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)

        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                /* 5/6. Parse the data and use the data (happens in completion handler) */
                if let error = downloadError {
                    let newError = VLTFlickerClient.errorForData(data, response: response, error: error)
                    completionHandler(response: nil, error: downloadError)
                } else {
                    let newData = data

                    VLTFlickerClient.parseJSONWithCompletionHandler(newData, completionHandler: completionHandler)
                }
            })

        }

        /* 7. Start the request */
        task.resume()
        
        return task
    }


    // MARK: - GET

    func taskForGETMethod(method: String, parameters: [String : AnyObject], completionHandler: CommonAPICompletionHandler) -> NSURLSessionDataTask {

        /* 1. Set the parameters */
        var mutableParameters = parameters

        /* 2/3. Build the URL and configure the request */
        let urlString = Constants.BaseURLSecure + method + VLTFlickerClient.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)

        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                /* 5/6. Parse the data and use the data (happens in completion handler) */
                if let error = downloadError {
                    let newError = VLTFlickerClient.errorForData(data, response: response, error: error)
                    completionHandler(response: nil, error: downloadError)
                } else {
                    let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5)) /* subset response data! */

                    VLTFlickerClient.parseJSONWithCompletionHandler(newData, completionHandler: completionHandler)
                }
            })

        }

        /* 7. Start the request */
        task.resume()

        return task
    }


    // MARK: - POST

    func taskForPOSTMethod(method: String, parameters: [String : AnyObject], jsonBody: [String:AnyObject], completionHandler: CommonAPICompletionHandler) -> NSURLSessionDataTask {

        /* 1. Set the parameters */
        var mutableParameters = parameters
        mutableParameters[ParameterKeys.ApiKey] = Constants.ApiKey

        /* 2/3. Build the URL and configure the request */
        let urlString = Constants.BaseURLSecure + method + VLTFlickerClient.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        var jsonifyError: NSError? = nil
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(jsonBody, options: nil, error: &jsonifyError)

        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                /* 5/6. Parse the data and use the data (happens in completion handler) */
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let error = downloadError {
                        let newError = VLTFlickerClient.errorForData(data, response: response, error: error)
                        completionHandler(response: nil, error: downloadError)
                    } else {
                        let newData = data.subdataWithRange(NSMakeRange(5, data.length - 5)) /* subset response data! */
                        VLTFlickerClient.parseJSONWithCompletionHandler(newData, completionHandler: completionHandler)
                    }
                })

            })

        }

        /* 7. Start the request */
        task.resume()

        return task
    }

    // MARK: - Helpers

    /* Helper: Substitute the key for the value that is contained within the method name */
    class func subtituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }

    /* Helper: Given a response with error, see if a status_message is returned, otherwise return the previous error */
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {

        if let parsedResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String : AnyObject] {

            if let errorMessage = parsedResult[VLTFlickerClient.JSONResponseKeys.StatusMessage] as? String {

                let userInfo = [NSLocalizedDescriptionKey : errorMessage]

                return NSError(domain: "TMDB Error", code: 1, userInfo: userInfo)
            }
        }

        return error
    }

    /* Helper: Given raw JSON, return a usable Foundation object */
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CommonAPICompletionHandler) {

        var parsingError: NSError? = nil

        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)

        if let error = parsingError {
            completionHandler(response: nil, error: error)
        } else {
            completionHandler(response: parsedResult, error: nil)
        }
    }

    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {

        var urlVars = [String]()

        for (key, value) in parameters {

            /* Make sure that it is a string value */
            let stringValue = "\(value)"

            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> VLTFlickerClient {
        
        struct Singleton {
            static var sharedInstance = VLTFlickerClient()
        }
        
        return Singleton.sharedInstance
    }

}





extension VLTFlickerClient {


    // MARK: - Constants
    struct Constants {
        // MARK: API Key // flicker api key
        static let ApiKey : String = "6eba9ae473d2a2084ea0cd86a03d9cb8"
        // MARK: URLs
        static let BaseURL : String = "https://api.flickr.com/services/rest/"
        static let BaseURLSecure : String = "https://www.udacity.com/api/"
        static let AuthorizationURL : String = "https://www.themoviedb.org/authenticate/"
        static let signUpWebURL: NSURL?  = NSURL(string: "https://www.google.com/url?q=https%3A%2F%2Fwww.udacity.com%2Faccount%2Fauth%23!%2Fsignin&sa=D&sntz=1&usg=AFQjCNERmggdSkRb9MFkqAW_5FgChiCxAQ")
    }

    // MARK: - Methods
    struct Methods {
        // MARK: Session
        static let session = "session"
        // MARK: users
        static let users = "users"
        static let search = "flickr.photos.search"
        static let photosOfLocations = "flickr.photos.geo.photosForLocation"


    }

    // MARK: - URL Keys
    struct URLKeys {

        static let UserID = "id"

    }

    // MARK: - Parameter Keys
    struct ParameterKeys {

        static let ApiKey = "api_key"
        static let SessionID = "session_id"
        static let RequestToken = "request_token"
        static let Query = "query"

    }

    // MARK: - JSON Body Keys
    struct JSONBodyKeys {
        static let UserName = "username"
        static let Password = "password"
        static let facebook_mobile = "facebook_mobile"
        static let access_token = "access_token"
    }

    // MARK: - JSON Response Keys
    struct JSONResponseKeys {

        //MARK: Login
        static let account = "account"
        static let registered = "registered"
        static let key = "key"
        static let session = "session"
        static let id = "id"
        static let expiration = "expiration"
        static let error = "error"
        static let status = "status"
        // MARK: General
        static let StatusMessage = "status_message"
        // User
        static let user = "user"
        static let first_name = "first_name"
        static let last_name = "last_name"
        static let email = "email"
    }
    
    
}


