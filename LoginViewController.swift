//
//  LoginViewController.swift
//  Newsboard
//
//  Created by Kern Khanna on 2/22/17.
//  Copyright © 2017 Kern Khanna. All rights reserved.
//

import Foundation
import FirebaseAuth
import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Avenir Next", size: 18)!,  NSForegroundColorAttributeName: UIColor.white]
        
        //CHANGE: If user is not logged in, redirect to signin page via segue identifier
        //if (PFUser.currentUser() != nil) {
        //    self.performSegueWithIdentifier("returnToSportsFeed", sender: self)
        //}
      
        usernameField.delegate = self
        passwordField.delegate = self
    }

    
    
    @IBAction func loginAction(sender: AnyObject) {
        let username = self.usernameField.text
        let password = self.passwordField.text
        if ((username?.characters.count)! < 6 || (password?.characters.count)! < 6) {
            let alert = UIAlertView(title: "Invalid", message: "Username must be greater than 4 and password must be greater than 5", delegate: self, cancelButtonTitle: "OK")
            alert.show()
        } else {
            FIRAuth.auth()?.signIn(withEmail: username!, password: password!, completion: {(user, error) in
                    if (error != nil) {
                        print(error);
                        return;
                    } else{
                        let alert = UIAlertView(title: "Success", message: "Logged in!", delegate: self, cancelButtonTitle: "OK")
                        alert.show()
                        self.performSegue(withIdentifier: "returnToSportsFeed", sender: self)
                    }
                } )
        }
    }
    
    @IBAction func signupAction(sender: AnyObject) {
        self.performSegue(withIdentifier: "displaySportsfeedSignupPage", sender: self)
    }
    
    
    @IBAction func returnToSportsFeed(sender: AnyObject) {
        self.performSegue(withIdentifier: "returnToSportsFeed", sender: self)
    }
    
    
    func welcomeBackUser() {
        let welcomeBack = UIAlertView(title: "Welcome back!", message: "", delegate: self, cancelButtonTitle: "OK")
        welcomeBack.show()
    }
    
    
    func informUserUsernameExists() {
        let alert = UIAlertView(title: "User Exists", message: "Username already registered", delegate: self, cancelButtonTitle: "OK")
        alert.show()
    }
    
    
}
