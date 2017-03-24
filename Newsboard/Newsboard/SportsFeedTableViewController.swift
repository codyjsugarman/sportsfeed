//
//  SportsFeedTableViewController.swift
//  Newsboard
//
//

import UIKit
import MessageUI
import CoreLocation
import CoreData
import FirebaseAuth
import FirebaseDatabase

class SportsFeedTableViewController: UITableViewController {

    var searchArray: [String]?
    var managedObjectContext: NSManagedObjectContext? = AppDelegate.managedObjectContext
    //var rootRef = FIRDatabase.database().reference()
    //private lazy var teamsRef: FIRDatabaseReference = self.rootRef.child("teams")
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let defaults = UserDefaults.standard
        if let obj = defaults.object(forKey: "favorites") {
            searchArray = obj as? [String]
        } else {
            searchArray = ["Add some favorite teams"]
        }
        tableView.reloadData()
    }

    override func viewDidLoad() {
        //If user not logged in
        if FIRAuth.auth()?.currentUser != nil {
            
        } else {
            redirectToLogin()
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchArray!.count
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "favorite", for: indexPath)
        let name = searchArray![indexPath.row]
        if let favoriteCell = cell as? FavoriteCell {
            favoriteCell.name = name
        }
        return cell
    }

    fileprivate var teamData: TeamData?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let teamName = searchArray![indexPath.row]
        if let context = managedObjectContext {
            context.performAndWait {
                 self.teamData = TeamData.fetchTeamData(teamName, inManagedObjectContext: context)
            }
            do {
                try context.save()
                self.performSegue(withIdentifier: "goToTeamProfile", sender: self)

            } catch let error {
                print("Core Data Error: \(error)")
            }
        }
    }
    
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let defaults = UserDefaults.standard
            if let obj = defaults.object(forKey: "favorites"){
                searchArray = obj as? [String]
                searchArray?.remove(at: indexPath.row)
                defaults.set(searchArray, forKey: "favorites")
            }
            tableView.deleteRows(at: [indexPath], with: .fade)
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
