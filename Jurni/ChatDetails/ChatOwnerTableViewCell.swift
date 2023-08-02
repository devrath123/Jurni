//
//  ChatOwnerTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 08/06/23.
//

import UIKit

class ChatOwnerTableViewCell: UITableViewCell {

    @IBOutlet weak var chatOwnerNameLabel: UILabel!
    @IBOutlet weak var chatOwnerMessageLabel: UILabel!
    @IBOutlet weak var chatOwnerMessageDateLabel: UILabel!
    @IBOutlet weak var chatOwnerView: UIView!
    @IBOutlet weak var chatOwnerParentView: UIView!
    @IBOutlet weak var chatOwnerImageView: UIImageView!
    @IBOutlet weak var chatOwnerAudioView: UIView!
    @IBOutlet weak var chatOwnerPlayPauseButton: UIButton!
    @IBOutlet weak var chatOwnerTimerLabel: UILabel!
    @IBOutlet weak var chatOwnerHorizontalSlider: UISlider!
    @IBOutlet weak var smileysView: UIView!
    @IBOutlet weak var chatOwnerShowSmileysButton: UIButton!
    @IBOutlet weak var smileysImageView: UIImageView!
    @IBOutlet weak var thumbsUpButton: UIButton!
    @IBOutlet weak var loveButton: UIButton!
    @IBOutlet weak var happyButton: UIButton!
    @IBOutlet weak var surpriseButton: UIButton!
    @IBOutlet weak var sadButton: UIButton!
    @IBOutlet weak var angryButton: UIButton!
    @IBOutlet weak var chatOwnerSmileyCollectionView: UICollectionView!
    @IBOutlet weak var chatOwnerReplyLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
