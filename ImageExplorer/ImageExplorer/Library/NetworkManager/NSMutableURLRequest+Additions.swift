//
//  NSMutableURLRequest+Additions.swift
//
//  Created by Rishi Kumar on 08/08/18.
//  Copyright © 2018 Rishi Kumar. All rights reserved.
//

import Foundation

/**
 * HTTP Methods
 */
enum HTTPRequestMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

extension NSMutableURLRequest {

    /**
     Default url request timeout

     - returns: Default request timeout
     */
    class func requestTimeoutInterval() -> Double {
        return 20.0
    }

    /**
     Creates a NSMutableURLRequest object

     - parameter URL:    URL
     - parameter method: HTTPMethod
     - parameter body:   HTTPBody for creating mutable url request.

     - returns: NSMutableURLRequest object.
     */
    class func requestWithURL(_ URL: Foundation.URL, method: HTTPRequestMethod = .POST, body: String) -> NSMutableURLRequest {

        // LogManager.logDebug("URL = \(URL.absoluteString) \nparams = \(body)")

        // let mutableURLRequest: NSMutableURLRequest = NSMutableURLRequest(URL: URL, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: NSMutableURLRequest.requestTimeoutInterval())
        let mutableURLRequest: NSMutableURLRequest = NSMutableURLRequest(url: URL)
        mutableURLRequest.timeoutInterval = NSMutableURLRequest.requestTimeoutInterval()

        // Set the request's content type to application/x-www-form-urlencoded
        // In body data for the 'application/x-www-form-urlencoded' content type, form fields are separated by an ampersand. Note the absence of a leading ampersand.
        // eg: @"name=Arvind+Singh&address=123+Main+St"
        mutableURLRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Designate the request a POST request and specify its body data
        mutableURLRequest.httpMethod = method.rawValue

        if method != .GET {
            mutableURLRequest.httpBody = body.data(using: String.Encoding.utf8)
        }

        return mutableURLRequest
    }

    /**
     Creates a NSMutableURLRequest object

     - parameter URL:            URL
     - parameter method:         HTTPMethod
     - parameter jsonDictionary: jsonDictionary for creating mutable url request.
     * @return NSMutableURLRequest object.

     - returns: NSMutableURLRequest object.
     */
    class func requestWithURL(_ URL: Foundation.URL, method: HTTPRequestMethod = .POST, jsonDictionary: NSDictionary?) -> NSMutableURLRequest {

        // LogManager.logDebug("URL = \(URL.absoluteString) \nparams = \(jsonDictionary)")

        // let mutableURLRequest: NSMutableURLRequest = NSMutableURLRequest(URL: URL, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: NSMutableURLRequest.requestTimeoutInterval())
        let mutableURLRequest: NSMutableURLRequest = NSMutableURLRequest(url: URL)
        mutableURLRequest.timeoutInterval = NSMutableURLRequest.requestTimeoutInterval()

        // Set the request's content type to application/json
        mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
       // mutableURLRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        //mutableURLRequest.setValue(Constants.interComeKey, forHTTPHeaderField: "Authorization")

        // Designate the request a POST request and specify its body data
        mutableURLRequest.httpMethod = method.rawValue

        if method != .GET {
            if let obj = jsonDictionary {

                do {
                    if let data: Data? = try JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted) {
                        mutableURLRequest.httpBody = data // Okay, the `json` is here, let's get the value for 'success' out of it
                        
                        
                    } else {
                        print("JSON serialization failed.\(obj.description)") // No error thrown, but not NSData
                    }
                } catch let parseError {
                    print("Error could not parse JSON.\n \(parseError)") // Log the error thrown by `JSONObjectWithData`
                }
            }
        }
        return mutableURLRequest
    }

    /**
     Set multipart form data

     - parameter dataFields: A dictionary contains parameters for fields in key value pair
     {"field1" : "value1", "field2" : "value2"}
     e.g userID="6", name="yourname" then
     dataFields = {"userID" : "6", "name" : "yourname"}

     - parameter fileFields: An array of dictionary where each dictionary contians parameters for each photo uploaded in the format {"key" : "YourKeyOfTheParameterPassedForImage", "fileName" : "YourFileNameParameterPassedForImage", "contentType" : "YourContentTypeOfImage", "data" : "YourImageData"} e.g. web service parameter is pic="filename.jpg" [{"key" : "pic1", "filename" : "MyFileName1.jpg", "contentType" : "image/jpeg", "value" : "ImageData of type NSData"}, {"key" : "pic2", "filename" : "MyFileName2.png", "contentType" : "image/png", "value" : "Image data of NSData"}]
     */
    func setMultipartFormData(_ dataFields: [String: AnyObject]?, fileFields: [[String: AnyObject]]?) {

        // Add http method
        httpMethod = HTTPRequestMethod.POST.rawValue

        let stringEncoding: String.Encoding = String.Encoding.utf8
        // let stringBoundary: NSString = NSString(format: "0xKhTmLbOuNdArY-%@", NSUUID().UUIDString)
        let stringBoundary: NSString = "---011000010111000001101001"
        let endBoundryData = String(format: "\r\n--%@\r\n", stringBoundary).data(using: stringEncoding)!

        // Add default httpheader fields ***********
        setValue(String(format: "multipart/form-data; boundary=%@", stringBoundary), forHTTPHeaderField: "Content-Type")

        let body = NSMutableData()
        body.append(String(format: "--%@\r\n", stringBoundary).data(using: stringEncoding)!)

        if let _ = dataFields {
            var index: Int = 0
            for key in dataFields!.keys {
                let value = dataFields![key]

                body.append(String(format: "Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key).data(using: stringEncoding)!)
                body.append(String(format: "%@", value! as! CVarArg).data(using: stringEncoding)!)
                index += 1

                // Only add the boundary if this is not the last item in the post body
                if index != (dataFields?.count)! || (fileFields?.count)! > 0 {
                    body.append(endBoundryData)
                }
            }
        }

        if let _ = fileFields {
            var index: Int = 0
            for fileInfo in fileFields! {
                if let key = fileInfo["key"], let value = fileInfo["value"], let fileName = fileInfo["fileName"], let contentType = fileInfo["contentType"] {

                    body.append(String(format: "Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key as! String, fileName as! String).data(using: stringEncoding)!)
                    body.append(String(format: "Content-Type: %@\r\n\r\n", contentType as! String).data(using: stringEncoding)!)
                    body.append(value as! Data)
                    index += 1

                    // Only add the boundary if this is not the last item in the post body
                    if index != fileFields?.count {
                        body.append(endBoundryData)
                    }
                }
            }
        }

        body.append(String(format: "\r\n--%@--\r\n", stringBoundary).data(using: stringEncoding)!)
        httpBody = body as Data
    }
}
