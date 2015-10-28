//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Moath_Othman on 8/25/15.
//  Copyright (c) 2015 Moba. All rights reserved.
//

import UIKit
import MapKit
import CoreData

let positionShitMax: CGFloat = 60
let positionShitMin: CGFloat = 0
let TAP_PINS_TO_DELETE = "Tap Pins to Delete"
let DRAG_PINS_TO_UPDATE_LOCATIOM = "Drag Pins to Update Locations"

class MapViewController: UIViewController,MKMapViewDelegate {
    var editorEnabled: Bool = false
    var updatingEnabled: Bool = false
    let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!

    /*Outlets*/
    @IBOutlet weak var notebuttonBottomVerticalSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var noteButton: UIButton!
    @IBOutlet weak var noteButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var updatePinsBarButton: UIBarButtonItem!
    @IBOutlet weak var InstructionBottomButton: UIButton!


    var annotations = [MKPointAnnotation]()
    var _pins = [Pin]()
    var temporaryContext: NSManagedObjectContext!

    func buildAnnotationsFromPins() {
      _pins = fetchAllPins()
        for pin in _pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = CLLocationDegrees(pin.lat.doubleValue)
            annotation.coordinate.longitude = CLLocationDegrees(pin.lon.doubleValue)
            annotations.append(annotation)
        }
        self.mapView.addAnnotations(annotations)
    }
    //MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.buildAnnotationsFromPins()

        // Set the temporary context
        temporaryContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        temporaryContext.persistentStoreCoordinator = sharedContext.persistentStoreCoordinator

        
        let longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        notebuttonBottomVerticalSpaceConstraint.constant = -positionShitMax
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)

        checkOnPinsAndEnabledOrDisableNavBarItems()
               // Do any additional setup after loading the view.
    }
    override func viewWillAppear(animated: Bool) {
        if let map = Map.fetchMapObject(sharedContext) {
            let centerLocation = CLLocation(latitude:CLLocationDegrees(map.centerX), longitude: CLLocationDegrees(map.centerY))
            centerMapOnLocation(centerLocation, latD: CLLocationDistance(map.latDistance), lonD: CLLocationDistance(map.lonDistance))
        }
    }

    func checkOnPinsAndEnabledOrDisableNavBarItems() {
        if _pins.isEmpty {
            //no pins currently
            enableNavBarButtonsIfNeeded(false,force:true)
        }
    }
    func enableNavBarButtonsIfNeeded(enabled: Bool,force: Bool) {
        if !updatingEnabled || force {
        editBarButton.enabled = enabled
        }
        if !editorEnabled || force {
        updatePinsBarButton.enabled = enabled
        }
    }
    func centerMapOnLocation(location: CLLocation, latD: CLLocationDistance, lonD: CLLocationDistance) {
        _ = MKCoordinateRegionMakeWithDistance(location.coordinate,
            latD , lonD )
        mapView.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpanMake(latD, lonD))
        mapView.setCenterCoordinate(mapView.region.center, animated: true)
    }
    @IBAction func editPins(sender: AnyObject) {
         if editorEnabled == false{
            editorEnabled = true
            editBarButton.title = "Done"
            updatePinsBarButton.enabled = false
            updatingEnabled = false
            self.notebuttonBottomVerticalSpaceConstraint.constant = positionShitMin

         }else  {
            editorEnabled = false
            editBarButton.title = "Edit"
            updatePinsBarButton.enabled = true
            self.notebuttonBottomVerticalSpaceConstraint.constant = -positionShitMax

        }
        UIView.animateWithDuration(0.15, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })

    }
    func showInstructionPinsWithInstructions() {
        if !updatingEnabled || (!updatingEnabled && !editorEnabled) {
            self.notebuttonBottomVerticalSpaceConstraint.constant = positionShitMin
            self.InstructionBottomButton.setTitle(DRAG_PINS_TO_UPDATE_LOCATIOM, forState: .Normal)
        } else {
            self.InstructionBottomButton.setTitle(TAP_PINS_TO_DELETE, forState: .Normal)
            self.notebuttonBottomVerticalSpaceConstraint.constant = -positionShitMax
        }
        UIView.animateWithDuration(0.15, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })

    }
    func fetchAllPins() -> [Pin] {
        let error: NSErrorPointer = nil

        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")

        // Execute the Fetch Request
        let results: [AnyObject]?
        do {
            results = try sharedContext.executeFetchRequest(fetchRequest)
        } catch let error1 as NSError {
            error.memory = error1
            results = nil
        }

        // Check for Errors
        if error != nil {
            print("Error in fectchAllActors(): \(error)")
        }

        // Return the results, cast to an array of Person objects
        return results as! [Pin]
    }

    func addAnnotationInDB(annotation: MKPointAnnotation) {
       let pin = Pin(dictionary: ["lat":annotation.coordinate.latitude,"lon":annotation.coordinate.longitude], context: self.sharedContext)
        _pins.append(pin)

        CoreDataStackManager.sharedInstance().saveContext()
        VLTPhotosFetcher.fetchPhotosForPin(pin, context: sharedContext)
        enableNavBarButtonsIfNeeded(true,force: false)
    }

    func handleLongPress(getstureRecognizer : UIGestureRecognizer){
        if getstureRecognizer.state != .Began { return }

        let touchPoint = getstureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)

        let annotation = MKPointAnnotation()

        annotation.coordinate = touchMapCoordinate
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.mapView.addAnnotation(annotation)
        })
        self.addAnnotationInDB(annotation)
    }


    func getPinObjectForAnnotation(annotation:MKAnnotation?) -> Pin? {
        _pins = fetchAllPins()
        for pino in _pins {
            let numberofplaces: Float = 8.0
            let pinoLat: Int = Int( roundFloatToDecimal(Float(pino.lat.doubleValue), numberOfPlaces: numberofplaces) * powf(10.0, numberofplaces))
            let annoLat  = Int(roundFloatToDecimal(Float(annotation!.coordinate.latitude), numberOfPlaces: numberofplaces) * powf(10.0, numberofplaces))
            let pinlon = Int(roundFloatToDecimal(Float(pino.lon.doubleValue), numberOfPlaces: numberofplaces) * powf(10.0, numberofplaces))
            let annolong = Int(roundFloatToDecimal(Float(annotation!.coordinate.longitude), numberOfPlaces: numberofplaces) * powf(10.0, numberofplaces))
            if pinoLat == annoLat {
                if pinlon == annolong {
                return pino
                }
            }

        }
        return nil
    }
}

//MARK: MapView Delegate
extension MapViewController {
    func roundFloatToDecimal(decimal: Float, numberOfPlaces: Float) -> Float {
        let numberOfPlaces = numberOfPlaces
        let multiplier = pow(10.0, numberOfPlaces)
        let mul = decimal * multiplier
        let rounded = round(mul) / multiplier
        return rounded
    }
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
             let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView { // 2
                    dequeuedView.annotation = annotation
                    view = dequeuedView
                    view.draggable = true
            } else {
                // 3
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.animatesDrop = true
                view.draggable = true
            }
            return view
     }
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView,
        calloutAccessoryControlTapped control: UIControl) {
    }
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if updatingEnabled {
            return
        }
        if editorEnabled {
            if let pin = getPinObjectForAnnotation(view.annotation) {
                sharedContext.deleteObject(pin)
            }
            mapView.removeAnnotation(view.annotation!)
            do {
                try sharedContext.save()
            } catch _ {
            }
        } else {
            let photosViewController: PhotosViewController? = self.storyboard?.instantiateViewControllerWithIdentifier("PhotosViewController") as? PhotosViewController
            photosViewController?.currentannotation = view.annotation
            photosViewController?.currentPin = getPinObjectForAnnotation(view.annotation)
            self.navigationController?.pushViewController(photosViewController! as UIViewController, animated: true)
        }
        mapView.deselectAnnotation(view.annotation, animated: true)
    }
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {

    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        _ = 40075160 * cos(self.mapView.region.center.latitude * M_PI / 180)
        let parameters = [
            Map.Keys.latDistance: mapView.region.span.latitudeDelta  ,
            Map.Keys.lonDistance: mapView.region.span.longitudeDelta ,
            Map.Keys.centerX:Float(mapView.region.center.latitude),
            Map.Keys.centerY:Float(mapView.region.center.longitude)
        ]
        _ = Map(dictionary: parameters as! [String : AnyObject], context: sharedContext)
        CoreDataStackManager.sharedInstance().saveContext()

    }
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        var pin:Pin
        if newState == MKAnnotationViewDragState.Starting {
            //Get the pin for the annotation
            pin = getPinObjectForAnnotation(view.annotation)!
        }
        if newState == MKAnnotationViewDragState.Ending {
            pin = Pin(dictionary: ["lat":view.annotation!.coordinate.latitude,"lon":view.annotation!.coordinate.longitude], context: self.sharedContext)
            pin.photos = NSSet() //reset photos
            pin.isPhotosDownloaded = false
            pin.isPinMoved = true
            CoreDataStackManager.sharedInstance().saveContext()
            mapView.deselectAnnotation(view.annotation, animated: true)
            //fetch again 
            VLTPhotosFetcher.fetchPhotosForPin(pin, context: sharedContext)
        }

    }


    @IBAction func updatePinsLocation(sender: UIBarButtonItem) {
        showInstructionPinsWithInstructions()
        if !updatingEnabled {
            updatePinsBarButton.title = "Done"
            editBarButton.enabled = false // no editting while updating
            editorEnabled = false

        }else {
            updatePinsBarButton.title = "Update Pins"
            editBarButton.enabled = true // no editting while updating

        }
        updatingEnabled = !updatingEnabled
    }

}

