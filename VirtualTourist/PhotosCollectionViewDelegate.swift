//
//  PhotosCollectionViewDelegate.swift
//  VirtualTourist
//
//  Created by Moath_Othman on 9/15/15.
//  Copyright (c) 2015 Moba. All rights reserved.
//

import Foundation
import UIKit
import CoreData
extension PhotosViewController {



    //MARK:CollectionView Datasource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] 
        if sectionInfo.numberOfObjects == 0 {
            collectionView.backgroundColor = UIColor.clearColor()
        }else {
            collectionView.backgroundColor = UIColor.whiteColor()
        }

        return sectionInfo.numberOfObjects

    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let CellIdentifier = "photoCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! VLTPhotoCollectionViewCell
        configureCell(cell, photo: photoForIndex(indexPath))

        let coverView: UIView = cell.contentView.viewWithTag(2)!
        if checkIfPhotoIsAlreadySelected(indexPath) {
            coverView.backgroundColor = UIColor(white: 0.8, alpha: 0.9)
        } else {
            coverView.backgroundColor = nil
        }
        return cell
    }

    
    func configureCell(cell: VLTPhotoCollectionViewCell, photo: Photo) {
        let imageView = cell.contentView.viewWithTag(1) as! UIImageView
        let animator = cell.contentView.viewWithTag(3) as! UIActivityIndicatorView

        var pinImage = UIImage(named: "posterPlaceHoldr")

        if  photo.url_m == "" {
            pinImage = UIImage(named: "noImage")
            animator.stopAnimating()
        } else if photo.image != nil {
            pinImage = photo.image
            animator.stopAnimating()
        } else {
            animator.startAnimating()
            let task =  VLTFlickerClient.sharedInstance().taskForImageWithURL(photo.url_m, completionHandler: { (imageData, error) -> Void in
                if let error = error {
                    print("Poster download error: \(error.localizedDescription)")
                }

                if let data = imageData {
                    // Craete the image
                    let image = UIImage(data: data)
                    dispatch_async(dispatch_get_main_queue()) {
                        photo.image = image 
                        imageView.image = image
                        animator.stopAnimating()
                    }
                }

            })
            cell.task = task
            cell.taskToCancelifCellIsReused = task
        }
        imageView.image = pinImage
    }


    //MARK: CollectionView Delegate
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        bottomActionbarButton.title = DELETE_SELECTED_PHOTOS
        if checkIfPhotoIsAlreadySelected(indexPath) {
            indicesSelected.removeValueForKey(indexPath)
        } else {
            indicesSelected[indexPath] = self.photoForIndex(indexPath)
        }
        collectionView.reloadItemsAtIndexPaths([indexPath])
    }
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
//        highlightCell(indexPath, flag: !checkIfPhotoIsAlreadySelected(indexPath))
    }
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    //MARK: heighlight cells
    func highlightCell(indexPath : NSIndexPath, flag: Bool) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        let coverView: UIView = cell!.contentView.viewWithTag(2)!
        if flag {
            coverView.backgroundColor = UIColor(white: 0.8, alpha: 0.9)
//            indicesSelected[indexPath] = self.photoForIndex(indexPath)
        } else {
            coverView.backgroundColor = nil
//            indicesSelected.removeValueForKey(indexPath)
            //            indicesSelected.removeAtIndex(indexPath.row)
        }

    }
    func checkIfPhotoIsAlreadySelected(indx: NSIndexPath) -> Bool {
        for foto in indicesSelected.keys {
            if foto == indx {
                return true
            }
        }
        return false
    }
    func isThereAnySelectedPhoto() -> Bool {
        if indicesSelected.count > 0 {
            return true
        }
        return false
    }
    func unHighLighAll() {
        for i in 0...countOfEntities() {
            collectionView.reloadItemsAtIndexPaths([NSIndexPath(index: i)])
        }
    }

    func deleteCells(sender: AnyObject) {

        var deletedPhotos:[Photo] = []

        let indexpaths = indicesSelected.keys

        for item  in indexpaths {
                _ = collectionView!.cellForItemAtIndexPath(item  )
                collectionView?.deselectItemAtIndexPath(item  , animated: true)
                // fruits for section
                let sectionfruits = indicesSelected[item]
                deletedPhotos.append(sectionfruits!)
                deletePhoto(indicesSelected[item]!)
                indicesSelected.removeValueForKey(item)
//                highlightCell(item as! NSIndexPath , flag: false)
                collectionView.reloadItemsAtIndexPaths([item])
            }

            bottomActionbarButton.title = NEW_COLLECTION
            
        CoreDataStackManager.sharedInstance().saveContext()
    }

}