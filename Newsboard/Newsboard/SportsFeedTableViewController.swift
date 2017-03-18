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

class SportsFeedTableViewController: UITableViewController, MFMessageComposeViewControllerDelegate {

    var searchArray: [String]?
    var managedObjectContext: NSManagedObjectContext? = AppDelegate.managedObjectContext
    
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
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        if result.rawValue == MessageComposeResult.cancelled.rawValue || result.rawValue == MessageComposeResult.failed.rawValue ||  result.rawValue == MessageComposeResult.sent.rawValue {
            self.dismiss(animated: true, completion: nil)
        } 
    }
    
    
    @IBAction func saveContentsAsFile(_ sender: UIBarButtonItem) {
        let docDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let filePath = docDirectory + "\\Favorite_Teams"
        let manager = FileManager.default
        let data = NSMutableData()
        for string in searchArray! {
            data.append(string.data(using: String.Encoding.utf8)!)
        }
        if manager.fileExists(atPath: filePath) {
            try! manager.removeItem(atPath: filePath)
            manager.createFile(atPath: filePath, contents: data as Data, attributes: nil)
        } else {
            manager.createFile(atPath: filePath, contents: data as Data, attributes: nil)
        }
        
        if MFMessageComposeViewController.canSendText(){
            if MFMessageComposeViewController.canSendAttachments() {
                let message = MFMessageComposeViewController()
                message.messageComposeDelegate = self
                message.recipients = ["4143392150"] // MY PHONE NUMBER
                message.body = "My favorite teams are attached: "
                if message.addAttachmentData(data as Data, typeIdentifier: "public.data", filename: "Favorite_Teams") {
                    self.present(message, animated: true, completion: nil)
                }
            }
            else {
                presentErrorAlert("Unable to text attachment")
            }
        } else {
            presentErrorAlert("Unable to text on device")
        }
    }
    
    func presentErrorAlert(_ text: String){
        let alert = UIAlertController(
            title: text,
            message: ":(",
            preferredStyle: UIAlertControllerStyle.alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
