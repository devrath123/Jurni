//
//  CongratsTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 19/01/23.
//

import UIKit

class CongratsTableViewCell: UITableViewCell {

    @IBOutlet weak var congratsLabel: UILabel!
    @IBOutlet weak var congratsArrowOne: UIImageView!
    @IBOutlet weak var congratsArrowTwo: UIImageView!
    @IBOutlet weak var congratsArrowThree: UIImageView!
    @IBOutlet weak var congratsArrowFour: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
