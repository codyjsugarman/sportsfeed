//
//  SportsFeedViewController.swift
//  Newsboard
//
//  Created by Kern Khanna on 3/22/17.
//  Copyright © 2017 Kern Khanna. All rights reserved.
//

import UIKit
import MessageUI
import CoreLocation
import CoreData
import FirebaseAuth
import FirebaseDatabase
import FirebaseAnalytics

class SportsFeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,
UITableViewDataSource, UITableViewDelegate{

    var rootRef : FIRDatabaseReference!
    var messagesRef: FIRDatabaseReference!
    var searchArray: [String]?
    var searchIDArray: [String]?
    var textArray: [String]?
    private var userRefHandle: FIRDatabaseHandle?
    
    @IBOutlet weak var commentsTableView: UITableView!
    
    @IBOutlet weak var teamCollectionView: UICollectionView!
    @IBOutlet weak var welcomeLabel: UILabel!
    
    override func viewDidLoad() {
        if FIRAuth.auth()?.currentUser != nil {
        } else {
            redirectToLogin()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.textArray = []
        let defaults = UserDefaults.standard
        if let obj = defaults.object(forKey: "favorites") {
            searchArray = obj as? [String]
        }
        if let obj = defaults.object(forKey: "favoriteID") {
            searchIDArray = obj as? [String]
        } else {
            searchArray = []
            searchIDArray = []
        }
        /**
        let group = DispatchGroup()
        group.enter()
        let userRefHandle = userQuery.observeSingleEvent(of: .value, with: { (snapshot) in
            let userData = snapshot.value as! Dictionary<String, String>
            if let id = userData["userId"] as String! {
                if id == FIRAuth.auth()?.currentUser?.uid {
                    self.welcomeLabel.text = "Welcome " + userData["username"]! + "!"
       
                    return
                }
            }
        }) {
            (error) in print(error.localizedDescription)
        }
        group.wait()
        **/
        updateTableViewText()
        teamCollectionView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        rootRef.removeObserver(withHandle: userRefHandle!)
    }
    
    private func updateTableViewText(){
        rootRef = FIRDatabase.database().reference()
        messagesRef  = self.rootRef.child("messages")
        let userQuery = messagesRef.queryOrdered(byChild: "senderId")
        let bQueue = DispatchQueue(label: "test")
        userRefHandle = userQuery.observe(.childAdded, with: { (snapshot) -> Void in
            if (!snapshot.exists()) {
                print("Not Found")
            } else {
                let userData = snapshot.value as? Dictionary<String, Dictionary<String, String>>
                if (userData == nil){
                    print("Type casting does not work")
                    print(self.textArray!)
                    self.commentsTableView.reloadData()
                    return
                } else {
                    let messageDataArray = Array(userData!.values)
                    for messageData in messageDataArray {
                        if let id = messageData["senderId"] as String! {
                            print(FIRAuth.auth()?.currentUser?.uid);
                            print("ID- " + id)
                            if id == FIRAuth.auth()?.currentUser?.uid {
                                self.textArray!.append(messageData["text"]!)
                                self.commentsTableView.reloadData()
                            }
                        }
                    }
                }
            }
 
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchArray!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let name = searchArray![indexPath.row]
        let id = searchIDArray![indexPath.row]
        if let teamCell = cell as? UserProfileCollectionViewCell {
            teamCell.teamName.text = id
            teamCell.teamLogo.image = UIImage(named: id.lowercased())
        }
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.textArray!.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let name = textArray![indexPath.row]
        if let favoriteCell = cell as? FavoriteCell {
            favoriteCell.name = name
        }
        return cell
    }
    
    
    fileprivate var teamData: TeamData?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToTeamProfile" {
            if let pvc = segue.destination as? ProfileViewController {
                if let tData = teamData {
                    pvc.sportsID = tData.teamID
                    pvc.sportsTeamName = tData.teamName
                    pvc.teamLocation = CLLocation(latitude: tData.latitude, longitude: tData.longitude)
                }
            }
        }
        
    }

    @IBAction func logOutUser(_ sender: UIBarButtonItem) {
        if FIRAuth.auth()?.currentUser != nil {
            do {
                try FIRAuth.auth()?.signOut()
                self.performSegue(withIdentifier: "redirectToSignupFromTeams", sender: self)
                let alert = UIAlertView(title: "Logged Out", message: "Logged Out", delegate: self, cancelButtonTitle: "OK")
                alert.show()
            } catch let error as Error {
                print(error.localizedDescription)
            }
        }
    }
    
    func redirectToLogin() {
        self.performSegue(withIdentifier: "redirectToSignupFromTeams", sender: self)
        let promptLogin = UIAlertView(title: "Login Required", message: "Please login to view the Sportsfeed", delegate: self, cancelButtonTitle: "OK")
        promptLogin.show()
    }

}
