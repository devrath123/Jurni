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


class GroupDetailsViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextViewDelegate {
    
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
    var selectedImages: [UIImage] = []
    var videoURL: URL?
    
    let MESSAGE_TYPE_TEXT = "text"
    let MESSAGE_TYPE_IMAGE = "image"
    let MESSAGE_TYPE_VIDEO = "video"
    
    var previousSmileyIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        groupPostTableView.dataSource = self
        groupPostTableView.delegate = self
        imagePicker.delegate = self
        
//        showActivityIndicator()
        groupPostTableView.rowHeight = UITableView.automaticDimension
        self.groupPostTableView.estimatedRowHeight = 100
        let headerNib = UINib(nibName: "ComposeMessageTableViewCell", bundle: nil)
        groupPostTableView.register(headerNib, forCellReuseIdentifier: "ComposeMessageTableViewCell")

        let nib = UINib(nibName: "PostTableViewCell", bundle: nil)
        groupPostTableView.register(nib, forCellReuseIdentifier: "PostTableViewCell")
        fetchPosts()
        
        groupPostTableView.backgroundColor = UIColor.white
        groupNameLabel.text = groupDetails?.groupName
        membersCountLabel.text =  "\(groupDetails?.membersCount ?? 0) MEMBERS"
    }
    
    // MARK: - Methods
    
    func fetchPosts(){
        let defaultStore = Firestore.firestore()
        print("Group id: \(self.groupDetails?.groupId)")
        defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").getDocuments(){ (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err) :(")
            } else {
                if let documents = querySnapshot?.documents {
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
                        /// User id format example - from: /users/lzlXd3G5vhUFj1HIEjcmuLVLG4g1
                        /// needs UID to be retrieved as corresponding user's username
                        if let reactionsData = document.get("reactions") as? [String:Any] {
                            let reactions = PostReaction(
                                angry: reactionsData["ANGRY"] as? Int ?? 0,
                                laugh: reactionsData["LAUGH"] as? Int ?? 0,
                                love: reactionsData["LOVE"] as? Int ?? 0,
                                sad: reactionsData["SAD"] as? Int ?? 0,
                                surprise: reactionsData["SURPRISE"] as? Int ?? 0,
                                thumbsUp: reactionsData["THUMB_UP"] as? Int ?? 0
                            )
                           
                            
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
                                        
                                        let postUser = User(userName: userName, userAvatar: userImage)
                                        
                                        let post = Post(postType: postType ?? "", postTime: postTime, postContent: PostContent(postText: postText, postImageUrls: imageArray, postVideoUrl: videoArray), user: postUser, postReaction: reactions)
                                        
                                        post.id = id
                                        
                                        self.posts.append(post)
                                        
                                        self.posts = self.posts.sorted(by: { $0.postTime.compare($1.postTime as Date) == .orderedDescending })
                                        self.hideActivityIndicator()
                                        self.groupPostTableView.reloadData()
                                    } else {
                                        print("User document not found for UID: \(uid)")
                                        self.hideActivityIndicator()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func createComment(postID: String,content: String) {
        
        let defaultStore = Firestore.firestore()
        let document = defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(postID).collection("comments").document()
        let dataToSend : [String: Any] = ["content": content,"from": Auth.auth().currentUser!.uid, "timestamp":FieldValue.serverTimestamp()]
        document.setData(dataToSend) { error in
            if let error = error {
                print("error creating comment")
            } else {
                print("sucessful getting a comment")
                
            }
        }
    }
    func addReaction(postID: String, isLiked: Bool) {
        print("Attempting to add this reaction \(isLiked), to this postID: \(postID)")
       
    }

    
    @IBAction func backClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func playVideo(videoUrl: String, videoView: UIView){
        let videoUrl = URL(string: videoUrl)
        if(videoUrl != nil){
            player = AVPlayer(url: videoUrl!)
            avpPlayerController.player = player
            avpPlayerController.view.frame.size.height = videoView.frame.size.height
            avpPlayerController.view.frame.size.width = videoView.frame.size.width

                        videoView.addSubview(avpPlayerController.view)
            player.play()
        }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if results.count == 0 {
            // User canceled out of picker
            print("User canceled")
            selectedImages = []
          //  delegate?.resetCells()
        }else{
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                    if let image = object as? UIImage {
                        self.selectedImages.append(image)
                        DispatchQueue.main.async {
                            self.groupPostTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
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
           // tableView.reloadData()
        }
        
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      //  delegate?.resetCells()
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
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 5 * 3600 + 30 * 60) // UTC+5:30
        let date = Date() // Replace this with your specific Date object
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
            
            
            let photoNib = UINib(nibName: "PhotoCollectionViewCell", bundle: nil)
            cell.photoCollectionView.register(photoNib, forCellWithReuseIdentifier: "PhotoCollectionViewCell")
            
            
            
            cell.uploadPhotoBtn.addTarget(self, action: #selector(uploadImages(_:)), for: .touchUpInside)
            cell.uploadVideoBtn.addTarget(self, action: #selector(uploadVideo(_:)), for: .touchUpInside)
            cell.publishBtn.addTarget(self, action: #selector(publishPost(_:)), for: .touchUpInside)
            
            cell.writeSomthingTextView.attributedPlaceholder = NSAttributedString(
                string: "Write something here...",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
            )
            cell.containerView.layer.borderColor = UIColor.lightGray.cgColor
            
            
            let height = cell.photoCollectionView.collectionViewLayout.collectionViewContentSize.height
            cell.collectionHeightConstraint.constant = height
            cell.collectionHeightConstraint.constant = CGFloat(self.selectedImages.count * 140)
            
            cell.photoCollectionView.reloadData()
            groupPostTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            
            
            return cell
        }
        
        else{
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell", for: indexPath) as? PostTableViewCell else { return UITableViewCell() }
            let post = posts[indexPath.row]
            //        cell.delegate = self
            cell.configurePostCell(with: post, index: indexPath.row)
            print("Refresh for position: \(indexPath.row)")
            
            if !post.postContent.postVideoUrl.isEmpty{
//                playVideo(videoUrl: post.postContent.postVideoUrl[0], videoView: cell.videoContainerView)
            }
            cell.createCommentHandler = { postId, text in
                self.createComment(postID: postId, content: text)
            }
            cell.commentBtnTap.addTarget(self, action: #selector(commentClick(_:)), for: .touchUpInside)
            cell.reactionHandler = {index, reaction in
                self.updateReactionToFirebase(index: index, reaction: reaction)
            }
            
            return cell
        }
        
        
    }
    
    @objc func commentClick(_ sender: UIButton){
            let position: CGPoint = sender.convert(.zero, to: self.groupPostTableView)
            let indexPath = self.groupPostTableView.indexPathForRow(at: position)
            selectedPost = posts[indexPath!.row]

            self.performSegue(withIdentifier: "commentListSegue", sender: nil)
        }
    
    
    @objc func uploadImages(_ sender: UIButton?){
        
//        var position: CGPoint = sender!.convert(.zero, to: self.groupPostTableView)
//        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
//        let cell: ComposeMessageTableViewCell = groupPostTableView.cellForRow(at: indexPath!)! as! ComposeMessageTableViewCell
//
//        cell.videoView.isHidden = true
//        var configuration = PHPickerConfiguration()
//        configuration.selectionLimit = 0  // 0 means no limit
//        configuration.filter = .images
//
//        let picker = PHPickerViewController(configuration: configuration)
//        picker.delegate = self
//        self.present(picker, animated: true, completion: nil)
        
    }
    
    
    
    @objc func uploadVideo(_ sender: UIButton?){
        
        var position: CGPoint = sender!.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        let cell: ComposeMessageTableViewCell = groupPostTableView.cellForRow(at: indexPath!)! as! ComposeMessageTableViewCell
        
        cell.videoView.isHidden = true
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0  // 0 means no limit
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
        
    }
    
    @objc func publishPost(_ sender: UIButton){
        
        let position: CGPoint = sender.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        let cell: ComposeMessageTableViewCell = groupPostTableView.cellForRow(at: indexPath!)! as! ComposeMessageTableViewCell
        
        //        let text = cell.writeSomthingTextView.text
        
        
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
            
        }
        else{
            self.showActivityIndicator()
            self.postDataToFirebase(dataType: self.MESSAGE_TYPE_TEXT, content: ["content" : unwrappedValue])
        }
        cell.writeSomthingTextView.text = ""
        cell.writeSomthingTextView.placeholder = "Write something here..."
        
    }
    
    
    
    @objc func deleteSeletedImage( sender: UIButton){
        
        var position: CGPoint = sender.convert(.zero, to: self.groupPostTableView)
        let indexPath = self.groupPostTableView.indexPathForRow(at: position)
        let cell: ComposeMessageTableViewCell = groupPostTableView.cellForRow(at: indexPath!)! as! ComposeMessageTableViewCell
        cell.photoCollectionView.reloadData()
        
        let buttonTag = sender.tag
        print(buttonTag, selectedImages.count, "delete click")
        
        selectedImages.remove(at: buttonTag)
        let sectionIndex = 0 // Change this to your specific section index
        groupPostTableView.reloadData()
        groupPostTableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
        
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
            
            // Create a unique name for the image (e.g., using a timestamp)
            let imageName = String("\(randomString(length: 5)).png")
            
            // Reference to the Firebase Storage bucket
            let storageRef = Storage.storage().reference().child("grouppost/\(imageName)")
            
            // Upload the image data to Firebase Storage
            let uploadTask = storageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    uploadErrors.append(error)
                    dispatchGroup.leave()
                } else {
                    // Once the upload is complete, get the download URL
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
            
            // You can also observe the upload progress if needed
            //            uploadTask.observe(.progress) { snapshot in
            //                let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            //                print("Upload progress: \(percentComplete)%")
            //            }
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
        let storageRef = Storage.storage().reference()
        
        // Create a unique name for the video (e.g., using a timestamp)
        let videoName = String("\(randomString(length: 5)).mp4")
        
        // Reference to the Firebase Storage bucket with the video's name
        let videoRef = storageRef.child("video/\(videoName)")
        
        // Upload the video file
        DispatchQueue.main.async {
            let uploadTask = videoRef.putFile(from: videoURL, metadata: nil) { (metadata, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    // Once the upload is complete, get the download URL
                    videoRef.downloadURL { (url, error) in
                        if let error = error {
                            completion(.failure(error))
                        } else if let downloadURL = url {
                            completion(.success(downloadURL))
                        }
                    }
                }
            }
        }
    }
    
    
    func showActivityIndicator() {
        activityView = UIActivityIndicatorView(style: .large)
        activityView?.center = self.view.center
        activityView?.color = .black
        self.view.addSubview(activityView!)
        activityView?.startAnimating()
    }
    
    func hideActivityIndicator(){
        if (activityView != nil){
            activityView?.stopAnimating()
        }
    }
    
    func updateReactionToFirebase(index: Int,reaction: String){
        let post = posts[index]
        let groupId = self.groupDetails?.groupId ?? ""
        print("Index: \(index) Post : \(reaction)")
        
        var thumbsUp = post.postReaction.thumbsUp
        var love = post.postReaction.love
        var laugh = post.postReaction.laugh
        var surprise = post.postReaction.surprise
        var sad = post.postReaction.sad
        var angry = post.postReaction.angry
        switch reaction{
            case "THUMBS_UP": thumbsUp += 1
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
                   case "THUMBS_UP": post.postReaction.thumbsUp += 1
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
            let destinationVC = segue.destination as! CommentViewController
            destinationVC.postDetails = selectedPost
            destinationVC.groupDetails = self.groupDetails
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

extension GroupDetailsViewController: ReactionTableViewCellDelegate {
 func reactionButtonTapped(postID: String, isLiked: Bool) {
 addReaction(postID: postID, isLiked: isLiked)
  }
}
