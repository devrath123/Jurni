//
//  ChatTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 11/05/23.
//

import UIKit

class ChatTableViewCell: UITableViewCell {

    @IBOutlet weak var chatImageView: UIImageView!
    @IBOutlet weak var chatTitle: UILabel!
    @IBOutlet weak var chatDesc: UILabel!
    @IBOutlet weak var chatUser: UILabel!
    @IBOutlet weak var unreadChatImageView: UIImageView!
    @IBOutlet weak var chatOptionsImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
