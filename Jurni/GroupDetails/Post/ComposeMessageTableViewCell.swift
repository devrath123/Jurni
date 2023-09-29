//
//  ComposeMessageTableViewCell.swift
//  Jurni
//
//  Created by Yatharth Singh on 27/09/23.
//

import UIKit

class ComposeMessageTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var collectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var avtarImageView: UIImageView!
    @IBOutlet var writeSomthingTextView: UITextField!
    @IBOutlet weak var imgView: UIView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var uploadPhotoBtn: UIButton!
    @IBOutlet weak var uploadVideoBtn: UIButton!
    @IBOutlet weak var publishBtn: UIButton!
    @IBOutlet weak var photoCollectionView: UICollectionView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
