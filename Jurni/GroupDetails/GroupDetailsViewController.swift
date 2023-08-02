//
//  GroupDetailsViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 27/02/23.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import AVKit

class GroupDetailsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var membersCountLabel: UILabel!
    @IBOutlet weak var groupPostTableView: UITableView!
    var groupDetails: Group? = nil
    var postArray = [Post]()
    var player: AVPlayer!
    var avpPlayerController = AVPlayerViewController()
    let imageLoaderCache = ImageCacheLoader()
    
    let POST_TYPE_IMAGE = "image"
    let POST_TYPE_VIDEO = "video"
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        groupPostTableView.backgroundColor = UIColor.white
        
        let postNib = UINib(nibName: "PostTableViewCell", bundle: nil)
        groupPostTableView.register(postNib, forCellReuseIdentifier: "PostTableViewCell")
       
        groupNameLabel.text = groupDetails?.groupName
        membersCountLabel.text =  "\(groupDetails?.membersCount ?? 0) MEMBERS"
        
        fetchGroupPost()
    }
    
    func fetchGroupPost(){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        defaultStore?.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").getDocuments(){ (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                print("************ Posts ************")
                let jurniGroup =  DispatchGroup()
                for document in querySnapshot!.documents {
                    print("\(document.documentID) ==> \(document.data())")
                    
                    var reaction = PostReaction()
                    if(document.get("reactions") != nil){
                        let reactions = document.get("reactions") as! NSDictionary
                        if(reactions["ANGRY"] != nil){
                            if let angry = reactions["ANGRY"] as? Int{
                                reaction.angry = angry
                            }
                        }
                        
                        if(reactions["LAUGH"] != nil){
                            if let laugh = reactions["LAUGH"] as? Int{
                                reaction.laugh = laugh
                            }
                        }
                        
                        if(reactions["SAD"] != nil){
                            if let sad = reactions["SAD"] as? Int{
                                reaction.sad = sad
                            }
                        }
                        
                        if(reactions["LOVE"] != nil){
                            if let love = reactions["LOVE"] as? Int{
                                reaction.love = love
                            }
                        }
                        
                        if(reactions["SURPRISE"] != nil){
                            if let surprise = reactions["SURPRISE"] as? Int{
                                reaction.surprise = surprise
                            }
                        }
                        
                        if(reactions["THUMB_UP"] != nil){
                            if let thumbs = reactions["THUMB_UP"] as? Int{
                                reaction.thumbsUp = thumbs
                            }
                        }
                    }
                    
                    let type = document.get("type") as? String
                    let groupMeta : [String : Any] = document.get("meta") as! [String : Any]
                    let postText = groupMeta["content"] as? String
                   // let postUrl = groupMeta["url"] as? String
                    
                    var user = User()
                    var postContent = PostContent()
                    postContent.postText = postText?.htmlAttributedString() ?? ""
                    
                    if(groupMeta["url"] != nil ){
                        if let urlArray = groupMeta["url"] as? [String]{
                            for post in urlArray{
                                if(type == self.POST_TYPE_IMAGE){
                                    postContent.postImageUrls.append(post)
                                }else{
                                    postContent.postVideoUrl.append(post)
                                }
                            }
                        }
                    }
                    
                    let time = document.get("timestamp") as! Timestamp
                    let postDate : Date = time.dateValue()
                    
                    let postFrom = document.get("from") as! DocumentReference
                    let postFromArray = postFrom.path.components(separatedBy: "/")
                    let postOwner = postFromArray.last ?? ""
                    
                    jurniGroup.enter()
                    let docRef = defaultStore?.collection("users").document(postOwner)
                    docRef!.getDocument { (document, error) in
                        if let document = document, document.exists {
                            
                            var userName: String = ""
                            var userAvatar: String = ""
                            if(document.get("firstName") as? String != nil){
                                userName = document.get("firstName") as? String ?? ""
                            }
                            
                            if(document.get("lastName") as? String != nil){
                                userName += " " + (document.get("lastName") as? String ?? "")
                            }
                            
                            if(document.get("avatar") as? String != nil && document.get("avatar") as? String != ""){
                                userAvatar = document.get("avatar") as! String
                            }
                            
                            user.userName = userName
                            user.userAvatar = userAvatar
                            
                            self.postArray.append(Post(postType: type ?? "", postTime: postDate, postContent: postContent, user: user, postReaction: reaction ))
                            jurniGroup.leave()
                        }
                    }
                }
                jurniGroup.notify(queue: .main) {
                    self.postArray = self.postArray.sorted(by: { $0.postTime.compare($1.postTime as Date) == .orderedDescending })
                    self.groupPostTableView.reloadData()
                }
            }
        }
    }
    

    @IBAction func backClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = postArray[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell", for: indexPath) as! PostTableViewCell
        cell.postTextLabel.text = post.postContent.postText
        cell.userNameLabel.text = post.user.userName
        cell.postTimeLabel.text = self.getMessagePostedDay(date: post.postTime)
        
        if(post.user.userAvatar == ""){
            cell.userInitialLabel.isHidden = false
            cell.userInitialLabel.text = String(post.user.userName.prefix(1))
            cell.userImageView?.layer.cornerRadius = (cell.userImageView?.frame.size.width)! / 2
            cell.userImageView?.layer.masksToBounds = true
            cell.userImageView?.layer.backgroundColor = UIColor.lightGray.cgColor
        }else{
            cell.userInitialLabel.isHidden = true
            let avatarUrl = URL(string:  post.user.userAvatar)
            cell.userImageView?.layer.cornerRadius = (cell.userImageView?.frame.size.width)! / 2
            cell.userImageView?.layer.masksToBounds = true
            DispatchQueue.global().async {
                           let data = try? Data(contentsOf: avatarUrl!)
                if (data != nil){
                    DispatchQueue.main.async {
                        cell.userImageView.image = UIImage(data: data!)
                    }
                }
            }
        }
        
        cell.postImagesStackView.isHidden = true
        cell.videoView.isHidden = true
        cell.moreImageView.isHidden = true
        
        switch post.postType{
            case POST_TYPE_IMAGE:
                cell.postImagesStackView.isHidden = false
                switch post.postContent.postImageUrls.count {
                    case 1:
                            cell.imagesBottomView.isHidden = true
                            setImage(url: post.postContent.postImageUrls[0], imageView: cell.firstImageView)
                
                    case 2:
                            cell.imagesTopView.isHidden = true
                            setImage(url: post.postContent.postImageUrls[0], imageView: cell.secondImageView)
                            setImage(url: post.postContent.postImageUrls[1], imageView: cell.thirdImageView)
                
                    case 3:
                            setImage(url: post.postContent.postImageUrls[0], imageView: cell.firstImageView)
                            setImage(url: post.postContent.postImageUrls[1], imageView: cell.secondImageView)
                            setImage(url: post.postContent.postImageUrls[2], imageView: cell.thirdImageView)
                
                case 4..<100:
                        cell.moreImageView.isHidden = false
                        cell.imageCountLabel.text = "\(post.postContent.postImageUrls.count - 3)"
                        setImage(url: post.postContent.postImageUrls[0], imageView: cell.firstImageView)
                        setImage(url: post.postContent.postImageUrls[1], imageView: cell.secondImageView)
                        setImage(url: post.postContent.postImageUrls[2], imageView: cell.thirdImageView)
                
                    default: print("Default")
                }
            case POST_TYPE_VIDEO:
                cell.videoView.isHidden = false
                let videoTapped = UITapGestureRecognizer(target: self, action: #selector(videoTapped))
                cell.videoView.tag = indexPath.row
                cell.videoView.addGestureRecognizer(videoTapped)
            
            default: print("Other")
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300//UITableView.automaticDimension
    }
    
    @objc func videoTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view!
        let post = postArray[view.tag]
        playVideo(videoUrl: post.postContent.postVideoUrl, videoView: view)
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
    
    func getMessagePostedDay(date: Date) -> String{
        let diffInDays: Int = Calendar.current.dateComponents([.day], from: date, to: Date()).day!
        var day : String = ""
        
        switch diffInDays{
            case 0: day = "Today"
            case 1: day = "1 day ago"
            case 2..<32: day = "\(diffInDays) days ago"
            case 33..<366: day = "\(diffInDays/30) months ago"
            default: day = "\(diffInDays/365) year ago"
            }
        return day
    }
    
    func setImage(url: String, imageView: UIImageView){
//        let url = URL(string:  url)
//        DispatchQueue.global().async {
//            let data = try? Data(contentsOf: url!)
//            if (data != nil){
//                DispatchQueue.main.async {
//                    imageView.image = UIImage(data: data!)
//                }
//            }
//        }
        
        if(url != ""){
            imageLoaderCache.obtainImageWithPath(imagePath: url) { (image) in
               // if let updateCell = tableView.cellForRow(at: indexPath) {
                    imageView.image = image
               // }
            }
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
