//
//  NearByLocation.swift
//  Women Security
//
//  Created by Devesh kataria on 23/05/17.
//  Copyright © 2017 Devesh kataria. All rights reserved.
//

import Foundation


class NearByLocation {
    
    private var _name: String!
    private var _open_now: Int!
    private var _lati: String!
    private var _longi: String!
    private var _address: String!
    
    var name: String {
        
        return _name
    }
    
    var open_now: Int {
        
        return _open_now
    }
    
    var lati: String {
        
        return _lati
    }
    
    var longi: String {
        
        return _longi
    }
    
    var address: String {
        
        return _address
    }
    
    init(name: String, open_now: Int, lati: String, longi: String, address: String) {
        
        self._name = name
        self._open_now = open_now
        self._lati = lati
        self._longi = longi
        self._address = address
    }
    
}
