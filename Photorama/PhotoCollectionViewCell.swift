//
//  PhotoCollectionViewCell.swift
//  Photorama
//
//  Created by Andy Steinmann on 3/30/17.
//  Copyright © 2017 DLS. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var label: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        update(with: nil)
    }


    override func prepareForReuse() {
        super.prepareForReuse()
        update(with: nil)
    }


    func update(with image: UIImage?, photo: Photo? = nil) {
        if let imageToDisplay = image {
            spinner.stopAnimating()
            imageView.image = imageToDisplay
        } else {
            spinner.startAnimating()
            imageView.image = nil
        }
        
        label.text = nil
        
        //if let uploaded = photo?.dateUploaded?.timeIntervalSince1970{
            label.text = photo?.title //String(uploaded)
        //}
        
    }

}
