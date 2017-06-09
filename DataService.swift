//
//  DataService.swift
//  Women Security
//
//  Created by Devesh kataria on 21/05/17.
//  Copyright © 2017 Devesh kataria. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

let URL_BASE = "https://women-security-55fc2.firebaseio.com"

class DataService {
    
    static let ds = DataService()
    
    private var _REF_BASE = FIRDatabase.database().reference(fromURL: "\(URL_BASE)")
    private var _REF_USERS = FIRDatabase.database().reference(fromURL: "\(URL_BASE)/users")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_USERS: FIRDatabaseReference {
        return _REF_USERS
    }
    
    var REF_USER_CURRENT: FIRDatabaseReference {
        let uid = UserDefaults.standard.value(forKey: KEY_UID) as! String
        let user = FIRDatabase.database().reference(fromURL: "\(URL_BASE)").child("users").child(uid)
        return user
        
    }
    
    func createFirebaseUser(uid: String, user: Dictionary<String, Any>) {
        
        REF_USERS.child(uid).setValue(user)
    }
    
    func saveUser(withID: String, email: String, isOnline: String, name: String, phone: String) {
        
        let data: Dictionary<String, Any> = [EMAIL: email, ISONLINE: isOnline, USER_NAME: name, PHONE: phone]
        
        REF_USERS.child(withID).setValue(data)
    }
    
    func addLocationValues(latitude: Double, longitude: Double) {
        
        //let data: Dictionary<String, Any> = [LATITUDE: latitude, LONGITUDE: longitude]
        
        REF_USERS.child((FIRAuth.auth()?.currentUser?.uid)!).child("latitude").setValue(latitude)
        REF_USERS.child((FIRAuth.auth()?.currentUser?.uid)!).child("longitude").setValue(longitude)
        
    }
    
    
}
