//
//  PostTableViewCell.swift
//  Jurni
//
//  Created by Esther on 9/14/23.
//

import UIKit

protocol ReactionTableViewCellDelegate: AnyObject {
    func reactionButtonTapped(postID: String, isLiked: Bool)
}

class PostTableViewCell: UITableViewCell, UITextFieldDelegate {
    
    
    // MARK: - Outlets
    @IBOutlet weak var posterProfilePicImageView: UIImageView!
    
    @IBOutlet weak var posterNameLabel: UILabel!
    @IBOutlet weak var timeSincePostLabel: UILabel!
    
    @IBOutlet weak var currentUserProfilePicView: UIImageView!
    @IBOutlet weak var postBorderView: UIView!
    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var postTextContentLabel: UILabel!
    @IBOutlet weak var imagesStackView: UIStackView!
    @IBOutlet weak var photoOneImageView: UIImageView!
    @IBOutlet weak var photoTwoImageView: UIImageView!
    @IBOutlet weak var photoThreeImageView: UIImageView!
    @IBOutlet weak var photoTwoOfTwoImageView: UIImageView!
    
    @IBOutlet weak var moreImagesButton: UIButton!
    @IBOutlet weak var numberOfReactionsLabel: UILabel!
    @IBOutlet weak var numberOfCommentsLabel: UILabel!
    @IBOutlet weak var reactToggleButton: UIButton!
    @IBOutlet weak var publishedCommentsContainer: UIView!
    
    @IBOutlet weak var userInitiaTextLabel: UILabel!
    @IBOutlet weak var newCommentTextField: UITextField!
    @IBOutlet weak var sendCommentButton: UIButton!
    
    
    // MARK: - Properties
    var postID: String?
    var createCommentHandler: ((_ postID: String,_ text:String) -> Void)?
    private var commentViews: [CommentView] = []
    private var visibleCommentViews: [CommentView] {
        return subviews as? [CommentView] ?? []
    }
    var isLiked: Bool = false
    weak var delegate: ReactionTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    func configurePostCell(with post: Post) {

        self.postID = post.id
        setPosterAvatar(with: post)
        setPostText(with: post)
        setPostImages(with: post)
        setPostVideo(with: post)
        postBorderView.layer.cornerRadius = 20
        postBorderView.layer.borderWidth = 1.0
        postBorderView.layer.borderColor = UIColor.opaqueSeparator.cgColor
        
        posterNameLabel.text = post.user.userName
        timeSincePostLabel.text = post.postTime.getMessagePostedDay()
        
        var totalReactions: Int{
            return post.postReaction.angry + post.postReaction.laugh + post.postReaction.love + post.postReaction.sad + post.postReaction.surprise + post.postReaction.thumbsUp
        }
        numberOfReactionsLabel.text = "\(totalReactions)"
        
    }
   
    
    func setPostVideo(with post: Post) {
        if !post.postContent.postVideoUrl.isEmpty, !post.postContent.postVideoUrl[0].isEmpty{
        }else{
            self.videoContainerView.isHidden = true
        }
    }
    
    func setPostImages(with post: Post) {
        if !post.postContent.postImageUrls.isEmpty, !post.postContent.postImageUrls[0].isEmpty {
           if let photoOneURL = URL(string: post.postContent.postImageUrls[0]) {
                DispatchQueue.global().async {
                    if let photoOneData = try? Data(contentsOf: photoOneURL){
                        DispatchQueue.main.async {
                            self.photoOneImageView.image = UIImage(data: photoOneData)
                            self.photoOneImageView.contentMode = .scaleAspectFill
                            self.photoOneImageView.isHidden = false
                            self.videoContainerView.isHidden = true
                        }
                    }
                }
            }
        } else {
            self.photoOneImageView.isHidden = true
            self.photoTwoImageView.isHidden = true
            self.photoThreeImageView.isHidden = true
            self.imagesStackView.isHidden = true
            print("Text: \(post.postContent.postText)")
            print("Image size:\(post.postContent.postImageUrls.count)")
        }

        if post.postContent.postImageUrls.count == 2 {
            self.photoTwoOfTwoImageView.isHidden = false
            self.photoOneImageView.isHidden = false
            self.photoTwoImageView.isHidden = true
            self.photoThreeImageView.isHidden = true
            self.videoContainerView.isHidden = true
            if let photoTwoOfTwoURL = URL(string: post.postContent.postImageUrls[1]) {
                DispatchQueue.global().async {
                    if let photoTwoData = try? Data(contentsOf: photoTwoOfTwoURL){
                        DispatchQueue.main.async {
                            self.photoTwoOfTwoImageView.image = UIImage(data: photoTwoData)
                            self.photoTwoOfTwoImageView.contentMode = .scaleAspectFill
                        }
                    }
                }
            }
            
        } else if
         post.postContent.postImageUrls.count == 1 {
            self.photoOneImageView.isHidden = false
            self.photoTwoImageView.isHidden = true
            self.photoTwoOfTwoImageView.isHidden = true
            self.photoThreeImageView.isHidden = true
            self.videoContainerView.isHidden = true
        } else if
            post.postContent.postImageUrls.count >= 3 {
            self.photoTwoImageView.isHidden = false
            self.photoThreeImageView.isHidden = false
            self.photoOneImageView.isHidden = false
            self.photoTwoOfTwoImageView.isHidden = true
            self.videoContainerView.isHidden = true
            
            if let photoTwoURL = URL(string: post.postContent.postImageUrls[1]) {
                DispatchQueue.global().async {
                    if let photoTwoData = try? Data(contentsOf: photoTwoURL){
                        DispatchQueue.main.async {
                            self.photoTwoImageView.image = UIImage(data: photoTwoData)
                            self.photoTwoImageView.contentMode = .scaleAspectFill
                            
                        }
                    }
                }
            }
            if let photoThreeURL = URL(string: post.postContent.postImageUrls[2]) {
                DispatchQueue.global().async {
                    if let photoThreeData = try? Data(contentsOf: photoThreeURL){
                        DispatchQueue.main.async {
                            self.photoThreeImageView.image = UIImage(data: photoThreeData)
                            self.photoThreeImageView.contentMode = .scaleAspectFill
                        }
                    }
                }
            }
        }

        let additionalImageCount = max(0, post.postContent.postImageUrls.count - 3)
        if additionalImageCount > 0 {
            self.moreImagesButton.isHidden = false
            self.moreImagesButton.setTitle("+ \(additionalImageCount)", for: .normal)
        } else {
            self.moreImagesButton.isHidden = true
        }
    }
    
    func setPostText(with post: Post){
        let htmlString = post.postContent.postText
        if let data = htmlString.data(using: .utf8),
           let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            postTextContentLabel.attributedText = attributedString
        }
    }
    
    
    func setPosterAvatar(with post: Post) {
        self.posterProfilePicImageView.image = UIImage(named: "userblue")
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if let text = newCommentTextField.text, !text.isEmpty {
            sendCommentButton.isEnabled = true
        } else {
            sendCommentButton.isEnabled = false
        }
    }
    
    @IBAction func moreImagesButtonTapped(_ sender: Any) {

    }
    @IBAction func reactButtonTapped(_ sender: Any) {
        guard let postID else { return }
        isLiked.toggle()
        if isLiked {
            reactToggleButton.setImage(UIImage(named: "react-10px"), for: .normal)
        } else {
            reactToggleButton.setImage(UIImage(named: "grey-react-15px"), for: .normal)
        }
        delegate?.reactionButtonTapped(postID: postID, isLiked: isLiked)
    }
    
    @IBAction func seeAllCommentsTapped(_ sender: Any) {
    }
    
    @IBAction func newCommentSendButtonTapped(_ sender: Any) {
        textFieldDidChange(newCommentTextField)
        guard let comment = newCommentTextField.text, !comment.isEmpty,
              let postID = self.postID else { return }
        createCommentHandler?(postID, comment)
    }
}
