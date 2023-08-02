//
//  ChatUserTableViewCell.swift
//  Jurni
//
//  Created by Devrath Rathee on 08/06/23.
//

import UIKit

class ChatUserTableViewCell: UITableViewCell{

    @IBOutlet weak var chatUserNameLabel: UILabel!
    @IBOutlet weak var chatUserMessageLabel: UILabel!
    @IBOutlet weak var chatUserMessageDateLabel: UILabel!
    @IBOutlet weak var chatUserView: UIView!
    @IBOutlet weak var chatUserParentView: UIView!
    @IBOutlet weak var chatUserImageView: UIImageView!
    @IBOutlet weak var chatUserAudioView: UIView!
    @IBOutlet weak var chatUserPlayPauseButton: UIButton!
    @IBOutlet weak var chatUserTimerLabel: UILabel!
    @IBOutlet weak var chatUserHorizontalSlider: UISlider!
    @IBOutlet weak var chatUserSmileysView: UIView!
    @IBOutlet weak var userThumbsUpButton: UIButton!
    @IBOutlet weak var userHappyButton: UIButton!
    @IBOutlet weak var userSurpriseButton: UIButton!
    @IBOutlet weak var userSadButton: UIButton!
    @IBOutlet weak var userAngryButton: UIButton!
    @IBOutlet weak var userLoveButton: UIButton!
    @IBOutlet weak var showUserSmileysButton: UIButton!
    @IBOutlet weak var userReplyButton: UIButton!
    @IBOutlet weak var chatUserSmileysCollectionView: UICollectionView!
    @IBOutlet weak var chatUserReplyLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
