//
//  SportsTableViewController.swift
//  Newsboard
//
//

import UIKit

class SportsTableViewController: UITableViewController {
    
    var currentSearch: String?
    var sports = ["NFL"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sports.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("sports", forIndexPath: indexPath)
        let sport = sports[indexPath.row]
        if let sportCell = cell as? SportTableViewCell {
            sportCell.name = sport
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        currentSearch = sports[indexPath.row]
        self.performSegueWithIdentifier("ChooseSport", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ChooseSport" {
            if let svc = segue.destinationViewController as? SingleSportTableViewController {
                if let cSport = currentSearch {
                    svc.cSport = cSport
                }
            }
        }
    }

}
