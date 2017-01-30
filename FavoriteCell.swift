//
//  FavoriteCell.swift
//  Newsboard
//
//

import UIKit

class FavoriteCell: UITableViewCell {
    var name: String?{
        didSet {
            loadCell()
        }
    }
    
    private func loadCell() {
        teamName.text = name
    }
    
    @IBOutlet weak var teamName: UILabel!
    
}
