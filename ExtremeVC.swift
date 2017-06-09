//
//  ExtremeVC.swift
//  Women Security
//
//  Created by Devesh kataria on 22/05/17.
//  Copyright © 2017 Devesh kataria. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import Firebase
import GoogleMaps
import GooglePlaces
import GooglePlacePicker
import Alamofire
import SwiftyJSON
import MessageUI
import AVFoundation

class ExtremeVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, GMSMapViewDelegate, MFMessageComposeViewControllerDelegate {
    

    @IBOutlet weak var tapImg: UIImageView!
    @IBOutlet weak var safeBtn: ButtonView!
    @IBOutlet weak var direcMAp: GMSMapView!
    private var locationManager = CLLocationManager()
    private var userLocation: CLLocationCoordinate2D?
    var mapView: GMSMapView!
    var placePicker: GMSPlacePicker!
    var latitude: Double!
    var longitude: Double!
    var timer = Timer()
    var minTime = 60
    var minTimeIndex = 0
    var routeVal: JSON!
    var initCounter = 0
    var callCounter = 0
    var highPitchSound: AVAudioPlayer!
    var timer2 = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let path = Bundle.main.path(forResource: "scream", ofType: "mp3")
        let soundUrl = NSURL(fileURLWithPath: path!)
        
        do {
            try highPitchSound = AVAudioPlayer(contentsOf: soundUrl as URL)
            highPitchSound.prepareToPlay()
        } catch let err as NSError
        {
            print(err.debugDescription)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let camera = GMSCameraPosition.camera(withLatitude: 20.5937, longitude: 78.9629, zoom: 0)
        mapView = GMSMapView.map(withFrame: direcMAp.bounds, camera: camera)
        direcMAp.addSubview(mapView)
        mapView.isMyLocationEnabled = true
        mapView.animate(to: camera)
        mapView.delegate = self
        safeLocation()
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(ExtremeVC.searchInMap), userInfo: nil, repeats: true)

    }

    
    func safeLocation() {
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
        
        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        let location:CLLocation = locations.last!
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        userLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.locationManager.stopUpdatingLocation()
        
        if initCounter == 0 {
            
            searchInMap()
            mapView.animate(toViewingAngle: 70)
            initCounter = 1
        }
        
        
    }
    
    func searchInMap() {
        
 
        let vancouver = CLLocationCoordinate2D(latitude: (self.userLocation?.latitude)!, longitude: (self.userLocation?.longitude)!)
        let vancouverCam = GMSCameraUpdate.setTarget(vancouver)
        self.mapView.animate(with: vancouverCam)
        self.mapView.animate(toViewingAngle: 70)
        self.mapView.animate(toZoom: 16)
        
        
        let position = CLLocationCoordinate2D(latitude: -18.23, longitude: 151.20)
        let marker = GMSMarker(position: position)
        marker.map = self.mapView
        
        mapView.clear()
        
        let lat = String(latitude)
        let long = String(longitude)
        
        let url = NSURL(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(lat),\(long)&radius=500&type=school&open_now=false&key=AIzaSyDEmH_dSh2GGclN4Uuf1NfH5lY7T0-3VgI")
        let task = URLSession.shared.dataTask(with: url! as URL) { (data, response, error) -> Void in
            
            if let urlContent = data {
                
                do {
                    
                    let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
                    //print(jsonResult)
                    
                    if let results = jsonResult["results"] as? [[String : AnyObject]] {
                        
                        for result in results{

                            let name = result["name"] as! String
                            let geo = result["geometry"] as! [String: AnyObject]
                            let loc = geo["location"]
                            let lati = loc?["lat"]
                            let longi = loc?["lng"]
                            let position = CLLocationCoordinate2D(latitude: lati as! CLLocationDegrees, longitude: longi as! CLLocationDegrees)
                            let marker = GMSMarker(position: position)
                            marker.title = name
                            marker.map = self.mapView
                            
                            if lati != nil && longi != nil && self.userLocation?.latitude != nil && self.userLocation?.longitude != nil{
                                
                                let startLoc = CLLocation(latitude: lati as! CLLocationDegrees, longitude: longi as! CLLocationDegrees)
                                let endLoc = CLLocation(latitude: (self.userLocation?.latitude)!, longitude: (self.userLocation?.longitude)!)
                                self.drawPath(startLocation: startLoc, endLocation: endLoc)
                            }

                        }
                    }

                    
                } catch {
                    
                    print("JSON serialization failed")
                }
                
                
            } else {
                
                print("ERROR FOUND")
                
            }
            
        }
        
        task.resume()

    }
    
    func drawPath(startLocation: CLLocation, endLocation: CLLocation) {
        
        minTime = 60
        let origin = "\(startLocation.coordinate.latitude),\(startLocation.coordinate.longitude)"
        let destination = "\(endLocation.coordinate.latitude),\(endLocation.coordinate.longitude)"
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=walking&key=AIzaSyDEmH_dSh2GGclN4Uuf1NfH5lY7T0-3VgI"
        
        Alamofire.request(url).responseJSON { response in
            
            
            let json = JSON(data: response.data!)
            
            let routes = json["routes"].arrayValue
            
            if routes.count != 0 {
                
                for route in routes {
                
                    let legs = route["legs"].array
                    
                    for leg in legs! {
                        
                        let steps = leg["steps"].array
                        
                        for step in steps! {
                            
                            let duration = step["duration"]
                            let timeVal = duration["text"].rawString()
                            let intString = timeVal?.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
                            
                            if intString != "" {
                                
                                let minVal = Int(intString!)
                                
                                if minVal! < self.minTime {
                                    
                                    self.minTime = minVal!
                                    self.routeVal = route
                                    
                                }
                                
                            }


                        }
                        
                    }

                    let routeOverviewPolyline = self.routeVal["overview_polyline"].dictionary
                    let points = routeOverviewPolyline?["points"]?.stringValue
                    let path = GMSPath.init(fromEncodedPath: points!)
                    let polyline = GMSPolyline.init(path: path)
                    polyline.strokeWidth = 6
                    polyline.strokeColor = UIColor.blue
                    polyline.map = self.mapView
                    
                    
                }
            }
            
            
        }

    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        
        mapView.selectedMarker = marker
        marker.appearAnimation = GMSMarkerAnimation.pop
        let lati = marker.position.latitude
        let longi = marker.position.longitude
        let startLoc = CLLocation(latitude: lati , longitude: longi )
        let endLoc = CLLocation(latitude: (self.userLocation?.latitude)!, longitude: (self.userLocation?.longitude)!)
        self.drawPath(startLocation: startLoc, endLocation: endLoc)
        
        return true
    }
 
    @IBAction func safeNowButton(_ sender: Any) {
        
        timer2.invalidate()
        safeBtn.backgroundColor = UIColor(red:0.11, green:0.37, blue:0.13, alpha:1.0)
        safeBtn.setTitle("Safe Now", for: .normal)
    }
    
    
    func SMSfunc() {
        
        let msgVC = MFMessageComposeViewController()
        msgVC.body = "Please help me!!!"
        msgVC.recipients = SettingVC.numbers
        msgVC.messageComposeDelegate = self
        self.present(msgVC, animated: true) { 
            
            print("ready to send msgs")
        }
        
        delay(1) {
            
            self.searchInMap()
        }
        
    }
    
    
    func delay(_ time: Double , closure: @escaping () -> () )
    {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC) , execute: closure)
    }
    
    
    func CallFunc(num: String) {
        
        let url = NSURL(string: "tel://\(num)")!
        UIApplication.shared.openURL(url as URL)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func screamFunc() {
        
        highPitchSound.play()
    }
    
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        
        tapFunc()
    }
    
    func tapFunc() {
        
        
        tapImg.isHidden = false
        
        delay(3) {
            
            self.tapImg.isHidden = true
        }
        
        //showErrorAlert(title: "HELPING", msg: "DON'T PANIC")
        safeBtn.backgroundColor = UIColor.red
        safeBtn.setTitle("Press If Safe", for: .normal)
        
        
        let val = SettingVC.numbers.count
        
        if callCounter == 0 {
            
            SMSfunc()
        }
        
        timer2 = Timer.scheduledTimer(timeInterval: TimeInterval(3), target: self, selector: #selector(ExtremeVC.screamFunc), userInfo: nil, repeats: true)

        delay(2) {
            
            if self.callCounter < val {
                
                let number = SettingVC.numbers[self.callCounter]
                self.CallFunc(num: number)
                self.callCounter = self.callCounter + 1
            } else {
                
                self.callCounter = 0
            }
        }
        
    }
    
    @IBAction func slideHelpAction(_ sender: Any) {
        
        tapFunc()
    }
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}
