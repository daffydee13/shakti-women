//
//  ViewController.swift
//  Women Security
//
//  Created by Devesh kataria on 26/04/17.
//  Copyright © 2017 Devesh kataria. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import Firebase
import LocalAuthentication
import CloudKit

class ViewController: UIViewController {

    var pId = ""
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var nickNameField: UITextField!

    
    var verificationTimer = Timer()
    var nickName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FIRDatabase.database().persistenceEnabled = true
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        setupCloudKitSubscription()

        DispatchQueue.main.async(execute: {
            
            NotificationCenter.default.addObserver(self, selector: #selector(ViewController.dismissKeyboard), name: NSNotification.Name(rawValue: "performReload"), object: nil)
        })
    }
    
    func setupCloudKitSubscription() {
        
        let userDefaults = UserDefaults.standard
        
        if userDefaults.bool(forKey: "subscribed") == false {
            
            let predicate = NSPredicate(format: "TRUEPREDICATE", argumentArray: nil)
            let subscription = CKQuerySubscription(recordType: "help", predicate: predicate, options: .firesOnRecordCreation)
            
            let notificationInfo = CKNotificationInfo()
            notificationInfo.alertLocalizationKey = "HELP"
            notificationInfo.shouldBadge = true
            
            subscription.notificationInfo = notificationInfo
            
            let publicData = CKContainer.default().publicCloudDatabase
            publicData.save(subscription) { (subscription, error) in
                
                if error != nil {
                    
                    print("message not sent")
                } else {
                    
                    userDefaults.set(true, forKey: "subscribed")
                    userDefaults.synchronize()
                }
            }
        }
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if UserDefaults.standard.value(forKey: KEY_UID) != nil {
            
            self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
        }
    }

    @IBAction func facebookLogin(sender: UIButton) {
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["public_profile", "email"], from: self) { (result, error) in
            
            if let error = error {
                print("Failed to login: \(error.localizedDescription)")
                return
            }
            
            guard let accessToken = FBSDKAccessToken.current() else {
                print("Failed to get access token")
                return
            }
            
            let credential = FIRFacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
            
            FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
                if error != nil {
                    
                    self.showErrorAlert(title: "Login Error", msg: (error?.localizedDescription)!)
                    
                } else {
                    
                    
                    let user = [ "name": user?.displayName, "email": user?.email, "isOnline": "yes", "phone": "100"]
                    let uid = FIRAuth.auth()?.currentUser?.uid
                    DataService.ds.REF_USERS.child(uid!).observeSingleEvent(of: .value, with: { snapshot in
                        
                        if snapshot.exists() {
                            
                            
                        } else {
                            
                            DataService.ds.createFirebaseUser(uid: (FIRAuth.auth()?.currentUser?.uid)! , user: user )
                        }
                        
                        UserDefaults.standard.set(FIRAuth.auth()?.currentUser?.uid, forKey: KEY_UID)
                        self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                    })
                }
                
                
            })
            
        }
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= 40
                
            }
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if ((notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += 40
                
            }
        }
    }
    
    @IBAction func forgotPassword(_ sender: Any) {
        
        FIRAuth.auth()?.sendPasswordReset(withEmail: emailTextField.text!) { (error) in
            
            if error != nil {
                
                if error?._code == NO_NETWORK {
                    
                    self.showErrorAlert(title: "Network Problem.", msg: "Check your internet connection")
                    
                } else if error?._code == STATUS_ACCOUNT_NOTEXIST {
                    
                    self.showErrorAlert(title: "Account does not exist", msg: "Create new account")
                    
                } else if error?._code == INVALID_EMAIL {
                    
                    self.showErrorAlert(title: "Invalid email ID", msg: "Enter valid email ID")
                    
                }
                
            } else {
                
                self.showErrorAlert(title: "Password reset link has been sent", msg: "Reset your password")
            }
            
        }
    }
    
    func touchIDCall() {
        
        let authContext: LAContext = LAContext()
        var error: NSError?
        
        if authContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            
            authContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authentication", reply: { (wasSuccessful, error) in
                
                if wasSuccessful {
                    
                    self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                    
                } else {
                    
                    
                }
                
            })
            
        } else {
            
            self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
        }
        
    }
    
    func showErrorAlert(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func loginAttempt(_ sender: Any) {
        
        if let email = emailTextField.text, email != "" , let pwd = passwordTextField.text, pwd != "", let nick = nickNameField.text, nick != "", nick.characters.count >= 4 {
            
            
            if pwd.characters.count < 8 {
                
                self.showErrorAlert(title: "Password length min 8 characters", msg: "Try again")
                
            } else {
                
                FIRAuth.auth()?.signIn(withEmail: email, password: pwd) { (authData, error) in
                    
                    if error != nil {
                        
                        print(error!._code)
                        
                        if error?._code == NO_NETWORK {
                            
                            self.showErrorAlert(title: "Network Problem.", msg: "Check your internet connection")
                        }
                        
                        if error?._code == STATUS_ACCOUNT_NOTEXIST {
                            
                            if FIRAuth.auth()?.currentUser != nil {
                                
                                do {
                                    try FIRAuth.auth()?.signOut()
                                    self.showErrorAlert(title: "Signed Out", msg: "Successfully Signed Out")
                                } catch let signOutError as NSError {
                                    print ("Error signing out: %@", signOutError)
                                }
                                
                            } else {
                                
                                FIRAuth.auth()?.createUser(withEmail: email, password: pwd) { (user, error) in
                                    
                                    if error != nil {
                                        
                                        self.showErrorAlert(title: "Could not create account.", msg: "Try something else")
                                        
                                    } else {
                                        
                                        FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: nil)
                                        
                                            
                                            FIRAuth.auth()?.currentUser?.sendEmailVerification(completion: { (error) in
                                                
                                                if error != nil {
                                                    
                                                    self.showErrorAlert(title: "Something went wrong.", msg: "Try again later")
                                                    
                                                } else {
                                                    
                                                    self.showErrorAlert(title: "Verify your account.", msg: "Email Verification Sent.")
                                                    self.verificationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.checkIfTheEmailIsVerified) , userInfo: nil, repeats: true)
                                                    
                                                }
                                            })
                                        
                                    }
                                    
                                }
                                
                            }
                            
                        }
                        
                        if error?._code == INVALID_EMAIL {
                            
                            self.showErrorAlert(title: "Invalid email ID", msg: "Enter valid email ID")
                        }
                        
                        if error?._code == WRONG_PASSWORD {
                            
                            self.showErrorAlert(title: "WRONG PASSWORD", msg: "Try again")
                        }
                        
                        
                    } else if FIRAuth.auth()?.currentUser?.isEmailVerified == true{
                        
                        UserDefaults.standard.set(FIRAuth.auth()?.currentUser?.uid, forKey: KEY_UID)
                        self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                        
                        
                    } else {
                        
                        self.showErrorAlert(title: "Email not verified", msg: "Verify your email")
                        FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: nil)
                        
                        FIRAuth.auth()?.currentUser?.sendEmailVerification(completion: { (error) in
                            
                            if error != nil {
                                
                                self.showErrorAlert(title: "Something went wrong.", msg: "Try again later")
                                
                            } else {
                                
                                self.showErrorAlert(title: "Verify your account.", msg: "Email Verification Sent.")
                                
                                self.verificationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.checkIfTheEmailIsVerified) , userInfo: nil, repeats: true)
                                
                            }
                        })
                    }
                }
                
            }
            
            
        } else {
            
            if let nickName = nickNameField.text, nickName.characters.count < 4 && nickNameField.text != ""{
                
                showErrorAlert(title: "NickName min 4 characters", msg: "Try Again")
                
            } else {
                
                showErrorAlert(title: "Email, Password and NickName Required.", msg: "You must enter email, password and NickName now")
            }
            
        }
        
    }
    
    func checkIfTheEmailIsVerified(){
        
        FIRAuth.auth()?.currentUser?.reload(completion: { (err) in
            if err == nil{
                
                if FIRAuth.auth()?.currentUser != nil {
                    
                    if FIRAuth.auth()!.currentUser!.isEmailVerified{
                        
                        UserDefaults.standard.set(FIRAuth.auth()?.currentUser?.uid, forKey: KEY_UID)
                        let user = [ "name": self.nickNameField.text! as String, "email": self.emailTextField.text!, "isOnline": "yes", "phone": "100"]
                        let uid = FIRAuth.auth()?.currentUser?.uid
                        
                        DataService.ds.REF_USERS.child(uid!).observeSingleEvent(of: .value, with: { snapshot in
                            
                            if snapshot.exists() {
                                
                                self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                                
                            } else {
                                
                                DataService.ds.createFirebaseUser(uid: (FIRAuth.auth()?.currentUser?.uid)! , user: user)
                                self.performSegue(withIdentifier: SEGUE_LOGGED_IN, sender: nil)
                                
                            }
                            
                        })
                        return
                        
                    } else {
                        
                        print("It aint verified yet")
                        
                    }
                    
                }
                
            } else {
                
                print(err?.localizedDescription ?? 0)
                
            }
        })
        
    }
    
    
}

