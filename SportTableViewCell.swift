//
//  SportTableViewCell.swift
//  Newsboard
//
//

import UIKit

class SportTableViewCell: UITableViewCell {
    
    var name: String?{
        didSet {
            loadCell()
        }
    }
    
    fileprivate func loadCell() {
        sportsName.text = name
        sportsLogo.image = UIImage(named: name!)
    }

    @IBOutlet weak var sportsName: UILabel!
    @IBOutlet weak var sportsLogo: UIImageView!
}
