//
//  SettingVC.swift
//  Women Security
//
//  Created by Devesh kataria on 30/05/17.
//  Copyright © 2017 Devesh kataria. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase

class SettingVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var contactName: TextView!
    @IBOutlet weak var contactNumber: TextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var contactPriority: TextView!
    var contacts = ["Police"]
    static var numbers = ["100"]
    var priority = ["1"]
    var block = UITableViewRowAction()
    var priorityCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        tableView.delegate = self
        tableView.dataSource = self
        
        if UserDefaults.standard.value(forKey: "contacts") != nil && UserDefaults.standard.value(forKey: "numbers") != nil && UserDefaults.standard.value(forKey: "priority") != nil {
            
            contacts = UserDefaults.standard.value(forKey: "contacts") as! [String]
            SettingVC.numbers = UserDefaults.standard.value(forKey: "numbers") as! [String]
            priority = UserDefaults.standard.value(forKey: "priority") as! [String]
        }
        
        
    }

    func dismissKeyboard() {
        view.endEditing(true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "contacts") as? Contacts {
            
            cell.configureCell(name: contacts[indexPath.row], number: SettingVC.numbers[indexPath.row], priority: priority[indexPath.row])
            print("bhumi <3 \(priority[indexPath.row])")
            return cell
        } else {
            
            return Contacts()
        }

    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            
            self.contacts.remove(at: indexPath.row)
            SettingVC.numbers.remove(at: indexPath.row)
            self.priority.remove(at: indexPath.row)
            tableView.endEditing(true)
            tableView.reloadData()
            UserDefaults.standard.set(self.contacts, forKey: "contacts")
            UserDefaults.standard.set(SettingVC.numbers, forKey: "numbers")
            UserDefaults.standard.set(self.priority, forKey: "priority")
        }
        
        let call = UITableViewRowAction(style: .normal, title: "Call") { (action, indexPath) in
            
            let num = SettingVC.numbers[indexPath.row]
            let url = NSURL(string: "tel://\(num)")!
            UIApplication.shared.openURL(url as URL)
            
        }
        
        call.backgroundColor = UIColor(red:0.25, green:0.32, blue:0.71, alpha:1.0)
        
        
        return [delete, call]
        
    }
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func addContactAction(_ sender: Any) {
        
        if  contactName.text != ""  && contactNumber.text != "" && contactPriority.text != "" {
            
            for i in priority {
                
                if i == contactPriority.text {
                    showErrorAlert(title: "Priority already assigned", msg: "Try again")
                    priorityCounter = 1
                    
                }
            }
            
            if priorityCounter == 0 {
                
                contacts.append(contactName.text!)
                SettingVC.numbers.append(contactNumber.text!)
                priority.append(contactPriority.text!)
                tableView.reloadData()
                UserDefaults.standard.set(contacts, forKey: "contacts")
                UserDefaults.standard.set(SettingVC.numbers, forKey: "numbers")
                UserDefaults.standard.set(priority, forKey: "priority")
                
                contactName.text = ""
                contactPriority.text = ""
                contactNumber.text = ""
                
            } else {
                
                priorityCounter = 0
            }
            
        } else {
            
            showErrorAlert(title: "Enter valid Name and Phone number", msg: "Try Again")
        }
        
        
        
    }
    
    
}
