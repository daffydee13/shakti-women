//
//  userInfo.swift
//  Women Security
//
//  Created by Devesh kataria on 21/05/17.
//  Copyright © 2017 Devesh kataria. All rights reserved.
//

import Foundation
import Firebase

class UserInfo {
    
    private var _email: String?
    private var _isOnline: String?
    private var _latitude: Double?
    private var _longitude: Double?
    private var _phone: String?
    private var _name: String?
    private var _userKey: String?
    private var _type: String?
    
    var email: String? {
        return _email
    }
    
    var isOnline: String? {
        return _isOnline
    }
    
    var latitude: Double? {
        return _latitude
    }
    
    var longitude: Double? {
        return _longitude
    }
    
    var phone: String? {
        return _phone
    }
    
    var name: String? {
        return _name
    }
    
    var userKey: String? {
        return _userKey
    }
    
    var type: String? {
        return _type
    }
    
    init(userKey: String, dictionary: Dictionary<String, Any>) {
        
        self._userKey = userKey
        
        if let email = dictionary["email"] as? String {
            
            self._email = email
        }
        
        if let isOnline = dictionary["isOnline"] as? String {
            
            self._isOnline = isOnline
        }
        
        if let latitude = dictionary["latitude"] as? Double {
            
            self._latitude = latitude
        }
        
        if let longitude = dictionary["longitude"] as? Double {
            
            self._longitude = longitude
        }
        
        if let phone = dictionary["phone"] as? String {
            
            self._phone = phone
        }
        
        if let name = dictionary["name"] as? String {
            
            self._name = name
        }
        
        if let type = dictionary["type"] as? String {
            
            self._type = type
        }
    }
}
