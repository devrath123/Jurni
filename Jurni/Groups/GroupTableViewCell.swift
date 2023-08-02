//
//  GroupTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 17/02/23.
//

import UIKit

class GroupTableViewCell: UITableViewCell {

    @IBOutlet weak var groupImageView: UIImageView!
  
    @IBOutlet weak var groupName: UILabel!
    @IBOutlet weak var groupMembers: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
