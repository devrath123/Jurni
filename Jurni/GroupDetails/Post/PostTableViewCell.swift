//
//  PostTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 19/04/23.
//

import UIKit

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var postTimeLabel: UILabel!
    @IBOutlet weak var postTextLabel: UILabel!
    @IBOutlet weak var postImagesStackView: UIView!
    @IBOutlet weak var firstImageView: UIImageView!
    @IBOutlet weak var secondImageView: UIImageView!
    @IBOutlet weak var thirdImageView: UIImageView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var imagesTopView: UIView!
    @IBOutlet weak var imagesBottomView: UIView!
    @IBOutlet weak var moreImageView: UIView!
    @IBOutlet weak var imageCountLabel: UILabel!
    @IBOutlet weak var imageVideoView: UIView!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
