//
//  AppDelegate.swift
//  Women Security
//
//  Created by Devesh kataria on 26/04/17.
//  Copyright © 2017 Devesh kataria. All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleMaps
import GooglePlaces
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var interval: Double!
    var victim: CKRecordValue!
    var handleNoti = MapVC()
    var lati: Double!
    var longi: Double!
    var Mylati: Double!
    var Mylongi: Double!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let notificationSettings = UIUserNotificationSettings(types: [.badge, .alert, .sound], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
        UIApplication.shared.registerForRemoteNotifications()
        
        FIRApp.configure()
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        GMSServices.provideAPIKey("AIzaSyBBURsw8FErSKTZZ5UkpHDnU2uYic6Jo2U")
        GMSPlacesClient.provideAPIKey("AIzaSyBBURsw8FErSKTZZ5UkpHDnU2uYic6Jo2U")
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        
        fetchHelp()
        
        let cloudkitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String: NSObject])
        
        if cloudkitNotification.notificationType == CKNotificationType.query {
            
            DispatchQueue.main.async(execute: { 
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "performReload"), object: nil)
            })

        }
    }
    
    func resetBadge() {
        
        let badgeReset = CKModifyBadgeOperation(badgeValue: 0)
        badgeReset.modifyBadgeCompletionBlock = { (error) -> Void in
            
            if error == nil {
                
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
            
        }
        
        CKContainer.default().add(badgeReset)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {

        fetchHelp()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
        fetchHelp()
        DispatchQueue.main.async(execute: {
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "performReload"), object: nil)
        
        })
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        fetchHelp()
        resetBadge()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        
        return handled
    }

    func fetchHelp() {
        
        let container = CKContainer.default()
        let publicDatabase = container.publicCloudDatabase
        let predicate = NSPredicate(format: "TRUEPREDICATE", argumentArray: nil)
        let query = CKQuery(recordType: "help", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.desiredKeys = ["content"]
        
        publicDatabase.perform(query, inZoneWith: nil) { (results, error) -> Void in
            
            if error != nil {
                
                
            } else {
                
                self.interval = -8000
                
                for result in results! {
                    
                    print("jai maata \(result.recordID)")
                    let geoFenc = result.object(forKey: "content") as! String
                    
                    if FIRAuth.auth()?.currentUser?.uid != nil {
                        
                        DataService.ds.REF_USERS.child((FIRAuth.auth()?.currentUser?.uid)!).child("latitude").observeSingleEvent(of: .value, with: { (snapshot) in
                            
                            self.Mylati = snapshot.value as! Double
                            
                        })
                        
                        DataService.ds.REF_USERS.child((FIRAuth.auth()?.currentUser?.uid)!).child("longitude").observeSingleEvent(of: .value, with: { (snapshot) in
                            
                            self.Mylongi = snapshot.value as! Double
                            
                        })
                        
                        DataService.ds.REF_USERS.child(geoFenc).child("latitude").observeSingleEvent(of: .value, with: { (snapshot) in
                            
                            self.lati = snapshot.value as! Double
                            
                        })
                        
                        DataService.ds.REF_USERS.child(geoFenc).child("longitude").observeSingleEvent(of: .value, with: { (snapshot) in
                            
                            
                            self.longi = snapshot.value as! Double
                            
                        })
                        
                    }
                    
                    
                    
                    //print("dev \(self.lati) \(self.longi)")
                    //print("bhumi \(self.Mylati) \(self.Mylongi)")
                    
                    if self.lati != nil && self.longi != nil && self.Mylati != nil && self.Mylongi != nil {
                       
                        if (self.lati + 0.02) > (self.Mylati) && (self.lati - 0.02) < (self.Mylati) && (self.longi + 0.02) > (self.Mylongi) && (self.longi - 0.02) < (self.Mylongi) {
                            
                            let timeInter = Double((result.creationDate?.timeIntervalSinceNow)!)
                            
                            if  timeInter > -900 {
                                
                                if timeInter > self.interval {
                                    
                                    self.interval = timeInter
                                    self.victim = result.object(forKey: "content")
                                }
                            }
                            
                        }
                        
                        if self.victim != nil {
                            
                            self.handleNoti.handleNotification(victim: self.victim as! String)
                        }

                    }
                        
                }

                /*OperationQueue.main.addOperation({ () -> Void in
                    
                })*/
            }
        }
    }
    
    
}

