//
//  GroupDetailsViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 27/02/23.
//

import UIKit
import AVKit
import FirebaseFirestore
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import PhotosUI
import MobileCoreServices

protocol BackDelegate: AnyObject {
    func didComeBack()
}

class GroupDetailsViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextViewDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var membersCountLabel: UILabel!
    @IBOutlet weak var groupPostTableView: UITableView!
    
    
    // MARK: - Properties
    var groupDetails: Group?
    var player: AVPlayer!
    var avpPlayerController = AVPlayerViewController()
    var posts: [Post] = []
    var selectedPost: Post? = nil
    let imagePicker = UIImagePickerController()
    var activityView: UIActivityIndicatorView?
    private var refreshControl = UIRefreshControl()
    var selectedImages: [UIImage] = []
    var postImages: [String] = []
    var videoURL: URL?
    var row: Int?
    
    let MESSAGE_TYPE_TEXT = "text"
    let MESSAGE_TYPE_IMAGE = "image"
    let MESSAGE_TYPE_VIDEO = "video"

    var contentOffset: CGPoint = .zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupPostTableView.dataSource = self
        groupPostTableView.delegate = self
        imagePicker.delegate = self

        contentOffset = groupPostTableView.contentOffset
        groupPostTableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        showActivityIndicator()
        groupPostTableView.rowHeight = UITableView.automaticDimension
        self.groupPostTableView.estimatedRowHeight = 100
        let headerNib = UINib(nibName: "ComposeMessageTableViewCell", bundle: nil)
        groupPostTableView.register(headerNib, forCellReuseIdentifier: "ComposeMessageTableViewCell")
        
        let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
        groupPostTableView.register(nib, forCellReuseIdentifier: "PostTableViewCell")
        fetchPosts()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        groupPostTableView.addGestureRecognizer(tapGesture)
        
        groupPostTableView.backgroundColor = UIColor.white
        groupNameLabel.text = groupDetails?.groupName
        membersCountLabel.text =  "\(groupDetails?.membersCount ?? 0) MEMBERS"
    }
    
    
    // MARK: - Methods
    
    @objc private func refreshData() {

           refreshControl.endRefreshing()
       }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func fetchPosts(){
        
        let defaultStore = Firestore.firestore()
        print("Group id: \(self.groupDetails?.groupId)")
        defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").getDocuments(){ (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err) :(")
            } else {
                if let documents = querySnapshot?.documents {
                    let jurniGroup =  DispatchGroup()
                    for document in documents {
                        print("Doc : \(document.data())")
                        let id = document.documentID
                        let postType = document.get("type") as? String
                        let timestamp = document.get("timestamp") as! Timestamp
                        let postTime = timestamp.dateValue()
                        
                        let mediaURL = document.get("meta.url")
                        var videoArray: [String] = []
                        var imageArray: [String] = []
                        
                        switch postType {
                        case "image":
                            if let singleImageURL = mediaURL as? String {
                                imageArray = [singleImageURL]
                            } else if let multipleURLs = mediaURL as? [String] {
                                imageArray = multipleURLs
                            }
                        case "video":
                            if let videoURL = mediaURL as? String {
                                videoArray = [videoURL]
                            }else if let multipleVideoURLs = mediaURL as? [String] {
                                videoArray = multipleVideoURLs
                            }
                            
                        case "text":
                            if let emptyStringURL = mediaURL as? String {
                                imageArray = [emptyStringURL]
                            }
                            
                        default:
                            break
                        }
                        
                        let postContent = document.get("meta.content") as? String
                        let postText = postContent?.htmlAttributedString() ?? ""
                        let comments = document.get("comments")
                        if let reactionsData = document.get("reactions") as? [String:Any] {
                            let reactions = PostReaction(
                                angry: reactionsData["ANGRY"] as? Int ?? 0,
                                laugh: reactionsData["LAUGH"] as? Int ?? 0,
                                love: reactionsData["LOVE"] as? Int ?? 0,
                                sad: reactionsData["SAD"] as? Int ?? 0,
                                surprise: reactionsData["SURPRISE"] as? Int ?? 0,
                                thumbsUp: reactionsData["THUMB_UP"] as? Int ?? 0
                            )
                            var commentsCount = 0
                            let posterIDPath = document.get("from") as! DocumentReference
                            let pathString = posterIDPath.path
                            let components = pathString.components(separatedBy: "/")
                            if let uid = components.last{
                                print("poster UID = \(uid)")
                                let userRef = defaultStore.collection("users").document(uid)
                                userRef.getDocument { (document, error) in
                                    if let document = document, document.exists {
                                        
                                        var userName: String = ""
                                        var userImage: String = ""
                                        
                                        if(document.get("firstName") as? String != nil){
                                            userName = document.get("firstName") as? String ?? ""
                                        }
                                        
                                        if(document.get("lastName") as? String != nil){
                                            userName += " " + (document.get("lastName") as? String ?? "")
                                        }
                                        
                                        if(document.get("avatar") != nil){
                                            if let image =  document.get("avatar") as? String {
                                                userImage = image
                                            }else{
                                                userImage.append("")
                                            }
                                        }
                                        
                                        
                                    let commentsRef = defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(id).collection("comments")
                                        commentsRef.getDocuments { (querySnapshot, err) in
                                            if let err = err {
                                                print("Error getting comments documents: \(err)")
                                            } else {
                                                commentsCount = querySnapshot?.documents.count ?? 0
                                                
                                                let currentUserUid = Auth.auth().currentUser!.uid
                                                var isOwner = false
                                                if currentUserUid == uid
                                                {
                                                    isOwner = true
                                                }
                                               
                                                let postUser = User(userName: userName, userAvatar: userImage, isOwner: isOwner)
                                                
                                                let post = Post(postType: postType ?? "", postTime: postTime, postContent: PostContent(postText: postText, postImageUrls: imageArray, postVideoUrl: videoArray), user: postUser, postReaction: reactions, commentsCount: commentsCount)
                                                
                                                post.id = id
                                                
                                                self.posts.append(post)
                                                
                                                self.posts = self.posts.removingDuplicates()
                                                self.posts = self.posts.sorted(by: { $0.postTime.compare($1.postTime as Date) == .orderedDescending })
                                                self.hideActivityIndicator()
                                                DispatchQueue.main.async {
                                                    self.groupPostTableView.reloadData()
                                                    UIView.setAnimationsEnabled(false)
                                                    self.groupPostTableView.beginUpdates()
                                                    self.groupPostTableView.endUpdates()
                                                }
                                                
                                            }}
                                    } else {
                                        print("User document not found for UID: \(uid)")
                                        self.hideActivityIndicator()
                                    }
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                                           self.hideActivityIndicator()
                                       }
                }
            }
        }
    }
    
    
    
    func  fetchPostsAndRefreshRow(section: Int, row: Int){
        
        let defaultStore = Firestore.firestore()
        print("Group id: \(self.groupDetails?.groupId)")
        defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").getDocuments(){ (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err) :(")
            } else {
                if let documents = querySnapshot?.documents {
                    let jurniGroup =  DispatchGroup()
                    for document in documents {
                        print("Doc : \(document.data())")
                        let id = document.documentID
                        let postType = document.get("type") as? String
                        let timestamp = document.get("timestamp") as! Timestamp
                        let postTime = timestamp.dateValue()
                        
                        let mediaURL = document.get("meta.url")
                        var videoArray: [String] = []
                        var imageArray: [String] = []
                        
                        switch postType {
                        case "image":
                            if let singleImageURL = mediaURL as? String {
                                imageArray = [singleImageURL]
                            } else if let multipleURLs = mediaURL as? [String] {
                                imageArray = multipleURLs
                            }
                        case "video":
                            if let videoURL = mediaURL as? String {
                                videoArray = [videoURL]
                            }else if let multipleVideoURLs = mediaURL as? [String] {
                                videoArray = multipleVideoURLs
                            }
                            
                        case "text":
                            if let emptyStringURL = mediaURL as? String {
                                imageArray = [emptyStringURL]
                            }
                            
                        default:
                            break
                        }
                        
                        let postContent = document.get("meta.content") as? String
                        let postText = postContent?.htmlAttributedString() ?? ""
                        let comments = document.get("comments")
                        
                        if let reactionsData = document.get("reactions") as? [String:Any] {
                            let reactions = PostReaction(
                                angry: reactionsData["ANGRY"] as? Int ?? 0,
                                laugh: reactionsData["LAUGH"] as? Int ?? 0,
                                love: reactionsData["LOVE"] as? Int ?? 0,
                                sad: reactionsData["SAD"] as? Int ?? 0,
                                surprise: reactionsData["SURPRISE"] as? Int ?? 0,
                                thumbsUp: reactionsData["THUMB_UP"] as? Int ?? 0
                            )
                            var commentsCount = 0
                            let posterIDPath = document.get("from") as! DocumentReference
                            let pathString = posterIDPath.path
                            let components = pathString.components(separatedBy: "/")
                            if let uid = components.last{
                                print("poster UID = \(uid)")
                                let userRef = defaultStore.collection("users").document(uid)
                                userRef.getDocument { (document, error) in
                                    if let document = document, document.exists {
                                        
                                        var userName: String = ""
                                        var userImage: String = ""
                                        
                                        if(document.get("firstName") as? String != nil){
                                            userName = document.get("firstName") as? String ?? ""
                                        }
                                        
                                        if(document.get("lastName") as? String != nil){
                                            userName += " " + (document.get("lastName") as? String ?? "")
                                        }
                                        
                                        if(document.get("avatar") != nil){
                                            if let image =  document.get("avatar") as? String {
                                                userImage = image
                                            }else{
                                                userImage.append("")
                                            }
                                        }
                                        
                                        
                                    let commentsRef = defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(id).collection("comments")
                                        commentsRef.getDocuments { (querySnapshot, err) in
                                            if let err = err {
                                                print("Error getting comments documents: \(err)")
                                            } else {
                                                commentsCount = querySnapshot?.documents.count ?? 0
                                                
                                                let currentUserUid = Auth.auth().currentUser!.uid
                                                var isOwner = false
                                                if currentUserUid == uid
                                                {
                                                    isOwner = true
                                                }
                                               
                                                let postUser = User(userName: userName, userAvatar: userImage, isOwner: isOwner)
                                                
                                                let post = Post(postType: postType ?? "", postTime: postTime, postContent: PostContent(postText: postText, postImageUrls: imageArray, postVideoUrl: videoArray), user: postUser, postReaction: reactions, commentsCount: commentsCount)
                                                
                                                post.id = id
                                                
                                                self.posts.append(post)
                                                
                                                self.posts = self.posts.removingDuplicates()
                                                self.posts = self.posts.sorted(by: { $0.postTime.compare($1.postTime as Date) == .orderedDescending })
                                                let indexPath = IndexPath(row: row, section: section)
                                                    DispatchQueue.main.async {
                                                        self.groupPostTableView.beginUpdates()
                                                        self.groupPostTableView.reloadRows(at: [indexPath], with: .none)
                                                        self.groupPostTableView.endUpdates()
                                                        self.hideActivityIndicator()
                                                    }
                                                
                                            }}
                                    } else {
                                        print("User document not found for UID: \(uid)")
                                        self.hideActivityIndicator()
                                    }
                                }
                            }
                        }
                    }
                    DispatchQueue.main.async {
                                           self.hideActivityIndicator()
                                       }
                }
            }
        }
    }
    
    
    func reloadTableView() {
        self.groupPostTableView.reloadData()
        self.groupPostTableView.layoutIfNeeded()
        self.groupPostTableView.setContentOffset(contentOffset, animated: false)
       }
    
    func createComment(postID: String,content: String) {
        
        self.showActivityIndicator()
        let defaultStore = Firestore.firestore()
        let document = defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(postID).collection("comments").document()
        
        let from = Auth.auth().currentUser!.uid
        let ownerString = Firestore.firestore().collection("users").document(from)
        let ownerReference = Firestore.firestore().document(ownerString.path)
        
        let dataToSend : [String: Any] = ["content": content,"from": ownerReference, "timestamp":FieldValue.serverTimestamp()]
        document.setData(dataToSend) { error in
            if let error = error {
                print("error creating comment")
            } else {
                print("sucessful getting a comment")
            
                DispatchQueue.main.async {
                    self.fetchPosts()

                }

                
            }
        }
    }
    
    func addReaction(postID: String, isLiked: Bool) {
        print("Attempting to add this reaction \(isLiked), to this postID: \(postID)")
        
    }
    
    
    @IBAction func backClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func playVideo(videoUrl: URL, videoView: UIView) {
        
        let videoURL =  videoUrl
        self.player = AVPlayer(url: videoURL)
        self.avpPlayerController = AVPlayerViewController()
        avpPlayerController.player = self.player
        avpPlayerController.view.frame = videoView.bounds
        self.avpPlayerController.showsPlaybackControls = true
        videoView.addSubview(avpPlayerController.view)
    }
    
    func play() {
        self.avpPlayerController.player?.play()
        }

        func pause() {
            self.avpPlayerController.player?.pause()
        }
    
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if results.count == 0 {
            print("User canceled")
            selectedImages = []
            self.groupPostTableView.reloadData()
        }
        else{
            for result in results {
                if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                        if let image = object as? UIImage {
                            self.selectedImages.append(image)
                            DispatchQueue.main.async {
                                self.groupPostTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                            }
                        }
                    }
                }
                
            }
            
            DispatchQueue.main.async {
                self.groupPostTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                self.groupPostTableView.reloadSections(IndexSet(integer: 1), with: .automatic)
                self.groupPostTableView.reloadData()
            }
            
            
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            self.videoURL = videoURL
            DispatchQueue.main.async {
                let cell: ComposeMessageTableViewCell = self.groupPostTableView.cellForRow(at: IndexPath(row: 0, section: 0))! as! ComposeMessageTableViewCell
                cell.imgView.isHidden = true
                self.groupPostTableView.reloadData()
            }
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.groupPostTableView.reloadData()
        dismiss(animated: true, completion: nil)
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func postDataToFirebase(dataType: String, content: [String: Any]){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy 'at' h:mm:ss a 'UTC'ZZZZZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 5 * 3600 + 30 * 60)
        let date = Date()
        let da = dateFormatter.string(from: date)
        let timestamp = dateFormatter.date(from: da)
        
        let randomId = String("\(randomString(length: 20))")
        let groupId = self.groupDetails?.groupId ?? ""
        let from = Auth.auth().currentUser!.uid
        let ownerString = Firestore.firestore().collection("users").document(from)
        let ownerReference = Firestore.firestore().document(ownerString.path)
        
        let reactions = [
            "THUMB_UP": 0,
            "LOVE": 0,
            "SAD": 0,
            "ANGRY": 0,
            "SURPRISE": 0,
            "LAUGH": 0 ]
        let docRef = Firestore.firestore().collection("groups").document(groupId).collection("posts").document(randomId)
        docRef.setData([
            "from": ownerReference,
            "type": dataType,
            "meta": content,
            "reactions": reactions,
            "timestamp": timestamp
        ]){ err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("successfully uploded ")
                DispatchQueue.main.async {
                    self.hideActivityIndicator()
                    self.selectedImages.removeAll()
                    self.videoURL = nil
                    self.fetchPosts()
                    self.groupPostTableView.reloadData()
                    self.groupPostTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                    self.groupPostTableView.reloadSections(IndexSet(integer: 1), with: .automatic)
                }
            }
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as? PhotoCollectionViewCell else { return UICollectionViewCell() }
        
        
        cell.deleteImageBtn.addTarget(self, action: #selector(deleteSeletedImage(sender:)), for: .touchUpInside)
        cell.deleteImageBtn.tag = indexPath.item
        cell.backgroundColor = UIColor.white
        cell.avtarImageView.image =  self.selectedImages[indexPath.item]
        cell.avtarImageView.layer.cornerRadius = 10
        cell.avtarImageView.layer.masksToBounds = true
        cell.avtarImageView.contentMode = .scaleToFill
        
        return cell
    }
    
}

extension GroupDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func textViewDidChange(_ textView: UITextView) {
       
        groupPostTableView?.beginUpdates()
        groupPostTableView?.endUpdates()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {

        if textView.textColor == UIColor.lightGray {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {

        if textView.text == "" {

            textView.text = "Write something here..."
            textView.textColor = UIColor.lightGray
        }
    }
    func textViewDidChange(descriptionField: UITextView) {
        if descriptionField.text.isEmpty == false {
            descriptionField.text = ""
        } else {
            descriptionField.text = "Write something here..."
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 1
        }
        else{
            return posts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0{
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ComposeMessageTableViewCell") as? ComposeMessageTableViewCell else { return UITableViewCell() }
            
            cell.containerView.backgroundColor = UIColor.white
            cell.backgroundColor = UIColor.white
            
            print("Compose: \(indexPath.row)")
            
            cell.photoCollectionView.delegate = self
            cell.photoCollectionView.dataSource = self
            
            
            if let url = self.videoURL {
                cell.videoViewHeightConstraint.constant = CGFloat(140)
                cell.videoView.isHidden = false
                cell.deleteVideoBtnView.isHidden = false
                cell.imgView.isHidden = true
                cell.playVideoImg.isHidden = false
                playVideo(videoUrl: url , videoView: cell.videoView)
            }
            else{
                cell.videoViewHeightConstraint.constant = CGFloat(40)
                cell.deleteVideoBtnView.isHidden = true
                cell.imgView.isHidden = false
                cell.videoView.isHidden = true
                cell.playVideoImg.isHidden = true
            }
            
            if (self.selectedImages.count > 0)
            {
                cell.videoBtnView.isHidden = true
            }
            else{
                cell.videoBtnView.isHidden = false
            }
            
            
            
            
            let photoNib = UINib(nibName: "PhotoCollectionViewCell", bundle: nil)
            cell.photoCollectionView.register(photoNib, forCellWithReuseIdentifier: "PhotoCollectionViewCell")
            
            cell.photoCollectionView.backgroundColor = UIColor.white
            let tapGesture = UITapGestureRecognizer (target: self, action: #selector(imgTap(tapGesture:)))
            cell.playVideoImg.addGestureRecognizer(tapGesture)
            cell.playVideoImg.isUserInteractionEnabled = true
            cell.uploadPhotoBtn.addTarget(self, action: #selector(uploadImages(_:)), for: .touchUpInside)
            cell.uploadVideoBtn.addTarget(self, action: #selector(uploadVideo(_:)), for: .touchUpInside)
            cell.deleteVideoBtn.addTarget(self, action: #selector(deleteVideo(_:)), for: .touchUpInside)
            cell.publishBtn.addTarget(self, action: #selector(publishPost(_:)), for: .touchUpInside)
            
            cell.writeSomthingTextView.delegate = self
            if cell.writeSomthingTextView.text == "Write something here..."
            {
                cell.writeSomthingTextView.textColor = UIColor.lightGray
            }
            else
            {
                cell.writeSomthingTextView.textColor = UIColor.black
            }
            cell.writeSomthingTextView.backgroundColor = UIColor.white
            cell.writeSomthingTextView.tintColor = .black
            cell.containerView.layer.borderColor = UIColor.lightGray.cgColor
            
            let height = cell.photoCollectionView.collectionViewLayout.collectionViewContentSize.height
            cell.collectionHeightConstraint.constant = height
            cell.collectionHeightConstraint.constant = CGFloat(self.selectedImages.count * 140)
            
            cell.photoCollectionView.reloadData()
            groupPostTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            
            
            return cell
        }
        
        else if indexPath.section == 1 {
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell", for: indexPath) as? PostTableViewCell else { return UITableViewCell() }
            let post = posts[indexPath.row]
            cell.configurePostCell(with: post, index: indexPath.row)
            
            if !post.postContent.postVideoUrl.isEmpty{
                playVideo(videoUrl: URL(string: post.postContent.postVideoUrl[0])!, videoView: cell.videoContainerView)
            }

            let picOne = UITapGestureRecognizer(target: self, action: #selector(picOneTapped))
            cell.photoOneImageView.isUserInteractionEnabled = true
            cell.photoOneImageView.tag = indexPath.row
            cell.photoOneImageView.addGestureRecognizer(picOne)
            
            
            let picTwo = UITapGestureRecognizer(target: self, action: #selector(picTwoTapped))
            cell.photoTwoImageView.isUserInteractionEnabled = true
            cell.photoTwoImageView.tag = indexPath.row
            cell.photoTwoImageView.addGestureRecognizer(picTwo)
            
            
            let picThree = UITapGestureRecognizer(target: self, action: #selector(picThreeTapped))
            cell.photoThreeImageView.isUserInteractionEnabled = true
            cell.photoThreeImageView.tag = indexPath.row
            cell.photoThreeImageView.addGestureRecognizer(picThree)
            
            
            let picThreeOfThree = UITapGestureRecognizer(target: self, action: #selector(picThreeOfThreeTapped))
            cell.photoTwoOfTwoImageView.isUserInteractionEnabled = true
            cell.photoTwoOfTwoImageView.tag = indexPath.row
            cell.photoTwoOfTwoImageView.addGestureRecognizer(picThreeOfThree)
            
            cell.newCommentTextField.layer.borderColor = UIColor.lightGray.cgColor
            cell.newCommentTextField.layer.borderWidth = 1
            cell.newCommentTextField.tintColor = .black
            
            cell.commentBtnTap.addTarget(self, action: #selector(commentClick(_:)), for: .touchUpInside)
            cell.theeDotsBtnTap.addTarget(self, action: #selector(openActionsheet(_:)), for: .touchUpInside)
            cell.sendCommentButton.addTarget(self, action: #selector(createCommentClick(_:)), for: .touchUpInside)
            cell.reactToggleButton.addTarget(self, action: #selector(seeAllReactionsBtnTap(_:)), for: .touchUpInside)
            cell.moreImagesButton.addTarget(self, action: #selector(moreImages(_:)), for: .touchUpInside)
            
            
            return cell
        }
        else{
            return UITableViewCell()
        }
       
    }
    
    func textViewShouldReturn(textView: UITextView!) -> Bool {
            self.view.endEditing(true);
            return true;
        }
    
    @objc func picOneTapped(tapGestureRecognizer: UITapGestureRecognizer){
        
        let view = tapGestureRecognizer.view as! UIImageView
        let postImages = posts[view.tag].postContent.postImageUrls[0]
        self.postImages = [postImages]
        self.performSegue(withIdentifier: "imageListSegue", sender: nil)
        
    }
    
    @objc func picTwoTapped(tapGestureRecognizer: UITapGestureRecognizer){
        
        let view = tapGestureRecognizer.view as! UIImageView
        let postImages = posts[view.tag].postContent.postImageUrls[1]
        self.postImages = [postImages]
        self.performSegue(withIdentifier: "imageListSegue", sender: nil)
        
    }
    
    @objc func picThreeTapped(tapGestureRecognizer: UITapGestureRecognizer){
        
        let view = tapGestureRecognizer.view as! UIImageView
        let postImages = posts[view.tag].postContent.postImageUrls[2]
        self.postImages = [postImages]
        self.performSegue(withIdentifier: "imageListSegue", sender: nil)
        
    }
    
    @objc func picThreeOfThreeTapped(tapGestureRecognizer: UITapGestureRecognizer){
        
        let view = tapGestureRecognizer.view as! UIImageView
        let postImages = posts[view.tag].postContent.postImageUrls[1]
        self.postImages = [postImages]
        self.performSegue(withIdentifier: "imageListSegue", sender: nil)
        
    }
    
    @objc func seeAllReactionsBtnTap(_ sender: UIButton){
        
        let position: CGPoint = sender.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        let popUpVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "allReactionVC") as! AllReactionViewController
        popUpVC.modalPresentationStyle = .overCurrentContext
        popUpVC.modalTransitionStyle = .crossDissolve
        popUpVC.postDetails = posts[indexPath!.row]
        self.row = indexPath?.row
        popUpVC.groupDetails = self.groupDetails
        popUpVC.backDelegate = self
        present(popUpVC, animated: true, completion: nil)
        
    }
    
    @objc func commentClick(_ sender: UIButton){
        
        let position: CGPoint = sender.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        let cell: PostTableViewCell = groupPostTableView.cellForRow(at: indexPath!)! as! PostTableViewCell
        selectedPost = posts[indexPath!.row]
        self.row = indexPath?.row
        if (cell.numberOfCommentsLabel.text != "No Comments")
        {
            self.performSegue(withIdentifier: "commentListSegue", sender: nil)
        }
        
        
    }
    
    @objc func createCommentClick(_ sender: UIButton){
        
        let position: CGPoint = sender.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        let cell: PostTableViewCell = groupPostTableView.cellForRow(at: indexPath!)! as! PostTableViewCell
        if (cell.newCommentTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == false)
        {
            self.createComment(postID: posts[indexPath!.row].id!, content: cell.newCommentTextField.text ??  "")
            cell.newCommentTextField.text = ""
        }
       
    }
    
    func editPost(post: Post) {
        selectedPost = post
        self.performSegue(withIdentifier: "editPostSegue", sender: nil)
    }
    
    @objc func openActionsheet(_ sender: UIButton?) {
        
        let position: CGPoint = sender!.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        

        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)


        let firstAction: UIAlertAction = UIAlertAction(title: "Edit", style: .default) { action -> Void in

            self.row = indexPath?.row
            self.editPost(post: self.posts[indexPath!.row])

        }
        
        let redTextColor = UIColor.red
        let secondAction = ColoredAction(title: "Delete", style: .default, textColor: redTextColor) { (action) in
            self.deletePostAlert(postID: self.posts[indexPath!.row].id!, index: indexPath!)
        }

        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }


        actionSheetController.addAction(firstAction)
        actionSheetController.addAction(secondAction)
        actionSheetController.addAction(cancelAction)


        actionSheetController.popoverPresentationController?.sourceView = self.view

        present(actionSheetController, animated: true) {
            print("option menu presented")
        }
    }
    
    @objc func closeReactionView (){
        
    }
    
    
    @objc func uploadImages(_ sender: UIButton?){
        
        let position: CGPoint = sender!.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        let cell: ComposeMessageTableViewCell = groupPostTableView.cellForRow(at: indexPath!)! as! ComposeMessageTableViewCell
        
        cell.videoBtnView.isHidden = true
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
        
    }
    
    @objc func uploadVideo(_ sender: UIButton?){
        
        let position: CGPoint = sender!.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        let cell: ComposeMessageTableViewCell = groupPostTableView.cellForRow(at: indexPath!)! as! ComposeMessageTableViewCell
        
        cell.imgView.isHidden = true
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        
        present(imagePicker, animated: true)
        
    }
    
    @objc func deleteVideo(_ sender: UIButton?){
        
        let position: CGPoint = sender!.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        let cell: ComposeMessageTableViewCell = groupPostTableView.cellForRow(at: indexPath!)! as! ComposeMessageTableViewCell
        self.videoURL = nil
        cell.videoViewHeightConstraint.constant = CGFloat(40)
        cell.videoView.isHidden = true
        cell.imgView.isHidden = false
        cell.deleteVideoBtnView.isHidden = true
        
        let sectionIndex = 0
        groupPostTableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
        
    }
    
    @objc func imgTap(tapGesture: UITapGestureRecognizer) {
        let imgView = tapGesture.view as! UIImageView
        let idToMove = imgView.tag
        let cell: ComposeMessageTableViewCell = self.groupPostTableView.cellForRow(at: IndexPath(row: 0, section: 0))! as! ComposeMessageTableViewCell
        cell.playVideoImg.isHidden = true
        
    }
    
    @objc func publishPost(_ sender: UIButton){
        
        let position: CGPoint = sender.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        let cell: ComposeMessageTableViewCell = groupPostTableView.cellForRow(at: indexPath!)! as! ComposeMessageTableViewCell
        
        guard let unwrappedValue = cell.writeSomthingTextView.text else {
            print("Optional Value is nil")
            return
        }
        
        if (self.selectedImages.count > 0)
            
        {
            
            self.showActivityIndicator()
            var urls = [String]()
            self.uploadImagesToFirebaseStorage(images: self.selectedImages) { result in
                switch result {
                case .success(let downloadURLs):
                    print("Images uploaded successfully. Download URLs: \(downloadURLs)")
                    urls = downloadURLs
                    self.postDataToFirebase(dataType: self.MESSAGE_TYPE_IMAGE, content: ["content" : unwrappedValue, "url": urls])
                case .failure(let error):
                    print("Error uploading images: \(error.localizedDescription)")
                }
            }
            
        }
        else if (self.videoURL != nil)
        {
            
            self.showActivityIndicator()
            var urls = [String]()
            
            self.uploadVideoToFirebaseStorage(videoURL: self.videoURL!) { result in
                switch result {
                case .success(let downloadURLs):
                    print("Images uploaded successfully. Download URLs: \(downloadURLs)")
                    urls.append(downloadURLs.absoluteString)
                    self.postDataToFirebase(dataType: self.MESSAGE_TYPE_VIDEO, content: ["content" : unwrappedValue, "url": urls])
                case .failure(let error):
                    print("Error uploading video: \(error.localizedDescription)")
                    self.hideActivityIndicator()
                }
            }
            
            
        }
        else{
            self.showActivityIndicator()
            self.postDataToFirebase(dataType: self.MESSAGE_TYPE_TEXT, content: ["content" : unwrappedValue])
        }
        cell.writeSomthingTextView.text = ""
        cell.writeSomthingTextView.text = "Write something here..."
        
    }
    
    func deletePostAlert(postID: String, index: IndexPath){
        
        let refreshAlert = UIAlertController(title: "Delete Post!", message: "Are you sure you want to delete this post?", preferredStyle: UIAlertController.Style.alert)

        refreshAlert.addAction(UIAlertAction(title: "Sure", style: .default, handler: { (action: UIAlertAction!) in
            self.deletePost(postID: self.posts[index.row].id!, index: index)
        }))

        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
              print("Handle Cancel Logic here")
        }))

        present(refreshAlert, animated: true, completion: nil)
    }
    
    func deletePost(postID: String, index: IndexPath) {
        
        self.showActivityIndicator()
        let defaultStore = Firestore.firestore()
        let document = defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(postID)
        
        document.delete() { error in
            if let error = error {
                print("error creating comment", error)
                self.hideActivityIndicator()
            } else {
                print("sucessful getting a comment", index.row)
                self.posts.remove(at: index.row)
                self.groupPostTableView.reloadData()
                self.hideActivityIndicator()
                
            }
        }
    }
    
    @objc func deleteSeletedImage( sender: UIButton){
        
        let position: CGPoint = sender.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        let cell: ComposeMessageTableViewCell = groupPostTableView.cellForRow(at: indexPath!)! as! ComposeMessageTableViewCell
        cell.photoCollectionView.reloadData()
        
        let buttonTag = sender.tag
        print(buttonTag, selectedImages.count, "delete click")
        
        selectedImages.remove(at: buttonTag)
        let sectionIndex = 0
        groupPostTableView.reloadData()
        groupPostTableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
        
    }
    
    @objc func moreImages(_ sender: UIButton){
        
        let position: CGPoint = sender.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ImageGalleryViewController") as! ImageGalleryViewController
        vc.postImageUrls = self.posts[indexPath!.row].postContent.postImageUrls
        self.present(vc, animated: true, completion: nil)
    }
  
    func uploadImagesToFirebaseStorage(images: [UIImage], completion: @escaping (Result<[String], Error>) -> Void) {
        
        var uploadURLs: [String] = []
        var uploadErrors: [Error] = []
        
        let dispatchGroup = DispatchGroup()
        
        for image in images {
            dispatchGroup.enter()
            
            guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                uploadErrors.append(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"]))
                dispatchGroup.leave()
                continue
            }
            let imageName = String("\(randomString(length: 5)).png")
            let storageRef = Storage.storage().reference().child("grouppost/\(imageName)")
            
            let uploadTask = storageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    uploadErrors.append(error)
                    dispatchGroup.leave()
                } else {
                    storageRef.downloadURL { (url, error) in
                        if let error = error {
                            uploadErrors.append(error)
                        } else if let downloadURL = url {
                            uploadURLs.append(downloadURL.absoluteString)
                        }
                        dispatchGroup.leave()
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if !uploadErrors.isEmpty {
                completion(.failure(uploadErrors.first!))
            } else {
                completion(.success(uploadURLs))
            }
        }
    }
    
    func uploadVideoToFirebaseStorage(videoURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        
        
        let videoName = String("\(randomString(length: 5)).mp4")
        do {
            let data = try Data(contentsOf: videoURL)
            
            let storageRef = Storage.storage().reference().child("videos").child(videoName)
            if let uploadData = data as Data? {
                let metaData = StorageMetadata()
                metaData.contentType = "video/mp4"
                storageRef.putData(data, metadata: metaData) { metadata, error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        storageRef.downloadURL { (url, error) in
                            if let error = error {
                                completion(.failure(error))
                            } else if let downloadURL = url {
                                completion(.success(downloadURL))
                            }
                        }
                    }
                }
            }
        }catch let error {
            print(error.localizedDescription)
        }
        
    }
    
    func showActivityIndicator() {
        
        let backgroundView = UIView(frame: view.bounds)
           backgroundView.backgroundColor = UIColor(white: 0, alpha: 0.5)
           backgroundView.tag = 999
           view.addSubview(backgroundView)
           
           activityView = UIActivityIndicatorView(style: .large)
           activityView?.center = backgroundView.center
           activityView?.color = .white
           backgroundView.addSubview(activityView!)
           activityView?.startAnimating()
    }
    
    func hideActivityIndicator(){
        if let backgroundView = view.viewWithTag(999) {
        if (activityView != nil){
            activityView?.stopAnimating()
        }
        backgroundView.removeFromSuperview()
        }
    }
    
    func updateReactionToFirebase(index: Int,reaction: String){
        let post = posts[index]
        let groupId = self.groupDetails?.groupId ?? ""
        
        var thumbsUp = post.postReaction.thumbsUp
        var love = post.postReaction.love
        var laugh = post.postReaction.laugh
        var surprise = post.postReaction.surprise
        var sad = post.postReaction.sad
        var angry = post.postReaction.angry
        switch reaction{
        case "THUMB_UP": thumbsUp += 1
        case "LOVE": love += 1
        case "LAUGH": laugh += 1
        case "SURPRISE": surprise += 1
        case "SAD": sad += 1
        case "ANGRY": angry += 1
            
        default: print("Default")
        }
        
        let docRef = Firestore.firestore().collection("groups").document(groupId).collection("posts").document(post.id!)
        let reactions = [
            "THUMB_UP": thumbsUp,
            "LOVE": love,
            "SAD": sad,
            "ANGRY": angry,
            "SURPRISE": surprise,
            "LAUGH": laugh ]
        let chatData: [String:Any] = [
            "reactions": reactions
        ]
        
        docRef.updateData(chatData){ err in
            if err != nil {
                print("Error updating Profile. Try again.")
            } else {
                print("Profile updated successfully")
                switch reaction{
                case "THUMB_UP": post.postReaction.thumbsUp += 1
                case "LOVE": post.postReaction.love += 1
                case "LAUGH": post.postReaction.laugh += 1
                case "SURPRISE": post.postReaction.surprise += 1
                case "SAD": post.postReaction.sad += 1
                case "ANGRY": post.postReaction.angry += 1
                    
                default: print("Default")
                }
                DispatchQueue.main.async {
                    self.groupPostTableView.reloadData()
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? CommentViewController
        {
           destinationVC.backDelegate = self
           destinationVC.postDetails = selectedPost
           destinationVC.groupDetails = self.groupDetails
       }
        else if let destinationVC = segue.destination as? ImageGalleryViewController
        {
            destinationVC.postImageUrls = self.postImages
        }
        else if let destinationVC = segue.destination as? EditPostViewController
        {
            destinationVC.backDelegate = self
            destinationVC.postDetails = self.selectedPost
            destinationVC.groupDetails = self.groupDetails
        }
    }
}
extension String {
    func htmlAttributedString() -> String? {
        guard let data = self.data(using: String.Encoding.utf16, allowLossyConversion: false) else { return nil }
        guard let html = try? NSMutableAttributedString(
            data: data,
            options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil) else { return nil }
        return html.string
    }
}

extension GroupDetailsViewController: BackDelegate {
    func didComeBack() {
        self.showActivityIndicator()
        print("Came back to YourViewController!", row!)
        
        self.fetchPostsAndRefreshRow(section: 1, row: row!)
    }
}

extension GroupDetailsViewController: ReactionTableViewCellDelegate {
    func reactionButtonTapped(postID: String, isLiked: Bool) {
        addReaction(postID: postID, isLiked: isLiked)
    }
}
class ColoredAction: UIAlertAction {
    convenience init(title: String?, style: UIAlertAction.Style, textColor: UIColor, handler: ((UIAlertAction) -> Void)?) {
        self.init(title: title, style: style, handler: handler)
        self.setValue(textColor, forKey: "titleTextColor")
    }
}

extension Array where Element: Post {
    func removingDuplicates() -> [Element] {
        var uniquePosts = [String: Element]()
        
        for post in self {
            if let postID = post.id {
                uniquePosts[postID] = post
            }
        }
        return Array(uniquePosts.values)
    }
}
