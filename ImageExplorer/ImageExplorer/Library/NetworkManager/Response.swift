//
//  ApiResponse.swift
//
//  Created by Rishi Kumar on 08/08/18.
//  Copyright © 2018 Rishi Kumar. All rights reserved.
//

import UIKit

let kHTTPRequestDomain = "com.httprequest"
let kResponseStatus = "success"
let kResponseCode = "responseCode"
let kResponseMessage = "message"
let kStatusCode = "status"
let kStatusMessage = "Forbidden"
let kCode = "code"


/// ApiResponseInfo used to store URL response.
class Response: NSObject {

    // The data received during the request.
    var responseData: Data?

    // The error received during the request.
    var responseError: NSError?

    // The dictionary received after parsing the received data.
    var resultDictionary: NSDictionary?

    var resultArray: NSArray?

    /**
     The response status after parsing the received data.

     - returns: true if success code return
     */
    var success: Bool {
        if let resultDictionary = self.resultDictionary {
            
            if let statusCode = resultDictionary[kCode] as? Int {
                if statusCode  == 400 {
                    return false
                }
                else if statusCode  == 200 {
                    return true
                }
                else {
                    return false
                }
            }
           else if let status = resultDictionary[kResponseStatus] {
                return (status as AnyObject).boolValue
                //                    return Bool(status.doubleValue)
            } else if let message = resultDictionary[kResponseMessage] as? String {
                if message == kStatusMessage {
                    return false
                } else {
                    return true
                }
            } else {
                return true
            }
        } else if let _ = self.resultArray {
            return true
        }

        return false
        // return true
    }

    /**
     The response string from the received data.

     - returns: Returns the response as a string
     */
    var text: String? {

        guard let _ = responseData else {
            return nil
        }
        return String(data: responseData!, encoding: String.Encoding.utf8)
    }

    override init() {

        super.init()
        responseData = nil
        resultDictionary = nil
    }

    init(data: Data?) {

        super.init()

        if isObjectInitialized(value: data as AnyObject?) {

            responseData = data

            do {
                // Try parsing some valid JSON
                resultDictionary = try JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary
                if resultDictionary == nil {
                    resultArray = try JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions.allowFragments) as? NSArray
                }
                if !success {
                    responseError = error()
                }
            } catch let error as NSError {
                // Catch fires here, with an NSErrro being thrown from the JSONObjectWithData method
                responseError = error
            }
        } else {
            responseError = error()
        }
    }

    init(error: NSError?) {
        super.init()
        responseError = error
    }

    // MARK: - Getters Methods

    /**
     The responseCode received after parsing the received data.

     - returns: get response code from api response data.
     */
    func responseCode() -> String {

        if let resultDictionary = self.resultDictionary, let code = resultDictionary[kResponseCode] as? String {
            return code
        }

        return "-1" // Unknown response code.
    }

    /**
     The statusCode received after parsing the received data.

     - returns: get status code from api response data.
     */

    func statusCode() -> NSNumber {

        let resultDictionary = self.resultDictionary
        if resultDictionary == nil {
            return -1 // Unknown response code.
        } else {
            if let code = resultDictionary![kStatusCode] {
                return code as! NSNumber
            }
        }
        return -1
    }

    /**
     The message received after parsing the received data.

     - returns: response message from api response data.
     */
    func message() -> String {

        if let resultDictionary = self.resultDictionary, let message = resultDictionary[kResponseMessage] as? String {
            return message
        }

        return (success) ? NSLocalizedString("Action performed successfully.", comment: "Action performed successfully.") : NSLocalizedString("Network not available", comment: "Network not available")
    }

    /**
     The responseError received after parsing the received data.

     - returns: error if api failed.
     */

    func error() -> NSError? {

        let mainBundle: NSDictionary = Bundle.main.infoDictionary! as NSDictionary
        let errorDictionary: NSDictionary = NSDictionary(objects: [mainBundle["CFBundleName"]!, self.message()], forKeys: [NSLocalizedDescriptionKey as NSCopying, NSLocalizedFailureReasonErrorKey as NSCopying])
        let errorReq: NSError = NSError(domain: kHTTPRequestDomain, code: Int(responseCode())!, userInfo: errorDictionary as? [AnyHashable: Any] as! [String : Any])
        return errorReq
    }
  
   
    public func isObjectInitialized(value: AnyObject?) -> Bool {
        guard let _ = value else {
            return false
        }
        return true
    }
   
}
