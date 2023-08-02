//
//  StepTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 19/01/23.
//

import UIKit

class StepTableViewCell: UITableViewCell {

    @IBOutlet weak var stepTitleLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var lockImageView: UIImageView!
    @IBOutlet weak var yourProgressLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var stepView: UIView!
    @IBOutlet weak var stepArrrowOne: UIImageView!
    @IBOutlet weak var stepArrowTwo: UIImageView!
    @IBOutlet weak var stepArrowThree: UIImageView!
    @IBOutlet weak var stepArrowFour: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
