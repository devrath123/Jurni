//
//  JurniChapterTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 03/02/23.
//

import UIKit

class JurniChapterTableViewCell: UITableViewCell {

    @IBOutlet weak var chapterNameLabel: UILabel!
    @IBOutlet weak var chapterImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
