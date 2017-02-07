//
//  SingleSportTableViewController.swift
//  Newsboard
//
//

import UIKit
import CoreLocation
import CoreData

class SingleSportTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    var managedObjectContext: NSManagedObjectContext? = AppDelegate.managedObjectContext
    
    @IBAction func printTableView(sender: UIBarButtonItem) {
        if UIPrintInteractionController.isPrintingAvailable(){
            UIGraphicsBeginImageContextWithOptions(view.frame.size, true, 1.0)
            view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let data = UIImageJPEGRepresentation(image, 0.7)
            if UIPrintInteractionController.canPrintData(data!){
                let printInfo = UIPrintInfo(dictionary: nil)
                printInfo.jobName = image.description
                printInfo.outputType = .Photo
                
                let printController = UIPrintInteractionController.sharedPrintController()
                printController.printInfo = printInfo
                printController.showsNumberOfCopies = false
                printController.printingItem = image
                
                printController.presentAnimated(true, completionHandler: nil)
            }
        }
    }

    private let sportsURLs: [String:String] = [
        "NFL" : "http://api.sportradar.us/nfl-t1/teams/hierarchy.xml?api_key=uj5gmqyvhw76g7sgpd9s8s5k",
    ]
    
    var cSport: String? {
        didSet {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            if CLLocationManager.authorizationStatus() == .NotDetermined {
               locationManager.requestWhenInUseAuthorization()
            }
            
            locationManager.startUpdatingLocation()
            fetchSports()
            tableView.reloadData()
        }
    }
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error: \(error)")
    }
    
    struct teamObject {
        var teamName: String
        var teamID: String
    }

    private var sportsTeams = [[teamObject]]()
    private var unsortedTeams = [teamObject]()
    private
    var recommendedTeam: teamObject?
    private var selectedLocation = [String:CLLocation]()
    
    let sectionTitle = ["Recommended", "All"]
    
    private func fetchSports() {
        let sample = NSURL(string: sportsURLs[cSport!]!)
        let task = NSURLSession.sharedSession().dataTaskWithURL(sample!) {
            (data, response, error) in
            if error == nil {
                let htmlParser = TFHpple(HTMLData: data!)
                let query = "//team"
                if let results = htmlParser.searchWithXPathQuery(query) as? [TFHppleElement] {
                    var minDistance:CLLocationDistance = Double(Int.max)
                    let teams = dispatch_group_create()
                    
                    for result in results {
                        let teamID = result.attributes["id"]
                        if let id = teamID as? String {
                            let teamName = String(result.attributes["market"]!) + " " + String(result.attributes["name"]!)
                            let addr = result.children[1]["address"] as! String
                            let zip = result.children[1]["zip"] as! String
                            let address = addr + ", " + zip
                            self.unsortedTeams.append(teamObject(teamName: teamName, teamID: id))
                            dispatch_group_enter(teams)
                            CLGeocoder().geocodeAddressString(address, completionHandler: {
                                (placemarks, error) -> Void in
                                if let placemark = placemarks?[0] {
                                    self.selectedLocation[teamName] = placemark.location!
                                    if let distance = self.currentLocation?.distanceFromLocation(placemark.location!) {
                                        if distance < minDistance {
                                            minDistance = distance
                                            self.recommendedTeam = teamObject(teamName: teamName, teamID: id)
                                        }
                                    }
                                }
                                dispatch_group_leave(teams)
                            })
                        }
                    }
                    dispatch_group_notify(teams, dispatch_get_main_queue(), {
                        if let team = self.recommendedTeam {
                            self.sportsTeams.append([team])
                        } else {
                            self.sportsTeams.append([])
                        }
                        self.sportsTeams.append(self.unsortedTeams)
                        self.tableView.reloadData()
                    })
                }
            }
            self.tableView.reloadData()
        }
        task.resume()
    }

    // MARK: - Table view data source

    private var selectedTeamName: String?
    private var selectedID: String?
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sportsTeams.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sportsTeams[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("sportsTeam", forIndexPath: indexPath)
        let team = sportsTeams[indexPath.section][indexPath.row]
        if let sportCell = cell as? SingleSportTableViewCell {
            sportCell.name = team.teamName
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sportsTeams[section].count != 0 ? sectionTitle[section] : nil
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedTeamName = sportsTeams[indexPath.section][indexPath.row].teamName
        selectedID = sportsTeams[indexPath.section][indexPath.row].teamID
        self.performSegueWithIdentifier("moveToTeamProfile", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "moveToTeamProfile" {
            if let pvc = segue.destinationViewController as? ProfileViewController {
                if let context = AppDelegate.managedObjectContext {
                    context.performBlock{
                        TeamData.getTeamData(self.selectedTeamName!, teamID: self.selectedID!, teamLocation: self.selectedLocation[self.selectedTeamName!]!, inManagedObjectContext: context)
                    }
                    do {
                        try context.save()
                    } catch let error {
                        print("Core Data Error: \(error)")
                    }
                }
                
                pvc.sportsID = selectedID!
                pvc.sportsTeamName = selectedTeamName!
                pvc.teamLocation = selectedLocation[selectedTeamName!]
            }
        }
    }
    
    
}
