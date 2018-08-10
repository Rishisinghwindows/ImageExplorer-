//
//  Constants.swift
//  Grilld
//
//  Created by Appster on 01/08/17.
//  Copyright © 2017 Appster. All rights reserved.
//

import Foundation

struct Constants {
    
    static let BASE_URL = Constants.apiBaseURL()
    
    static func apiBaseURL() -> String {
        return ConfigurationManager.sharedManager().applicationEndPoint()
    }
    
    struct APIServiceMethods {
        
        //        static let campaignAPI = Constants.APIServiceMethods.apiURL("dev/globals/mobile")
        //        static let newsAPI = Constants.APIServiceMethods.apiURL("dev/news")
        //        static let newsDetails = Constants.APIServiceMethods.apiURL("locations/1458")
        static let flickerApi = Constants.APIServiceMethods.apiURL("rest/?method=flickr.photos.search&api_key=3e7cc266ae2b0e0d78e279ce8e361736&format=json&nojsoncallback=1&safe_search=1&text=kittens")
    
        static func apiURL(_ methodName: String) -> String {
            return Constants.BASE_URL + "/" + methodName
        }
        
    }
    
  
}
