//
//  UpdatePaymentTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 20/12/22.
//

import UIKit

class UpdatePaymentTableViewCell: UITableViewCell {

    @IBOutlet weak var cardType: UILabel!
    @IBOutlet weak var lastFour: UILabel!
    @IBOutlet weak var action: UILabel!
    @IBOutlet weak var removeBtn: UIButton!
    
    @IBOutlet weak var removeAction: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
