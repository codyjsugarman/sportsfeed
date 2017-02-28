/
//  SignupViewController.swift
//  Newsboard
//
//  Created by Kern Khanna on 2/22/17.
//  Copyright © 2017 Kern Khanna. All rights reserved.
//

import Foundation
import UIKit

class SignupViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        usernameField.delegate = self
        passwordField.delegate = self
    }
    
    private func textFieldDidBeginEditing(textField: UITextField) {
        animateViewMoving(up: true, moveValue: 150)
    }
    
    private func textFieldDidEndEditing(textField: UITextField) {
        animateViewMoving(up: false, moveValue: 150)
    }
    
    func animateViewMoving (up:Bool, moveValue :CGFloat){
        let movementDuration:TimeInterval = 0.3
        let movement:CGFloat = ( up ? -moveValue : moveValue)
        UIView.beginAnimations( "animateView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration )
        self.view.frame = self.view.frame.offsetBy(dx: 0,  dy: movement)
        UIView.commitAnimations()
    }
    
    
    func usernameExists(username: String) -> Bool {
        //Check if username exists - if so, give warning and return false
        return false
    }
    
    
    func informUserUsernameExists() {
        let alert = UIAlertView(title: "User Exists", message: "Username already registered", delegate: self, cancelButtonTitle: "OK")
        alert.show()
    }
    
    func signupNewRallyUser() {
        //Create new user account
        let alert = UIAlertView(title: "Success", message: "Signed up!", delegate: self, cancelButtonTitle: "OK")
        alert.show()
        self.performSegue(withIdentifier: "returnToSportsFeed", sender: self)
    }
    
    @IBAction func signupAction(sender: AnyObject) {
        if (usernameExists(username: self.usernameField.text!)) {
            return
        }
        
        // Username/password error checking
        if ((self.usernameField.text?.characters.count)! < 4 || (self.passwordField.text?.characters.count)! < 5) {
            let alert = UIAlertView(title: "Invalid Credentials", message: "Username and password must be greater than 5 characters", delegate: self, cancelButtonTitle: "OK")
            alert.show()
            return
            
            //Successful signup
        } else {
            signupNewRallyUser()
        }
    }
}
