//
//  PaymentPlanTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 21/12/22.
//

import UIKit

class PaymentPlanTableViewCell: UITableViewCell {

    @IBOutlet weak var transactionName: UILabel!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var cost: UILabel!
    @IBOutlet weak var billingDate: UILabel!
    @IBOutlet weak var action: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
