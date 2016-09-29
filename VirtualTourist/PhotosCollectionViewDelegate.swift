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

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] 
        if sectionInfo.numberOfObjects == 0 {
            collectionView.backgroundColor = UIColor.clear
        }else {
            collectionView.backgroundColor = UIColor.white
        }

        return sectionInfo.numberOfObjects

    }
    @objc(collectionView:cellForItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let CellIdentifier = "photoCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as! VLTPhotoCollectionViewCell
        configureCell(cell, photo: photoForIndex(indexPath))

        let coverView: UIView = cell.contentView.viewWithTag(2)!
        if checkIfPhotoIsAlreadySelected(indexPath) {
            coverView.backgroundColor = UIColor(white: 0.8, alpha: 0.9)
        } else {
            coverView.backgroundColor = nil
        }
        return cell
    }

    
    func configureCell(_ cell: VLTPhotoCollectionViewCell, photo: Photo) {
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
                    DispatchQueue.main.async {
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
    @objc(collectionView:didSelectItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        bottomActionbarButton.title = DELETE_SELECTED_PHOTOS
        if checkIfPhotoIsAlreadySelected(indexPath) {
            indicesSelected.removeValue(forKey: indexPath)
        } else {
            indicesSelected[indexPath] = self.photoForIndex(indexPath)
        }
        collectionView.reloadItems(at: [indexPath])
    }
    @objc(collectionView:didDeselectItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
//        highlightCell(indexPath, flag: !checkIfPhotoIsAlreadySelected(indexPath))
    }
    @objc(collectionView:shouldHighlightItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    //MARK: heighlight cells
    func highlightCell(_ indexPath : IndexPath, flag: Bool) {
        let cell = collectionView.cellForItem(at: indexPath)
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
    func checkIfPhotoIsAlreadySelected(_ indx: IndexPath) -> Bool {
        for foto in indicesSelected.keys {
            if foto as IndexPath == indx {
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
            collectionView.reloadItems(at: [IndexPath(index: i)])
        }
    }

    func deleteCells(_ sender: AnyObject) {

        var deletedPhotos:[Photo] = []

        let indexpaths = indicesSelected.keys

        for item  in indexpaths {
                _ = collectionView!.cellForItem(at: item as IndexPath  )
                collectionView?.deselectItem(at: item as IndexPath  , animated: true)
                // fruits for section
                let sectionfruits = indicesSelected[item]
                deletedPhotos.append(sectionfruits!)
                deletePhoto(indicesSelected[item]!)
                indicesSelected.removeValue(forKey: item)
//                highlightCell(item as! NSIndexPath , flag: false)
                collectionView.reloadItems(at: [item as IndexPath])
            }

            bottomActionbarButton.title = NEW_COLLECTION
            
        CoreDataStackManager.sharedInstance().saveContext()
    }

}
