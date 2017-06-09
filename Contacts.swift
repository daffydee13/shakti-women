//
//  Contacts.swift
//  Women Security
//
//  Created by Devesh kataria on 30/05/17.
//  Copyright © 2017 Devesh kataria. All rights reserved.
//

import UIKit

class Contacts: UITableViewCell {

    @IBOutlet weak var contactName: UILabel!
    @IBOutlet weak var contactNumber: UILabel!
    @IBOutlet weak var contactPriority: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    
    func configureCell(name: String, number: String, priority: String) {
        
        contactName.text = name
        contactNumber.text = number
        contactPriority.text = priority
    }

    

}
