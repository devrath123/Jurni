//
//  EditImageCell.swift
//  Jurni
//
//  Created by Yatharth Singh on 11/10/23.
//

import UIKit

class EditImageCell: UITableViewCell {
    
    @IBOutlet weak var avtarImageView: UIImageView!
    @IBOutlet weak var deleteImageBtn: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
