//
//  SIngleSportTableViewCell.swift
//  Newsboard
//
//

import UIKit

class SingleSportTableViewCell: UITableViewCell {
    var name: String?{
        didSet {
            loadCell()
        }
    }
    
    fileprivate func loadCell() {
        sportsName.text = name
    }
    
    @IBOutlet weak var sportsName: UILabel!
}
