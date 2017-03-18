//
//  SportsTableViewController.swift
//  Newsboard
//
//

import UIKit
import FirebaseAuth

class SportsTableViewController: UITableViewController {
    
    var currentSearch: String?
    var sports = ["NFL"]
    
    override func viewDidLoad() {
        if FIRAuth.auth()?.currentUser != nil {
        } else {
            redirectToLogin()
        }
        super.viewDidLoad()
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sports.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sports", for: indexPath)
        let sport = sports[indexPath.row]
        if let sportCell = cell as? SportTableViewCell {
            sportCell.name = sport
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentSearch = sports[indexPath.row]
        self.performSegue(withIdentifier: "ChooseSport", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ChooseSport" {
            if let svc = segue.destination as? SingleSportTableViewController {
                if let cSport = currentSearch {
                    svc.cSport = cSport
                }
            }
        }
    }
    
    func redirectToLogin() {
        self.performSegue(withIdentifier: "redirectToSignupFromFeed", sender: self)
        let promptLogin = UIAlertView(title: "Login Required", message: "Please login to view the Sportsfeed", delegate: self, cancelButtonTitle: "OK")
        promptLogin.show()
    }

}
