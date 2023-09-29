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

class GroupDetailsViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var membersCountLabel: UILabel!
    @IBOutlet weak var groupPostTableView: UITableView!
    
    // MARK: - Properties
    var groupDetails: Group?
    var player: AVPlayer!
    var avpPlayerController = AVPlayerViewController()
    var posts: [Post] = []
    
    let imagePicker = UIImagePickerController()
    var selectedImages: [UIImage] = []
    var videoURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        groupPostTableView.dataSource = self
        groupPostTableView.delegate = self
        imagePicker.delegate = self
        
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
                                        
                                        self.groupPostTableView.reloadData()
                                    } else {
                                        print("User document not found for UID: \(uid)")
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
//                        if (results.count == self.selectedImages.count){
//                            self.postCellImageDelegate?.setImages(images: self.selectedImages)
//                        }
                    }
                    
                    
                }
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
        
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "MMMM d, yyyy 'at' h:mm:ss a 'UTC'ZZZZZ"
//        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//        dateFormatter.timeZone = TimeZone(secondsFromGMT: 5 * 3600 + 30 * 60) // UTC+5:30
//        let date = Date() // Replace this with your specific Date object
//        let timestamp = dateFormatter.string(from: date)
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
                DispatchQueue.global().async {
                    self.fetchPosts()
                }
            }
        }
    }
}

extension GroupDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell", for: indexPath) as? PostTableViewCell else { return UITableViewCell() }
        let post = posts[indexPath.row]
        cell.delegate = self
        cell.configurePostCell(with: post)
        
        if !post.postContent.postVideoUrl.isEmpty{
          //  playVideo(videoUrl: post.postContent.postVideoUrl[0], videoView: cell.videoContainerView)
        }
        cell.createCommentHandler = { postId, text in
            self.createComment(postID: postId, content: text)
            
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerCell = tableView.dequeueReusableCell(withIdentifier: "ComposeMessageTableViewCell") as! ComposeMessageTableViewCell
        headerCell.groupDetails = self.groupDetails
       // headerCell.apiCallDelegate = self
       
        headerCell.selectImageHandler = {
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 0  // 0 means no limit
            configuration.filter = .images
            
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
        return headerCell
        
        }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 250
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


//extension GroupDetailsViewController: ApiCallDelegate{
////    func resetCells() {
////
////    }
////
////    func setImages(images: [UIImage]) {
////
////    }
//
//    func postMessage(message: String){
//        self.postDataToFirebase(dataType: "text", content: ["content" : message])
//    }
//}
