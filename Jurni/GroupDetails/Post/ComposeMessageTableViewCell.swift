//
//  ComposeMessageTableViewCell.swift
//  Jurni
//
//  Created by Yatharth Singh on 27/09/23.
//

import UIKit
import AVFoundation

class ComposeMessageTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var collectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var avtarImageView: UIImageView!
    @IBOutlet weak var videoViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var playVideoImg: UIImageView!
    @IBOutlet weak var deleteVideoBtnView: UIView!
    @IBOutlet weak var deleteVideoBtn: UIButton!
    @IBOutlet var writeSomthingTextView: UITextView!
    @IBOutlet weak var imgView: UIView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var uploadPhotoBtn: UIButton!
    @IBOutlet weak var uploadVideoBtn: UIButton!
    @IBOutlet weak var publishBtn: UIButton!
    @IBOutlet weak var videoBtnView: UIView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    var videoPlayerLayer: AVPlayerLayer!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
//        videoPlayerLayer = AVPlayerLayer(player: nil)
//        videoPlayerLayer.videoGravity = .resizeAspectFill // Set desired video gravity
//        videoView.layer.addSublayer(videoPlayerLayer)
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
   
    
}
