//
//  MyJurniTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 10/01/23.
//

import UIKit

class MyJurniTableViewCell: UITableViewCell {

    @IBOutlet weak var myJurniImageView: UIImageView!
    @IBOutlet weak var myJurniTitle: UILabel!
    @IBOutlet weak var membersLabel: UILabel!
    @IBOutlet weak var activeGroupsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
