//
//  GroupMembersTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 10/07/23.
//

import UIKit

class GroupMembersTableViewCell: UITableViewCell {

    @IBOutlet weak var groupImageView: UIImageView!
    @IBOutlet weak var groupInitialLabel: UILabel!
    @IBOutlet weak var groupMemberNameLabel: UILabel!
    @IBOutlet weak var groupMemberEmailLabel: UILabel!
    @IBOutlet weak var groupMemberDeleteButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
