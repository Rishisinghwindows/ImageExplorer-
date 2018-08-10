//
//  NetworkManager.swift
//
//  Created by Rishi Kumar on 08/08/18.
//  Copyright © 2018 Rishi Kumar. All rights reserved.
//

import UIKit

public enum HTTPRequestErrorCode: Int {

    case httpConnectionError = 40 // Trouble connecting to Server.
    case httpInvalidRequestError = 50 // Your request had invalid parameters.
    case httpResultError = 60 // API result error (eg: Invalid username and password).
}

class RequestManager: NSObject {

    var _urlSession: URLSession?
    var _runningURLRequests: NSSet?

    static var networkFetchingCount: Int = 0

    // MARK: - Class Methods

    static func beginNetworkActivity() {
        networkFetchingCount += 1
        DispatchQueue.main.async {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
    }

    /**
     Call to hide network indicator in Status Bar
     */
    static func endNetworkActivity() {
        if networkFetchingCount > 0 {
            networkFetchingCount -= 1
        }

        if networkFetchingCount == 0 {
             DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }

    // MARK: - Singleton Instance
    static let _sharedManager = RequestManager()

    class func sharedManager() -> RequestManager {
        return _sharedManager
    }

    override init() {
        super.init()
        // customize initialization
    }

    // MARK: - Private Methods
    /**
     Craete Urlsession from default configuration.

     - returns: instance of Url Session.
     */
    func urlSession() -> URLSession {
        if _urlSession == nil {
            _urlSession = URLSession(configuration: URLSessionConfiguration.default)
            //            _urlSession?.sessionDescription! = "networkmanager.nsurlsession"
        }
        return _urlSession!
    }

    // MARK: - Public Methods
    /**
     Perform request to fetch data

     - parameter request:           request
     - parameter userInfo:          userinfo
     - parameter completionHandler: handler
     */
    func performRequest(_ request: NSMutableURLRequest, userInfo _: NSDictionary? = nil, completionHandler: @escaping (_ response: Response) -> Void) {
        

        performSessionDataTaskWithRequest(request, completionHandler: completionHandler)
    }

   

    /**
     Perform session data task

     - parameter request:           url request
     - parameter userInfo:          user information
     - parameter completionHandler: completion handler
     */
    func performSessionDataTaskWithRequest(_ request: NSMutableURLRequest, userInfo _: NSDictionary? = nil, completionHandler: @escaping (_ response: Response) -> Void) {
        RequestManager.beginNetworkActivity()
        addRequestedURL(request.url!)
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 8900.0
        sessionConfig.timeoutIntervalForResource = 8900.0
        let session = URLSession(configuration: sessionConfig)

        session.dataTask(with: request as URLRequest) { data, response, error in

            // let task = URLSession.shared().dataTask(with: request as URLRequest)
            RequestManager.endNetworkActivity()

            var responseError: NSError? = error as NSError?

            // handle http response status
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode > 299 {
                    responseError = self.errorForStatus(httpResponse.statusCode)
                }
            }

            var apiResponse: Response?
            if let _ = responseError {
                apiResponse = Response(data: data)

                if let _ = apiResponse?.resultDictionary {

                    if !(apiResponse?.success)! {
                        if let httpResponse = response as? HTTPURLResponse {
                            if httpResponse.statusCode == HTTPStatusCode.unauthorized.rawValue {
                                debugPrint("Unuthorized: Session Expire Notification", HTTPStatusCode.unauthorized.rawValue)
                                let message = apiResponse?.message()
                                return
                            }
                        }
                    } else {
                        // error handling
                        apiResponse = Response(error: responseError)
                    }

                } else {
                    apiResponse = Response(error: responseError)
                    self.logError(apiResponse!.responseError!, request: request)
                }

            } else {
                apiResponse = Response(data: data)
                self.logResponse(data!, forRequest: request)
            }

            self.removeRequestedURL(request.url!)

            DispatchQueue.main.async(execute: { () -> Void in
                completionHandler(apiResponse!)
            })

        }.resume()
    }

    /**
     Perform http action for a method

     - parameter method:            HTTP method
     - parameter urlString:         url string
     - parameter params:            parameters
     - parameter completionHandler: completion handler
     */
    func performHTTPActionWithMethod(_ method: HTTPRequestMethod, urlString: String, params: [String: AnyObject], completionHandler: @escaping (_ response: Response) -> Void) {
        if method == .GET {
            var components = URLComponents(string: urlString)
            components?.queryItems = params.queryItems() as [URLQueryItem]?

            if let url = components?.url {
                let request = NSMutableURLRequest(url: url)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.httpMethod = HTTPRequestMethod.GET.rawValue
                performRequest(request, completionHandler: completionHandler)
            } else { // do not proceed if the url is nil
                let resError: NSError = errorForInvalidURL()
                let res = Response(error: resError)
                completionHandler(res)
            }
        } else if method == .DELETE {
            var components = URLComponents(string: urlString)
            components?.queryItems = params.queryItems() as [URLQueryItem]?

            if let url = components?.url {
                let request = NSMutableURLRequest(url: url)
                request.httpMethod = HTTPRequestMethod.DELETE.rawValue
                performRequest(request, completionHandler: completionHandler)
            } else { // do not proceed if the url is nil
                let resError: NSError = errorForInvalidURL()
                let res = Response(error: resError)
                completionHandler(res)
            }

        } else {
            let request = NSMutableURLRequest.requestWithURL(URL(string: urlString)!, method: method, jsonDictionary: params as NSDictionary?)
            performRequest(request, completionHandler: completionHandler)
        }
    }

    
    
   
    
    
    
    func logError(_ error: NSError, request: NSMutableURLRequest) {
        #if DEBUG
            debugPrint("URL: \(String(describing: request.url?.absoluteString)) Error: \(error.localizedDescription)")
        #endif
    }

    func logResponse(_ data: Data, forRequest request: NSMutableURLRequest) {
        #if DEBUG
            debugPrint("Data Size: \(data.count) bytes")
        if let output: NSString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            debugPrint("URL: \(String(describing: request.url?.absoluteString)) Output: \(output)")
        }
        #endif
    }
}

// MARK: Request handling methods
extension RequestManager {

    /**
     Add a Url to request Manager.

     - parameter url: URL
     */
    func addRequestedURL(_ url: URL?) {
        objc_sync_enter(self)
        let requests: NSMutableSet = (runningURLRequests().mutableCopy()) as! NSMutableSet
        if let urlString: URL = url {
            requests.add(urlString)
            _runningURLRequests = requests
        }
        objc_sync_exit(self)
    }

    /**
     Remove url from Manager.

     - parameter url: URL
     */
    func removeRequestedURL(_ url: URL?) {
        objc_sync_enter(self)
        let requests: NSMutableSet = (runningURLRequests().mutableCopy()) as! NSMutableSet
        if let urlString: URL = url {
            if requests.contains(urlString) == true {
                requests.remove(urlString)
                _runningURLRequests = requests
            }
        }
        objc_sync_exit(self)
    }

    /**
     get currently running requests

     - returns: return set of running requests
     */
    func runningURLRequests() -> NSSet {
        if _runningURLRequests == nil {
            _runningURLRequests = NSSet()
        }
        return _runningURLRequests!
    }

    /**
     Check wheather requesting fro URL.

     - parameter URl: url to check.

     - returns: true if current request.
     */
    func isProcessingURL(_ url: URL) -> Bool {
        return runningURLRequests().contains(url)
    }

    /**
     Cancel session for a URL.

     - parameter url: URL
     */
    func cancelRequestForURL(_ url: URL) {
        urlSession().getTasksWithCompletionHandler({ (dataTasks: [URLSessionDataTask], uploadTasks: [URLSessionUploadTask], downloadTasks: [URLSessionDownloadTask]) -> Void in

            let capacity: NSInteger = dataTasks.count + uploadTasks.count + downloadTasks.count
            let tasks: NSMutableArray = NSMutableArray(capacity: capacity)
            tasks.addObjects(from: dataTasks)
            tasks.addObjects(from: uploadTasks)
            tasks.addObjects(from: downloadTasks)
            let predicate: NSPredicate = NSPredicate(format: "originalRequest.URL = %@", url as CVarArg)
            tasks.filter(using: predicate)

            for task in tasks {
                (task as! URLSessionDownloadTask).cancel()
            }
        })
    }

    /**
     Cancel All Running Requests
     */
    func cancelAllRequests() {
        urlSession().invalidateAndCancel()
        _urlSession = nil
        _runningURLRequests = nil
    }
}

// MARK: Error handling methods
extension RequestManager {

    /**
     Get Error instances if Nil URL.

     - returns: Error instance.
     */
    func errorForInvalidURL() -> NSError {
        return NSError(domain: NSURLErrorDomain, code: -1, userInfo: [NSLocalizedFailureReasonErrorKey: "URL must not be nil"])
    }

    /**
     Get Error instances for NoNetwork.

     - returns: Error instance.
     */
    func errorForNoNetwork() -> NSError {
        return NSError(domain: NSURLErrorDomain, code: HTTPRequestErrorCode.httpConnectionError.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: "Network not available"])
    }

    /**
     Get Error instances for connectionError.

     - returns: connectionError instance.
     */
    func connectionError() -> NSError {
        let errorDict = [NSLocalizedDescriptionKey: NSLocalizedString("Connection Error", comment: "Connection Error"), NSLocalizedFailureReasonErrorKey: NSLocalizedString("Network error occurred while performing this task. Please try again later.", comment: "Network error occurred while performing this task. Please try again later.")]
        let error: NSError = NSError(domain: kHTTPRequestDomain, code: HTTPRequestErrorCode.httpConnectionError.rawValue, userInfo: errorDict)
        return error
    }

    /**
     Create an error for response you probably don't want (400-500 HTTP responses for example).

     - parameter code: Code for error.

     - returns: An NSError.
     */
    func errorForStatus(_ code: Int) -> NSError {
        let text = NSLocalizedString(HTTPStatusCode(statusCode: code).statusDescription, comment: "")
        return NSError(domain: "HTTP", code: code, userInfo: [NSLocalizedDescriptionKey: text])
    }
}

//// MARK: Network reachable methods
//extension RequestManager {
//
//    /**
//     Check wheather network is reachable.
//
//     - returns: true is reachable otherwise false.
//     */
//    func isNetworkReachable() -> Bool {
//        let reach: Reachability = Reachability.forInternetConnection()
//        return reach.currentReachabilityStatus() != .NotReachable
//    }
//
//    /**
//     Check wheather WiFi is reachable.
//
//     - returns: true is reachable otherwise false.
//     */
//    func isReachableViaWiFi() -> Bool {
//        let reach: Reachability = Reachability.forInternetConnection()
//        return reach.currentReachabilityStatus() != .ReachableViaWiFi
//    }
//}
