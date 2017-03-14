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
    
    @IBAction func printTableView(_ sender: UIBarButtonItem) {
        if UIPrintInteractionController.isPrintingAvailable{
            UIGraphicsBeginImageContextWithOptions(view.frame.size, true, 1.0)
            view.layer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            let data = UIImageJPEGRepresentation(image!, 0.7)
            if UIPrintInteractionController.canPrint(data!){
                let printInfo = UIPrintInfo(dictionary: nil)
                printInfo.jobName = (image?.description)!
                printInfo.outputType = .photo
                
                let printController = UIPrintInteractionController.shared
                printController.printInfo = printInfo
                printController.showsNumberOfCopies = false
                printController.printingItem = image
                
                printController.present(animated: true, completionHandler: nil)
            }
        }
    }

    fileprivate let sportsURLs: [String:String] = [
        "NFL" : "http://api.sportradar.us/nfl-t1/teams/hierarchy.xml?api_key=uj5gmqyvhw76g7sgpd9s8s5k",
    ]
    
    var cSport: String? {
        didSet {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            if CLLocationManager.authorizationStatus() == .notDetermined {
               locationManager.requestWhenInUseAuthorization()
            }
            
            locationManager.startUpdatingLocation()
            fetchSports()
            tableView.reloadData()
        }
    }
    
    fileprivate let locationManager = CLLocationManager()
    fileprivate var currentLocation: CLLocation?
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error)")
    }
    
    struct teamObject {
        var teamName: String
        var teamID: String
    }

    fileprivate var sportsTeams = [[teamObject]]()
    fileprivate var unsortedTeams = [teamObject]()
    fileprivate
    var recommendedTeam: teamObject?
    fileprivate var selectedLocation = [String:CLLocation]()
    
    let sectionTitle = ["Recommended", "All"]
    
    fileprivate func fetchSports() {
        let sample = URL(string: sportsURLs[cSport!]!)
        let task = URLSession.shared.dataTask(with: sample!, completionHandler: {
            (data, response, error) in
            if error == nil {
                let htmlParser = TFHpple(htmlData: data!)
                let query = "//team"
                if let results = htmlParser?.search(withXPathQuery: query) as? [TFHppleElement] {
                    var minDistance:CLLocationDistance = Double(Int.max)
                    let teams = DispatchGroup()
                    
                    for result in results {
                        let teamID = result.attributes["id"]
                        if let id = teamID as? String {
                            let teamName = String(describing: result.attributes["market"]!) + " " + String(describing: result.attributes["name"]!)
                            let elem = result.children[1] as! TFHppleElement
                            let addr = elem["address"] as! String
                            let zip = elem["zip"] as! String

                            let address = addr + ", " + zip
                            //let address = "One Bills Drive 14127";
                            self.unsortedTeams.append(teamObject(teamName: teamName, teamID: id))
                            teams.enter()
                            CLGeocoder().geocodeAddressString(address, completionHandler: {
                                (placemarks, error) -> Void in
                                if let placemark = placemarks?[0] {
                                    self.selectedLocation[teamName] = placemark.location!
                                    if let distance = self.currentLocation?.distance(from: placemark.location!) {
                                        if distance < minDistance {
                                            minDistance = distance
                                            self.recommendedTeam = teamObject(teamName: teamName, teamID: id)
                                        }
                                    }
                                }
                                teams.leave()
                            })
                        }
                    }
                    teams.notify(queue: DispatchQueue.main, execute: {
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
        }) 
        task.resume()
    }

    // MARK: - Table view data source

    fileprivate var selectedTeamName: String?
    fileprivate var selectedID: String?
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sportsTeams.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sportsTeams[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sportsTeam", for: indexPath)
        let team = sportsTeams[indexPath.section][indexPath.row]
        if let sportCell = cell as? SingleSportTableViewCell {
            sportCell.name = team.teamName
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sportsTeams[section].count != 0 ? sectionTitle[section] : nil
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTeamName = sportsTeams[indexPath.section][indexPath.row].teamName
        selectedID = sportsTeams[indexPath.section][indexPath.row].teamID
        self.performSegue(withIdentifier: "moveToTeamProfile", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "moveToTeamProfile" {
            if let pvc = segue.destination as? ProfileViewController {
                if let context = AppDelegate.managedObjectContext {
                    context.perform{
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
    /**
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        cSport = "NFL";
    }
    **/
}
