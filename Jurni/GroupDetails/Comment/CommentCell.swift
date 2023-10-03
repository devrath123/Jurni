//
//  CommentCell.swift
//  Jurni
//
//  Created by Yatharth Singh on 02/10/23.
//

import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var avtarView: UIView!
    @IBOutlet weak var commentImgView: UIImageView!
    @IBOutlet weak var imageLbl: UILabel!
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var commentTextLbl: UILabel!
    @IBOutlet weak var timeLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func setCommentsData(with comment: Comment){
        print(comment, "comment")
        nameLbl.text = comment.from.userName
        commentTextLbl.text = comment.content.htmlAttributedString() ?? ""
        timeLbl.text = comment.timestamp.getMessagePostedDay()
        setImage(url: comment.from.userAvatar, imageView: commentImgView)

        if (!comment.from.userName.isEmpty && comment.from.userAvatar == ""){
            avtarView.layer.cornerRadius = avtarView.frame.size.width / 2
            let nameFirstLetter:String = comment.from.userName.first!.description
            imageLbl.text = nameFirstLetter
        }
    }
    
    func setImage(url: String, imageView: UIImageView){
        if(url != ""){
            let imageUrl = URL(string:  url)
            imageView.kf.setImage(with: imageUrl)
        }
    }
    
    
    
}
