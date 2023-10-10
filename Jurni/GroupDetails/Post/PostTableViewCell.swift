//
//  PostTableViewCell.swift
//  Jurni
//
//  Created by Esther on 9/14/23.
//

import UIKit
import Kingfisher

protocol PostTableViewCellDelegate: AnyObject {
    func moreImagesButtonTapped(cell: PostTableViewCell)
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
    @IBOutlet weak var photoTwoThreeStackView: UIStackView!
    
    @IBOutlet weak var commentBtnTap: UIButton!
    @IBOutlet weak var moreImagesButton: UIButton!
    @IBOutlet weak var numberOfReactionsLabel: UILabel!
    @IBOutlet weak var numberOfCommentsLabel: UILabel!
    @IBOutlet weak var reactToggleButton: UIButton!
    @IBOutlet weak var publishedCommentsContainer: UIView!
    
    @IBOutlet weak var userInitiaTextLabel: UILabel!
    @IBOutlet weak var newCommentTextField: UITextField!
    @IBOutlet weak var sendCommentButton: UIButton!
    @IBOutlet weak var playVideoImageView: UIImageView!
   // @IBOutlet weak var heartImageView: UIImageView!
    @IBOutlet weak var showSmileysView: UIView!
    @IBOutlet weak var thumbsUp: UIButton!
    @IBOutlet weak var laugh: UIButton!
    @IBOutlet weak var surprise: UIButton!
    @IBOutlet weak var sad: UIButton!
    @IBOutlet weak var angry: UIButton!
    @IBOutlet weak var love: UIButton!
    
    @IBOutlet weak var thumbsUpLabel: UILabel!
    @IBOutlet weak var laughLabel: UILabel!
    @IBOutlet weak var surpriseLabel: UILabel!
    @IBOutlet weak var sadLabel: UILabel!
    @IBOutlet weak var angryLabel: UILabel!
    @IBOutlet weak var loveLabel: UILabel!
    
    // MARK: - Properties
    var postID: String?
    var createCommentHandler: ((_ postID: String,_ text:String) -> Void)?
    var reactionHandler: ((_ index: Int,_ reaction:String) -> Void)?
    private var commentViews: [CommentView] = []
    private var visibleCommentViews: [CommentView] {
        return subviews as? [CommentView] ?? []
    }
    var isLiked: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func configurePostCell(with post: Post, index: Int) {
        hideImageVideoViews()
        hideAllSmileyLabels()
        self.postID = post.id
        setPosterAvatar(with: post)
        setPostText(with: post)
        if (!post.postContent.postImageUrls.isEmpty){
            setPostImages(with: post)
        }
        if (!post.postContent.postVideoUrl.isEmpty){
            setPostVideo(with: post)
        }
        postBorderView.layer.cornerRadius = 20
        postBorderView.layer.borderWidth = 1.0
        postBorderView.layer.borderColor = UIColor.lightGray.cgColor
        
        setRoundedCorner(view: photoOneImageView)
        setRoundedCorner(view: photoTwoImageView)
        setRoundedCorner(view: photoThreeImageView)
        setRoundedCorner(view: photoTwoOfTwoImageView)
        setRoundedCorner(view: moreImagesButton)
        
        posterNameLabel.text = post.user.userName
        timeSincePostLabel.text = post.postTime.getMessagePostedDay()
        numberOfCommentsLabel.text = "\(post.commentsCount)"
        
        var totalReactions: Int{
            return post.postReaction.angry + post.postReaction.laugh + post.postReaction.love + post.postReaction.sad + post.postReaction.surprise + post.postReaction.thumbsUp
        }
        numberOfReactionsLabel.text = "\(totalReactions)"
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewClickSelector))
        postBorderView.addGestureRecognizer(tapGesture)
        
        let showSmileysGesture = UITapGestureRecognizer(target: self, action: #selector(showSmileysTapped))
        reactToggleButton.isUserInteractionEnabled = true
        reactToggleButton.tag = index
        reactToggleButton.addGestureRecognizer(showSmileysGesture)
        
        let showLaughTapped = UITapGestureRecognizer(target: self, action: #selector(showLaughTapped))
        laugh.tag = index
        laugh.addGestureRecognizer(showLaughTapped)
        
        let showSurpriseTapped = UITapGestureRecognizer(target: self, action: #selector(showSurpriseTapped))
        surprise.tag = index
        surprise.addGestureRecognizer(showSurpriseTapped)
        
        let showSadTapped = UITapGestureRecognizer(target: self, action: #selector(showSadTapped))
        sad.tag = index
        sad.addGestureRecognizer(showSadTapped)
        
        let showAngryTapped = UITapGestureRecognizer(target: self, action: #selector(showAngryTapped))
        angry.tag = index
        angry.addGestureRecognizer(showAngryTapped)
        
        let showThumbsTapped = UITapGestureRecognizer(target: self, action: #selector(showThumbsTapped))
        thumbsUp.tag = index
        thumbsUp.addGestureRecognizer(showThumbsTapped)
        
        let loveTapped = UITapGestureRecognizer(target: self, action: #selector(showLoveTapped))
        love.tag = index
        love.addGestureRecognizer(loveTapped)
        
        if (post.postReaction.angry > 0){
            showSmiley(smiley: "ANGRY")
        }
        if (post.postReaction.sad > 0){
            showSmiley(smiley: "SAD")
        }
        if (post.postReaction.laugh > 0){
            showSmiley(smiley: "LAUGH")
        }
        if (post.postReaction.surprise > 0){
            showSmiley(smiley: "SURPRISE")
        }
        if (post.postReaction.love > 0){
            showSmiley(smiley: "LOVE")
        }
        if (post.postReaction.thumbsUp > 0){
            showSmiley(smiley: "THUMBSUP")
        }
        
        
    }
    
    func setRoundedCorner(view: UIView){
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    
    func setPostVideo(with post: Post) {
        self.videoContainerView.isHidden = false
        self.playVideoImageView.isHidden = false
    }
    
    func setPostImages(with post: Post) {
        switch post.postContent.postImageUrls.count {
        case 1:
            self.photoOneImageView.isHidden = false
            self.photoOneImageView.contentMode = .scaleAspectFill
            setImage(url: post.postContent.postImageUrls[0], imageView: photoOneImageView)
            
        case 2:
            self.photoOneImageView.isHidden = false
            self.photoOneImageView.contentMode = .scaleAspectFill
            self.photoTwoThreeStackView.isHidden = false
            self.photoTwoOfTwoImageView.isHidden = false
            self.photoTwoOfTwoImageView.contentMode = .scaleAspectFill
            
            setImage(url: post.postContent.postImageUrls[0], imageView: photoOneImageView)
            setImage(url: post.postContent.postImageUrls[1], imageView: photoTwoOfTwoImageView)
            
        case 3:
            self.photoOneImageView.isHidden = false
            self.photoOneImageView.contentMode = .scaleAspectFill
            self.photoTwoThreeStackView.isHidden = false
            self.photoTwoImageView.isHidden = false
            self.photoTwoImageView.contentMode = .scaleAspectFill
            self.photoThreeImageView.isHidden = false
            self.photoThreeImageView.contentMode = .scaleAspectFill
            
            setImage(url: post.postContent.postImageUrls[0], imageView: photoOneImageView)
            setImage(url: post.postContent.postImageUrls[1], imageView: photoTwoImageView)
            setImage(url: post.postContent.postImageUrls[2], imageView: photoThreeImageView)
            
            
        case 4..<100:
            self.photoOneImageView.isHidden = false
            self.photoOneImageView.contentMode = .scaleAspectFill
            self.photoTwoThreeStackView.isHidden = false
            self.photoTwoImageView.isHidden = false
            self.photoTwoImageView.contentMode = .scaleAspectFill
            self.photoThreeImageView.isHidden = false
            self.photoThreeImageView.contentMode = .scaleAspectFill
            self.moreImagesButton.isHidden = false
            self.moreImagesButton.setTitle(" +\(post.postContent.postImageUrls.count - 3)", for: .normal)
            
            setImage(url: post.postContent.postImageUrls[0], imageView: photoOneImageView)
            setImage(url: post.postContent.postImageUrls[1], imageView: photoTwoImageView)
            setImage(url: post.postContent.postImageUrls[2], imageView: photoThreeImageView)
            
        default: print("Image size:\(post.postContent.postImageUrls.count)")
        }
        
    }
    
    func setImage(url: String, imageView: UIImageView){
        if(url != ""){
            let imageUrl = URL(string:  url)
            imageView.kf.setImage(with: imageUrl)
        }
    }
    
    func hideImageVideoViews(){
        photoOneImageView.isHidden = true
        photoTwoImageView.isHidden = true
        photoThreeImageView.isHidden = true
        photoTwoOfTwoImageView.isHidden = true
        photoTwoThreeStackView.isHidden = true
        videoContainerView.isHidden = true
        moreImagesButton.isHidden = true
        playVideoImageView.isHidden = true
    }
    
    
    func setPostText(with post: Post){
        postTextContentLabel.text = post.postContent.postText
    }
    
    
    func setPosterAvatar(with post: Post) {
        self.userInitiaTextLabel.isHidden = true
        posterProfilePicImageView.image = nil
        
        posterProfilePicImageView.layer.cornerRadius = posterProfilePicImageView.frame.size.width / 2
        posterProfilePicImageView.layer.masksToBounds = true
        let posterImageURL = URL(string: post.user.userAvatar)
        if(posterImageURL != nil){
            posterProfilePicImageView.kf.setImage(with: posterImageURL)
        } else {
            self.userInitiaTextLabel.isHidden = false
            self.userInitiaTextLabel.text = String(post.user.userName.prefix(1))
            self.posterProfilePicImageView.layer.backgroundColor = UIColor.lightGray.cgColor
        }
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
      //  showSmileysView.isHidden = false
    }
    
    @IBAction func seeAllCommentsTapped(_ sender: Any) {
    }
    
    @IBAction func newCommentSendButtonTapped(_ sender: Any) {
        textFieldDidChange(newCommentTextField)
        guard let comment = newCommentTextField.text, !comment.isEmpty,
              let postID = self.postID else { return }
        createCommentHandler?(postID, comment)
    }
    
    @objc func viewClickSelector(){
        postBorderView.endEditing(true)
        showSmileysView.isHidden = true
    }
    
    @objc func showSmileysTapped(tapGestureRecognizer: UITapGestureRecognizer){
        showSmileysView.isHidden = false
    }
    
    @objc func showThumbsTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        showSmileysView.isHidden = true
        reactionHandler?(view.tag, "THUMBS_UP")
    }
    
    @objc func showLoveTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        showSmileysView.isHidden = true
        reactionHandler?(view.tag, "LOVE")
    }
    
    @objc func showLaughTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        showSmileysView.isHidden = true
        reactionHandler?(view.tag, "LAUGH")
    }
    
    @objc func showSurpriseTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        showSmileysView.isHidden = true
        reactionHandler?(view.tag, "SURPRISE")
    }
    
    @objc func showSadTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        showSmileysView.isHidden = true
        reactionHandler?(view.tag, "SAD")
    }
    
    @objc func showAngryTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        showSmileysView.isHidden = true
        reactionHandler?(view.tag, "ANGRY")
    }
    
    func hideAllSmileyLabels(){
        laughLabel.isHidden = true
        sadLabel.isHidden = true
        surpriseLabel.isHidden = true
        loveLabel.isHidden = true
        thumbsUpLabel.isHidden = true
        angryLabel.isHidden = true
    }
    
    func showSmiley(smiley: String){
        switch smiley{
        case "LAUGH": laughLabel.isHidden = false
        case "SAD": sadLabel.isHidden = false
        case "SURPRISE": surpriseLabel.isHidden = false
        case "LOVE": loveLabel.isHidden = false
        case "THUMBSUP": thumbsUpLabel.isHidden = false
        case "ANGRY": angryLabel.isHidden = false
        default: print("Default")
        }
    }
}
