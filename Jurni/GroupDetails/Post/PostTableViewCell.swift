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

protocol ReactionTableViewCellDelegate: AnyObject {
//    func reactionButtonTapped(postID: String, isLiked: Bool)
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
    @IBOutlet weak var threeDotImgView: UIImageView!
    @IBOutlet weak var theeDotsBtnTap: UIButton!
    @IBOutlet weak var commentBtnTap: UIButton!
    @IBOutlet weak var allReactionBtnTap: UIButton!
    @IBOutlet weak var moreImagesButton: UIButton!
    @IBOutlet weak var numberOfReactionsLabel: UILabel!
    @IBOutlet weak var numberOfCommentsLabel: UILabel!
    @IBOutlet weak var reactToggleButton: UIButton!
    @IBOutlet weak var publishedCommentsContainer: UIView!
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var commentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var userInitiaTextLabel: UILabel!
    @IBOutlet weak var newCommentTextField: UITextField!
    @IBOutlet weak var commentProfileLabel: UILabel!
    @IBOutlet weak var sendCommentButton: UIButton!
    @IBOutlet weak var playVideoImageView: UIImageView!
    @IBOutlet weak var heartImageView: UIImageView!
    @IBOutlet weak var showSmileysView: UIView!
    @IBOutlet weak var thumbsUp: UIButton!
    @IBOutlet weak var laugh: UIButton!
    @IBOutlet weak var surprise: UIButton!
    @IBOutlet weak var sad: UIButton!
    @IBOutlet weak var angry: UIButton!
    @IBOutlet weak var love: UIButton!
    
    @IBOutlet weak var showCommentsLabel: UILabel!
    
    
    // MARK: - Properties
    var postID: String?
    var post: Post?
    var createCommentHandler: ((_ postID: String,_ text:String) -> Void)?
    var reactionHandler: ((_ index: Int,_ reaction:String) -> Void)?
    private var commentViews: [CommentView] = []
    private var visibleCommentViews: [CommentView] {
        return subviews as? [CommentView] ?? []
    }
    var isLiked: Bool = false
    weak var delegate: ReactionTableViewCellDelegate?
    weak var imageDelegate: PostTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func configurePostCell(with post: Post, index: Int) {
        hideImageVideoViews()
        self.postID = post.id
        setPosterAvatar(with: post)
        setPostText(with: post)
        if (!post.postContent.postImageUrls.isEmpty){
            setPostImages(with: post)
        }
        if (!post.postContent.postVideoUrl.isEmpty){
            setPostVideo(with: post)
        }
        if (post.user.isOwner)
        {
            theeDotsBtnTap.isHidden = false
            threeDotImgView.isHidden = false
//            commentView.isHidden = false
        }
        
        currentUserProfilePicView.layer.cornerRadius = currentUserProfilePicView.frame.size.width / 2
        let profilePic = UserDefaults.standard.string(forKey: Constants.PROFILE_PIC) ?? ""
        let firstName =  UserDefaults.standard.string(forKey: Constants.FIRST_NAME) ?? ""
        
         setImage(url: profilePic, imageView: currentUserProfilePicView)
        commentProfileLabel.isHidden = true
         if (!firstName.isEmpty && profilePic == ""){
             commentProfileLabel.isHidden = false
             commentProfileLabel.layer.cornerRadius = commentProfileLabel.frame.size.width / 2
             commentProfileLabel.layer.masksToBounds = true
             
             let nameFirstLetter:String = firstName.first!.description
             commentProfileLabel.text = nameFirstLetter
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
        
        if (post.commentsCount > 0)
        {
            numberOfCommentsLabel.text = "Show \(post.commentsCount) Comments"
        }
        else{
            numberOfCommentsLabel.text = "No Comments"
        }
       
        
        var totalReactions: Int{
            return post.postReaction.angry + post.postReaction.laugh + post.postReaction.love + post.postReaction.sad + post.postReaction.surprise + post.postReaction.thumbsUp
        }
        if totalReactions > 0{
            numberOfReactionsLabel.text = "❤️ \(totalReactions)"
            numberOfCommentsLabel.textColor = .black
        }
        else{
            numberOfReactionsLabel.text = "🩶"
            numberOfCommentsLabel.textColor = .lightGray
        }
        
        
        
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewClickSelector))
//        postBorderView.addGestureRecognizer(tapGesture)
//
//        let showSmileysGesture = UITapGestureRecognizer(target: self, action: #selector(showSmileysTapped))
//        heartImageView.isUserInteractionEnabled = true
//        heartImageView.tag = index
//        heartImageView.addGestureRecognizer(showSmileysGesture)
//
//        let showLaughTapped = UITapGestureRecognizer(target: self, action: #selector(showLaughTapped))
//        laugh.tag = index
//        laugh.addGestureRecognizer(showLaughTapped)
//
//        let showSurpriseTapped = UITapGestureRecognizer(target: self, action: #selector(showSurpriseTapped))
//        surprise.tag = index
//        surprise.addGestureRecognizer(showSurpriseTapped)
//
//        let showSadTapped = UITapGestureRecognizer(target: self, action: #selector(showSadTapped))
//        sad.tag = index
//        sad.addGestureRecognizer(showSadTapped)
//
//        let showAngryTapped = UITapGestureRecognizer(target: self, action: #selector(showAngryTapped))
//        angry.tag = index
//        angry.addGestureRecognizer(showAngryTapped)
//
//        let showThumbsTapped = UITapGestureRecognizer(target: self, action: #selector(showThumbsTapped))
//        thumbsUp.tag = index
//        thumbsUp.addGestureRecognizer(showThumbsTapped)
//
//        let loveTapped = UITapGestureRecognizer(target: self, action: #selector(showLoveTapped))
//        love.tag = index
//        love.addGestureRecognizer(loveTapped)
        
        
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
        theeDotsBtnTap.isHidden = true
        threeDotImgView.isHidden = true
//        commentView.isHidden = true
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
        imageDelegate?.moreImagesButtonTapped(cell: self)
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
        reactionHandler?(view.tag, "THUMB_UP")
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
    
    @objc func showCommentsTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        showSmileysView.isHidden = true
        reactionHandler?(view.tag, "ANGRY")
    }
    
}
