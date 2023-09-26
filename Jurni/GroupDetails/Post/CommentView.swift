//
//  CommentView.swift
//  Jurni
//
//  Created by Esther on 9/21/23.
//

import UIKit

class CommentView: UIView {
    @IBOutlet weak var commenterNameLabel: UILabel!
    @IBOutlet weak var timeSinceCommentLabel: UILabel!
    @IBOutlet weak var commenterImageView: UIImageView!
    @IBOutlet weak var commentTextLabel: UILabel!
    @IBOutlet weak var commenterInitialTextLabel: UILabel!
    
    
    // MARK: - Methods
    
    func loadView(with post: Post, comment: Comment) {
        setCommenterAvatar(with: post)
        commenterNameLabel.text = post.user.userName
        timeSinceCommentLabel.text = comment.timestamp.getMessagePostedDay()
  
    }
    
    func setCommenterAvatar(with post: Post) {
        commenterImageView.layer.cornerRadius = commenterImageView.frame.size.width / 2
        commenterImageView.layer.masksToBounds = true
        
        let commenterImageURL = URL(string: post.user.userAvatar)
        if(commenterImageURL != nil){
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: commenterImageURL!)
                DispatchQueue.main.async {
                    self.commenterImageView.image = UIImage(data: data!)
                }
            }
        } else {
            DispatchQueue.main.async {
                self.commenterInitialTextLabel.isHidden = false
                self.commenterInitialTextLabel.text = String(post.user.userName.prefix(1))
                self.commenterImageView.layer.backgroundColor = UIColor.lightGray.cgColor
            }
        }
    }

}
