//
//  UpcomingPaymentTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 21/12/22.
//

import UIKit

class UpcomingPaymentTableViewCell: UITableViewCell {

    @IBOutlet weak var tansactionName: UILabel!
    @IBOutlet weak var cost: UILabel!
    @IBOutlet weak var upcomingBillingDate: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
