//
//  VLTPhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Moath_Othman on 9/5/15.
//  Copyright (c) 2015 Moba. All rights reserved.
//

import UIKit

class VLTPhotoCollectionViewCell: UICollectionViewCell {
    var imageName: String = ""
    var task: NSURLSessionTask!
    var taskToCancelifCellIsReused: NSURLSessionTask? {

        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
