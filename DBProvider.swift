//
//  DBProvider.swift
//  Women Security
//
//  Created by Devesh kataria on 21/05/17.
//  Copyright © 2017 Devesh kataria. All rights reserved.
//

import Foundation
import FirebaseDatabase

class DBProvider {
    
    private static let _instance = DBProvider()
    
    static var Instance: DBProvider {
        
        return _instance
    }
    
    var dbRef: FIRDatabaseReference {
        
        return FIRDatabase.database().reference()
    }
    
    var userRef: FIRDatabaseReference {
        
        return dbRef.child(Constants.USER)
    }
    
    func saveUser(withID: String, email: String, isOnline: String) {
        
        let data: Dictionary<String, Any> = [Constants.EMAIL: email, Constants.ONLINE: isOnline]
        userRef.child(withID).setValue(data)
        
    }
}
