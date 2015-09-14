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
class MapViewController: UIViewController,MKMapViewDelegate {
    var editorEnabled: Bool = false
    let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!

    /*Outlets*/
    @IBOutlet weak var notebuttonBottomVerticalSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var noteButton: UIButton!
    @IBOutlet weak var noteButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var editBarButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    var annotations = [MKPointAnnotation]()
    var _pins = [Pin]()
    var temporaryContext: NSManagedObjectContext!

    func buildAnnotationsFromPins() {
      _pins = fetchAllPins()
        for pin in _pins {
            var annotation = MKPointAnnotation()
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

        
        var longPressRecogniser = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        notebuttonBottomVerticalSpaceConstraint.constant = -positionShitMax
        longPressRecogniser.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecogniser)

               // Do any additional setup after loading the view.
    }
    override func viewWillAppear(animated: Bool) {
        if let map = Map.fetchMapObject(sharedContext) {
            var centerLocation = CLLocation(latitude:CLLocationDegrees(map.centerX), longitude: CLLocationDegrees(map.centerY))
            centerMapOnLocation(centerLocation, latD: CLLocationDistance(map.latDistance), lonD: CLLocationDistance(map.lonDistance))
        }
    }

    func centerMapOnLocation(location: CLLocation, latD: CLLocationDistance, lonD: CLLocationDistance) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate,
            latD , lonD )
        mapView.region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpanMake(latD, lonD))
        mapView.setCenterCoordinate(mapView.region.center, animated: true)
    }
    @IBAction func editPins(sender: AnyObject) {
        if editorEnabled == false{
            self.notebuttonBottomVerticalSpaceConstraint.constant = positionShitMin
            editorEnabled = true
            editBarButton.title = "Done"
         }else  {
            self.notebuttonBottomVerticalSpaceConstraint.constant = -positionShitMax
            editorEnabled = false
            editBarButton.title = "Edit"
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
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)

        // Check for Errors
        if error != nil {
            println("Error in fectchAllActors(): \(error)")
        }

        // Return the results, cast to an array of Person objects
        return results as! [Pin]
    }

    func addAnnotationInDB(annotation: MKPointAnnotation) {
       var pin = Pin(dictionary: ["lat":annotation.coordinate.latitude,"lon":annotation.coordinate.longitude], context: self.sharedContext)
        _pins.append(pin)
        CoreDataStackManager.sharedInstance().saveContext()
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
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if let annotation = annotation   {
            let identifier = "pin"
            var view: MKPinAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
                as? MKPinAnnotationView { // 2
                    dequeuedView.annotation = annotation
                    view = dequeuedView
            } else {
                // 3
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.animatesDrop = true

            }
            return view
        }
        return nil
    }
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!,
        calloutAccessoryControlTapped control: UIControl!) {
    }
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        if editorEnabled {
            if let pin = getPinObjectForAnnotation(view.annotation) {
                sharedContext.deleteObject(pin)
            }
            mapView.removeAnnotation(view.annotation)

            sharedContext.save(nil)
        } else {
            let photosViewController: PhotosViewController? = self.storyboard?.instantiateViewControllerWithIdentifier("PhotosViewController") as? PhotosViewController
            photosViewController?.currentannotation = view.annotation
            photosViewController?.currentPin = getPinObjectForAnnotation(view.annotation)
            self.navigationController?.pushViewController(photosViewController! as UIViewController, animated: true)
        }
        mapView.deselectAnnotation(view.annotation, animated: true)
    }

    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        let latitudeCircumference = 40075160 * cos(self.mapView.region.center.latitude * M_PI / 180)
        var parameters = [
            Map.Keys.latDistance: mapView.region.span.latitudeDelta  ,
            Map.Keys.lonDistance: mapView.region.span.longitudeDelta ,
            Map.Keys.centerX:Float(mapView.region.center.latitude),
            Map.Keys.centerY:Float(mapView.region.center.longitude)
        ]
        Map(dictionary: parameters as! [String : AnyObject], context: sharedContext)
        CoreDataStackManager.sharedInstance().saveContext()

    }
}

