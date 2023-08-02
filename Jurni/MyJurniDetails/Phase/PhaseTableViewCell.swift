//
//  PhaseTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 19/01/23.
//

import UIKit

class PhaseTableViewCell: UITableViewCell {

    @IBOutlet weak var phaseNumberLabel: UILabel!
    @IBOutlet weak var phaseDescriptionLabel: UILabel!
    @IBOutlet weak var phaseStepCountLabel: UILabel!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var phaseArrowOne: UIImageView!
    @IBOutlet weak var phaseArrowTwo: UIImageView!
    @IBOutlet weak var phaseArrowThree: UIImageView!
    @IBOutlet weak var phaseArrowFour: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
