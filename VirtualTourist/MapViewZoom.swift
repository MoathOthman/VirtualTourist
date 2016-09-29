//
//  MapViewZoom.swift
//  VirtualTourist
//
//  Created by Moath_Othman on 9/10/15.
//  Copyright (c) 2015 Moba. All rights reserved.
//

import Foundation
import MapKit
import UIKit
extension MKMapView {



//    func setZoomLevel(zoomLevel: Int) {
//     [self setCenterCoordinate:self.centerCoordinate zoomLevel:zoomLevel animated:NO];
//    }

    func zoomLevel() -> Double{
        let zoom: Double = Double(360.0 * Double(((self.frame.size.width/256.0))) / Double(self.region.span.longitudeDelta))
        return  log2(zoom) + 1.0;
    }

    func setCenterCoordinate(_ centerCoordinate: CLLocationCoordinate2D, zoomLevel :Float, animated: Bool) {
        let lonDis = Double(360.0 / pow(2, zoomLevel)) * Double(self.frame.size.width / 256.0)
        let span: MKCoordinateSpan = MKCoordinateSpanMake(0,lonDis);
        self.setRegion(MKCoordinateRegionMake(centerCoordinate, span), animated: animated)
    }



}
