//
//  MapVC.swift
//  Women Security
//
//  Created by Devesh kataria on 20/05/17.
//  Copyright © 2017 Devesh kataria. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import Firebase
import GoogleMaps
import CloudKit
import Alamofire
import SwiftyJSON

class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITabBarDelegate, UITabBarControllerDelegate {

    
    @IBOutlet weak var shakeImg: UIImageView!
    @IBOutlet weak var helpIfSafe: ButtonView!
    @IBOutlet weak var onlineSwitch: UISwitch!
    @IBOutlet weak var helpMap: GMSMapView!
    @IBOutlet weak var settingContainer: UIView!
    @IBOutlet weak var extremeHelpContainer: UIView!
    @IBOutlet weak var myTabBar: UITabBar!
    private var locationManager = CLLocationManager()
    private var userLocation: CLLocationCoordinate2D?
    var latitude: Double!
    var longitude: Double!
    var timer = Timer()
    var mapView: GMSMapView!
    var pinImage: UIImage!
    var initCounter = 0
    var arrNotes: Array<CKRecord> = []
    var lati: Double!
    var longi: Double!
    var Mylati: Double!
    var Mylongi: Double!
    var pointsLine = ""
    var timer3 = Timer()
    static var personWhoNeedsHelp = ""
    var helpCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            
            motionFunc()
        }
    }
    
    func motionFunc() {
        
        shakeImg.isHidden = false
        
        delay(3) {
            
            self.shakeImg.isHidden = true
        }
        
        createNoti()
        helpIfSafe.backgroundColor = UIColor.red
        helpIfSafe.setTitle("Press If Safe", for: .normal)
        //showErrorAlert(title: "HELPING", msg: "DON'T PANIC")
    }
    
    func createNoti() {
        
        let newMsg = CKRecord(recordType: "help")
        let uid = FIRAuth.auth()?.currentUser?.uid
        newMsg["content"] = uid! as CKRecordValue
        
        
        let publicData = CKContainer.default().publicCloudDatabase
        publicData.save(newMsg) { (record, error) in
            
            if error == nil {
                
                print("Help saved")
            } else {
                
                print(error?.localizedDescription as Any)
            }
        }
    }
    

    override func viewDidAppear(_ animated: Bool) {
        
        myTabBar.delegate = self
        settingContainer.isHidden = true
        extremeHelpContainer.isHidden = false
        self.view.bringSubview(toFront: extremeHelpContainer)
        self.view.bringSubview(toFront: myTabBar)
        
        DataService.ds.REF_USERS.child((FIRAuth.auth()?.currentUser?.uid)!).child("isOnline").observeSingleEvent(of: .value, with: { (snapshot) in
            
            let val = snapshot.value as! String
            
            if val == "yes" {
                self.onlineSwitch.isOn = true
            } else if val == "no" {
                self.onlineSwitch.isOn = false
            }
        })

        let camera = GMSCameraPosition.camera(withLatitude: 20.5937, longitude: 78.9629, zoom: 4)
        mapView = GMSMapView.map(withFrame: helpMap.bounds, camera: camera)
        helpMap.addSubview(mapView)
        mapView.isMyLocationEnabled = true
        mapView.animate(to: camera)
        mapView.isBuildingsEnabled = true
        
        delay(1) {
            
            self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(10), target: self, selector: #selector(MapVC.addingHelpersToMap), userInfo: nil, repeats: true)
            self.timer3 = Timer.scheduledTimer(timeInterval: TimeInterval(5), target: self, selector: #selector(MapVC.intermediateFunction), userInfo: nil, repeats: true)
            self.initializeLocationManager()
        }
        
        
        
    }

    
    private func initializeLocationManager() {

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
        
        if initCounter == 0 {
            
            addingHelpersToMap()
            mapView.animate(toViewingAngle: 70)
            initCounter = 1
        }
        
        
    }
    
  
    
    func addingHelpersToMap() {

        let position = CLLocationCoordinate2D(latitude: -18.23, longitude: 151.20)
        let marker = GMSMarker(position: position)
        marker.map = self.mapView
        
        mapView.clear()
        
        DataService.ds.addLocationValues(latitude: (userLocation?.latitude)!, longitude: (userLocation?.longitude)!)
        
        if helpCounter != 1 {
            
            let vancouver = CLLocationCoordinate2D(latitude: (self.userLocation?.latitude)!, longitude: (self.userLocation?.longitude)!)
            let vancouverCam = GMSCameraUpdate.setTarget(vancouver)
            self.mapView.animate(with: vancouverCam)
            self.mapView.animate(toViewingAngle: 70)
            self.mapView.animate(toZoom: 16)
        }
        
        DataService.ds.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let snapshots = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snaps in snapshots {
                    
                    print(snaps.key)
                   // print(snaps.value(forKey: "phone"))
                    
                    if let userDict = snaps.value as? Dictionary<String, Any> {
                        
                        let users = UserInfo(userKey: snaps.key, dictionary: userDict)
                        
                        if users.isOnline == "yes" {
                            
                            let lat = users.latitude
                            let long = users.longitude
                            
                            if lat != nil && long != nil {
                                
                                let position = CLLocationCoordinate2D(latitude: lat!, longitude: long!)
                                let marker = GMSMarker(position: position)
                                marker.title = users.name
                                
                                if users.type == "police" {
                                    
                                    self.pinImage = UIImage(named: "police")
                                    
                                } else if users.type == "female" {
                                    
                                    self.pinImage = UIImage(named: "female")
                                    
                                } else if users.type == "male" {
                                    
                                    self.pinImage = UIImage(named: "male")
                                    
                                } else {
                                    
                                    self.pinImage = UIImage(named: "social")
                                }
                                
                                let size = CGSize(width: 50, height: 50)
                                UIGraphicsBeginImageContext(size)
                                self.pinImage!.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                                let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                                UIGraphicsEndImageContext()
                                marker.icon = resizedImage

                                marker.map = self.mapView
                            }
                            
                            
                            
                        } else if users.isOnline == "no" {
                            
                            print("Helper is Offline")
                        }
                        
                    }
                    
                    
                }
            }
            
        })
        
       
    }
    
    @IBAction func onlineOrOffline(_ sender: UISwitch) {
        
        if sender.isOn {
            
          DataService.ds.REF_USERS.child((FIRAuth.auth()?.currentUser?.uid)!).child("isOnline").setValue("yes")
            
        } else {
            
            DataService.ds.REF_USERS.child((FIRAuth.auth()?.currentUser?.uid)!).child("isOnline").setValue("no")
            
        }
        
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
        switch item.tag {
        case 1:
            extremeHelpContainer.isHidden = false
            settingContainer.isHidden = true
            self.view.bringSubview(toFront: extremeHelpContainer)
            self.view.bringSubview(toFront: myTabBar)
            
        case 2:
            extremeHelpContainer.isHidden = true
            settingContainer.isHidden = true
            self.view.bringSubview(toFront: myTabBar)
            
        case 3:
            extremeHelpContainer.isHidden = true
            settingContainer.isHidden = false
            self.view.bringSubview(toFront: settingContainer)
            self.view.bringSubview(toFront: myTabBar)
            
            
        default:
            break;
        }

    }

    
    func handleNotification(victim: String) {
        
        MapVC.personWhoNeedsHelp = victim
        helpCounter = 1
       
    }
    
    func intermediateFunction() {
        
        print("stage1 \(MapVC.personWhoNeedsHelp)")
        if MapVC.personWhoNeedsHelp != "" {
            
            DataService.ds.REF_USERS.child((FIRAuth.auth()?.currentUser?.uid)!).child("latitude").observeSingleEvent(of: .value, with: { (snapshot) in
                
                self.Mylati = snapshot.value as! Double
                
            })
            
            DataService.ds.REF_USERS.child((FIRAuth.auth()?.currentUser?.uid)!).child("longitude").observeSingleEvent(of: .value, with: { (snapshot) in
                
                self.Mylongi = snapshot.value as! Double
                
            })
            
            DataService.ds.REF_USERS.child(MapVC.personWhoNeedsHelp).child("latitude").observeSingleEvent(of: .value, with: { (snapshot) in
                
                self.lati = snapshot.value as! Double
                
            })
            
            DataService.ds.REF_USERS.child(MapVC.personWhoNeedsHelp).child("longitude").observeSingleEvent(of: .value, with: { (snapshot) in
                
                self.longi = snapshot.value as! Double
                
            })
        }
        
        if lati != nil && longi != nil && Mylati != nil && Mylongi != nil{
            
            let startLoc = CLLocation(latitude: lati!, longitude: longi!)
            let endLoc = CLLocation(latitude: Mylati!, longitude: Mylongi!)
            self.drawPath(startLocation: startLoc, endLocation: endLoc)
        }

    }
    
    func drawPath(startLocation: CLLocation, endLocation: CLLocation) {
        
        let origin = "\(startLocation.coordinate.latitude),\(startLocation.coordinate.longitude)"
        let destination = "\(endLocation.coordinate.latitude),\(endLocation.coordinate.longitude)"
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=walking&key=AIzaSyDEmH_dSh2GGclN4Uuf1NfH5lY7T0-3VgI"
        
        Alamofire.request(url).responseJSON { response in
            
            let json = JSON(data: response.data!)
            let routes = json["routes"].arrayValue
            
            if routes.count != 0 {

                let routeVal = routes[0]
                //print("dev \(routeVal)")
                let routeOverviewPolyline = routeVal["overview_polyline"].dictionary
                let points = (routeOverviewPolyline?["points"]?.stringValue)!
                self.pointsLine = points
                //print("BHUMI \(self.pointsLine)")
                let path = GMSPath.init(fromEncodedPath: points)
                let polyline = GMSPolyline.init(path: path)
                polyline.strokeWidth = 6
                polyline.strokeColor = UIColor.red
                polyline.map = self.mapView
                
            }

        }
        
        let vancouver = CLLocationCoordinate2D(latitude: (self.userLocation?.latitude)!, longitude: (self.userLocation?.longitude)!)
        let vancouverCam = GMSCameraUpdate.setTarget(vancouver)
        self.mapView.animate(with: vancouverCam)
        self.mapView.animate(toViewingAngle: 70)
        self.mapView.animate(toZoom: 18)
    }

    func delay(_ time: Double , closure: @escaping () -> () )
    {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(time * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC) , execute: closure)
    }
    @IBAction func pressHelpAction(_ sender: Any) {
        
        helpIfSafe.backgroundColor = UIColor(red:0.11, green:0.37, blue:0.13, alpha:1.0)
        helpIfSafe.setTitle("Safe Now", for: .normal)
        
        let container = CKContainer.default()
        let publicDatabase = container.publicCloudDatabase
        let predicate = NSPredicate(format: "TRUEPREDICATE", argumentArray: nil)
        let query = CKQuery(recordType: "help", predicate: predicate)
        
        publicDatabase.perform(query, inZoneWith: nil) { (results, error) -> Void in
            
            if error != nil {
                
                
            } else {
                
                
                for result in results! {
                    
                    print("jai maata \(result.recordID)")
                    let geoFenc = result.object(forKey: "content") as! String
                    let uid = FIRAuth.auth()?.currentUser?.uid
                    
                    if geoFenc == uid {
                        
                        let selectedRecordID = result.recordID
                        
                        publicDatabase.delete(withRecordID: selectedRecordID, completionHandler: { (recordID, error) -> Void in
                            if error != nil {
                                print("error unable to delete record")
                            } else {
                                
                                print("record deleted")
                            }
                        })
                    }
                    
                }
                
            }
        }
        
        
    }
    
    @IBAction func slideSOSAction(_ sender: Any) {
        
        motionFunc()
    }
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}
