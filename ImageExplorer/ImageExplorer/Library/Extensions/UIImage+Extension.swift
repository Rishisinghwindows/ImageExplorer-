//
//  UIImage+Extension.swift
//  ImageViewer
//
//  Created by Rishi Kumar on 09/08/18.
//  Copyright © 2018 Rishi Kumar. All rights reserved.
//

import UIKit
extension UIImageView {
    static let imageCache = NSCache<NSString, AnyObject>()
    
    func downloadImageFromUrl(url:String)  {
        if let url = URL(string:url) {
            if let image =  UIImageView.imageCache.object(forKey: url.absoluteString as NSString) as? UIImage {
                DispatchQueue.main.async() {    // execute on main thread
                    self.image = image
                }
            }
            else {
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data, error == nil else { return }
                    DispatchQueue.main.async() {    // execute on main thread
                        let image = UIImage(data: data)
                        self.image = image
                        UIImageView.imageCache.setObject(image!, forKey: url.absoluteString as NSString)
                    }
                }
                task.resume();
            }
        }
    }
    
}
