//
//  PhotoCell.swift
//  ImageViewer
//
//  Created by Rishi Kumar on 09/08/18.
//  Copyright © 2018 Rishi Kumar. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    @IBOutlet weak var photoImageView: UIImageView!
    
    func setupData(info:Photo?)  {
        photoImageView.image = nil
        let imageUrl = String(format:"https://farm%d.static.flickr.com/%@/%@_%@.jpg", info?.farm ?? 0,info?.server ?? "", info?.id ?? "", info?.secret ?? "")
        if URL.init(string: imageUrl) != nil {
            photoImageView.downloadImageFromUrl(url: imageUrl);
        }
    }
}
