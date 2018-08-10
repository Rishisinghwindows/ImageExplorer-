//
//  Photos+Services.swift
//  ImageViewer
//
//  Created by Rishi Kumar on 09/08/18.
//  Copyright © 2018 Rishi Kumar. All rights reserved.
//

import Foundation
typealias photosCompletionBlock = (_ status:Bool?, _ photos: Photos?, _ error: Error?) -> Void
extension Photos {
    
    static func fetchPhotos(searchText:String, _ completion:@escaping(photosCompletionBlock)) {
        
        let flickerApi = "https://api.flickr.com/services/rest/"
        let params = ["text":searchText , "method":"flickr.photos.search" , "api_key":"3e7cc266ae2b0e0d78e279ce8e361736" ,"format":"json" , "nojsoncallback":"1" , "safe_search":"1" ] as [String : AnyObject]
        RequestManager.sharedManager().performHTTPActionWithMethod(.GET, urlString: flickerApi, params: params as [String : AnyObject]) { (response) -> Void in
            if response.success {
                
                if let resultDictionary = response.resultDictionary {
                
                let photos = Photos.init()
                if let resultDict = resultDictionary["photos"] as? NSDictionary {
                    if let page = resultDict["page"] as? Int {
                        photos.page = page
                    }
                    if let perpage = resultDict["perpage"] as? Int {
                        photos.perpage = perpage
                    }
                    if let pages = resultDict["page"] as? Int {
                        photos.pages = pages
                    }
                    if let total = resultDict["total"] as? String {
                        photos.total = total
                    }
                    if let photosDictionay = resultDict["photo"] as? [NSDictionary]{
                        for photoDic in photosDictionay {
                            let photo = Photo.init()
                            if let id = photoDic["id"] as? String {
                                photo.id = id
                            }
                            if let owner = photoDic["owner"] as? String {
                                photo.owner = owner
                            }
                            if let secret = photoDic["secret"] as? String {
                                photo.secret = secret
                            }
                            if let server = photoDic["server"] as? String {
                                photo.server = server
                            }
                            if let farm = photoDic["farm"] as? Int {
                                photo.farm = farm
                            }
                            if let title = photoDic["title"] as? String {
                                photo.title = title
                            }
                            if let ispublic = photoDic["ispublic"] as? Int {
                                photo.ispublic = ispublic
                            }
                            if let isfriend = photoDic["isfriend"] as? Int {
                                photo.isfriend = isfriend
                            }
                            if let isfamily = photoDic["isfamily"] as? Int {
                                photo.isfamily = isfamily
                            }
                            photos.photo.append(photo)
                        }
                    }
                }
                completion(true , photos,nil)
                }
            } else {
                completion(false,nil, response.responseError)
            }
        }
    }
    
}
