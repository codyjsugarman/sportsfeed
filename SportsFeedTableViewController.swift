//
//  SportsFeedTableViewController.swift
//  Newsboard
//
//

import UIKit
import MessageUI
import CoreLocation
import CoreData

class SportsFeedTableViewController: UITableViewController, MFMessageComposeViewControllerDelegate {

    var searchArray: [String]?
    var managedObjectContext: NSManagedObjectContext? = AppDelegate.managedObjectContext
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let defaults = NSUserDefaults.standardUserDefaults()
        if let obj = defaults.objectForKey("favorites") {
            searchArray = obj as? [String]
            
        } else {
            searchArray = ["Add some favorite teams"]
        }
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchArray!.count
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        if result.rawValue == MessageComposeResultCancelled.rawValue || result.rawValue == MessageComposeResultFailed.rawValue ||  result.rawValue == MessageComposeResultSent.rawValue {
            self.dismissViewControllerAnimated(true, completion: nil)
        } 
    }
    
    
    @IBAction func saveContentsAsFile(sender: UIBarButtonItem) {
        let docDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let filePath = docDirectory + "\\Favorite_Teams"
        let manager = NSFileManager.defaultManager()
        let data = NSMutableData()
        for string in searchArray! {
            data.appendData(string.dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        if manager.fileExistsAtPath(filePath) {
            try! manager.removeItemAtPath(filePath)
            manager.createFileAtPath(filePath, contents: data, attributes: nil)
        } else {
            manager.createFileAtPath(filePath, contents: data, attributes: nil)
        }
        
        if MFMessageComposeViewController.canSendText(){
            if MFMessageComposeViewController.canSendAttachments() {
                let message = MFMessageComposeViewController()
                message.messageComposeDelegate = self
                message.recipients = ["4143392150"] // MY PHONE NUMBER
                message.body = "My favorite teams are attached: "
                if message.addAttachmentData(data, typeIdentifier: "public.data", filename: "Favorite_Teams") {
                    self.presentViewController(message, animated: true, completion: nil)
                }
            }
            else {
                presentErrorAlert("Unable to text attachment")
            }
        } else {
            presentErrorAlert("Unable to text on device")
        }
    }
    
    func presentErrorAlert(text: String){
        let alert = UIAlertController(
            title: text,
            message: ":(",
            preferredStyle: UIAlertControllerStyle.Alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("favorite", forIndexPath: indexPath)
        let name = searchArray![indexPath.row]
        if let favoriteCell = cell as? FavoriteCell {
            favoriteCell.name = name
        }
        return cell
    }

    private var teamData: TeamData?
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let teamName = searchArray![indexPath.row]
        if let context = managedObjectContext {
            context.performBlockAndWait {
                 self.teamData = TeamData.fetchTeamData(teamName, inManagedObjectContext: context)
            }
            do {
                try context.save()
                self.performSegueWithIdentifier("goToTeamProfile", sender: self)

            } catch let error {
                print("Core Data Error: \(error)")
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "goToTeamProfile" {
            if let pvc = segue.destinationViewController as? ProfileViewController {
                if let tData = teamData {
                    pvc.sportsID = tData.teamID
                    pvc.sportsTeamName = tData.teamName
                    pvc.teamLocation = CLLocation(latitude: tData.latitude, longitude: tData.longitude)
                }
            }
        }
        
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let defaults = NSUserDefaults.standardUserDefaults()
            if let obj = defaults.objectForKey("favorites"){
                searchArray = obj as? [String]
                searchArray?.removeAtIndex(indexPath.row)
                defaults.setObject(searchArray, forKey: "favorites")
            }
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }

}
