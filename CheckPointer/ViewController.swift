//
//  ViewController.swift
//  CheckPointer
//
//  Created by Mike on 20/08/2020.
//  Copyright © 2020 mannett. All rights reserved.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var routeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var pointLabel: UILabel!
    
    let locationDelegate = LocationDelegate()
    var latestLocation: CLLocation? = nil
    var yourLocationBearing: CGFloat { return latestLocation?.bearingToLocationRadian(self.targetPoint) ?? 0 }
    var targetPoint: CLLocation {
        get { return UserDefaults.standard.currentLocation }
        set { UserDefaults.standard.currentLocation = newValue }
    }
    static var onceToken = false;
    
    func formatDistance(_ dist: Double) -> String{
        let numberFormatter = NumberFormatter()
        numberFormatter.groupingSeparator = ","
        numberFormatter.groupingSize = 3
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.decimalSeparator = "."
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter.string(from: dist as NSNumber)! + "m"
    }
    
    let locationManager: CLLocationManager = {
        $0.requestWhenInUseAuthorization()
        $0.desiredAccuracy = kCLLocationAccuracyBest
        $0.startUpdatingLocation()
        $0.startUpdatingHeading()
        return $0
    }(CLLocationManager())
    
    private func orientationAdjustment() -> CGFloat {
        let isFaceDown: Bool = {
            switch UIDevice.current.orientation {
            case .faceDown: return true
            default: return false
            }
        }()
        
        let adjAngle: CGFloat = {
            switch UIApplication.shared.statusBarOrientation {
            case .landscapeLeft:  return 90
            case .landscapeRight: return -90
            case .portrait, .unknown: return 0
            case .portraitUpsideDown: return isFaceDown ? 180 : -180
            }
        }()
        return adjAngle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = locationDelegate
        
        locationDelegate.locationCallback = { location in
            self.latestLocation = location
            let distance = location.distance(from: self.targetPoint)
            self.distanceLabel.text = self.formatDistance(distance)
        }
        
        locationDelegate.headingCallback = { newHeading in
            func computeNewAngle(with newAngle: CGFloat) -> CGFloat {
                let heading: CGFloat = {
                    let originalHeading = self.yourLocationBearing - newAngle.degreesToRadians
                    switch UIDevice.current.orientation {
                    case .faceDown: return -originalHeading
                    default: return originalHeading
                    }
                }()
                
                return CGFloat(self.orientationAdjustment().degreesToRadians + heading)
            }
            
            UIView.animate(withDuration: 0.5) {
                let angle = computeNewAngle(with: CGFloat(newHeading))
                
                self.imageView.transform = CGAffineTransform(rotationAngle: angle)
                
            }
        }
        
        if !ViewController.onceToken
        {
            ViewController.onceToken = true
            self.setupRoutes()
        }
        
        changeRoute( route: currRoute )
        
        /*
         let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CompassViewController.showMap))
         view.addGestureRecognizer(tapGestureRecognizer) */
    }
    
    func changeRoute( route: Route ){
        // pointIndex = Int.min
        currentRoute = route
        changePoint( point: currentRoute!.currentPoint() )
        routeLabel.text = route.name
    }
    
    func changePoint( point: Point ){
        targetPoint = CLLocation(latitude: point.lat, longitude: point.long)
        pointLabel.text = "\(point.name): \(point.lat), \(point.long)"
    }
    
    /*
    at IB Action func nextPointTap(_ sender: UIBarButtonItem
    changePoint( point: currentRoute!.prevPoint() )
    changePoint( point: currentRoute!.nextPoint() )
    changeRoute( route: prevRoute )
     print("abc")
    changeRoute( route: nextRoute )
    */
    
    @IBAction func prevPointTap(_ sender: UIBarButtonItem) {
        changePoint( point: currentRoute!.prevPoint() )
    }
    
    @IBAction func nextPointTap(_ sender: UIBarButtonItem) {
        changePoint( point: currentRoute!.nextPoint() )
    }
    
    @IBAction func prevRouteTap(_ sender: UIBarButtonItem) {
        changeRoute( route: prevRoute )
    }
    

    @IBAction func nextRouteTap(_ sender: UIBarButtonItem) {
        changeRoute( route: nextRoute )
    }
}
