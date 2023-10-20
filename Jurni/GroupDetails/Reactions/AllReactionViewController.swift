//
//  AllReactionViewController.swift
//  Jurni
//
//  Created by Yatharth Singh on 13/10/23.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class AllReactionViewController: UIViewController {
    
    
    var postDetails: Post?
    var groupDetails: Group?
    var myReactions = [String: Bool]()
    weak var backDelegate: BackDelegate?
    var myOldReaction = ""
    var activityView: UIActivityIndicatorView?
    @IBOutlet weak var reactionMainView: UIView!
    @IBOutlet weak var allReactionView: UIView!
    @IBOutlet weak var allReactionCountLbl: UILabel!
    @IBAction func allReactionBtnTap(_ sender: Any) {
    }
    
    @IBOutlet weak var loveView: UIView!
    @IBOutlet weak var loveCountLbl: UILabel!
    @IBAction func loveBtnTap(_ sender: Any) {
      
            updateReactionToFirebase(newReaction: "LOVE", oldReaction: self.myOldReaction)
        
        
    }
    
    @IBOutlet weak var thumbsUpView: UIView!
    @IBOutlet weak var thumbsUpCountLbl: UILabel!
    @IBAction func thumbsUpBtnTap(_ sender: Any) {
      
            updateReactionToFirebase(newReaction: "THUMB_UP", oldReaction: self.myOldReaction)
        
    }
    
    
    @IBOutlet weak var surpriseView: UIView!
    @IBOutlet weak var surpriseCountLbl: UILabel!
    @IBAction func surpriseBtnTap(_ sender: Any) {
    
            updateReactionToFirebase(newReaction: "SURPRISE", oldReaction: self.myOldReaction)
    
    }
    
    
    @IBOutlet weak var laughView: UIView!
    @IBOutlet weak var laughCountLbl: UILabel!
    @IBAction func laughBtnTap(_ sender: Any) {
    
            updateReactionToFirebase(newReaction: "LAUGH", oldReaction: self.myOldReaction)
    
    }
    
    @IBOutlet weak var sadView: UIView!
    @IBOutlet weak var sadCountLbl: UILabel!
    @IBAction func sadBtnTap(_ sender: Any) {
      
            updateReactionToFirebase(newReaction: "SAD", oldReaction: self.myOldReaction)
    
    }
    
    @IBOutlet weak var angryView: UIView!
    @IBOutlet weak var angryCountLbl: UILabel!
    @IBAction func angryBtnTap(_ sender: Any) {
       
            updateReactionToFirebase(newReaction: "ANGRY", oldReaction: self.myOldReaction)
        
    }
   
   
    
    
    
    
    
    
    
    
    
    
    @IBAction func closeBtnTap(_ sender: Any) {
        backDelegate?.didComeBack()
        self.dismiss(animated: true, completion: nil)
    
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isOpaque = false
        view.backgroundColor = .clear
        self.reactionMainView.layer.cornerRadius = 5
        self.reactionMainView.layer.masksToBounds = true
        // Do any additional setup after loading the view.
        self.showAllReactions()
        self.getAllReactions()
        
        var totalReactions: Int{
            return postDetails!.postReaction.angry + postDetails!.postReaction.laugh + postDetails!.postReaction.love + postDetails!.postReaction.sad + postDetails!.postReaction.surprise + postDetails!.postReaction.thumbsUp
        }
        
        if (totalReactions > 0)
        {
            self.allReactionView.isHidden = false
            self.allReactionCountLbl.text = "All \(totalReactions)"
        }
        
        if (postDetails!.postReaction.love > 0)
        {
            self.loveView.isHidden = false
            self.loveCountLbl.text = "❤️ \(postDetails!.postReaction.love)"
        }
        if (postDetails!.postReaction.sad > 0)
        {
            self.sadView.isHidden = false
            self.sadCountLbl.text = "☹️ \(postDetails!.postReaction.sad)"
        }
        if (postDetails!.postReaction.thumbsUp > 0)
        {
            self.thumbsUpView.isHidden = false
            self.thumbsUpCountLbl.text = "👍 \(postDetails!.postReaction.thumbsUp)"
        }
        if (postDetails!.postReaction.angry > 0)
        {
            self.angryView.isHidden = false
            self.angryCountLbl.text = "😠 \(postDetails!.postReaction.angry)"
        }
        if (postDetails!.postReaction.surprise > 0)
        {
            self.surpriseView.isHidden = false
            self.surpriseCountLbl.text = "😯 \(postDetails!.postReaction.surprise)"
        }
        if (postDetails!.postReaction.laugh > 0)
        {
            self.laughView.isHidden = false
            self.laughCountLbl.text = "😀 \(postDetails!.postReaction.laugh)"
        }
        
        
    }
    
    
    func showAllReactions (){
      
            self.loveCountLbl.text = "❤️"
            self.sadCountLbl.text = "☹️"
            self.thumbsUpCountLbl.text = "👍"
            self.angryCountLbl.text = "😠"
            self.surpriseCountLbl.text = "😯"
            self.laughCountLbl.text = "😀"
      
    }
    
    func getAllReactions() {
        let defaultStore = Firestore.firestore()
        defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(self.postDetails?.id ?? "").collection("reactions").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting reactions documents: \(err)")
            } else {
                if let documents = querySnapshot?.documents {
                    var reactionsArray = [String: Bool].self

                    for document in documents {
                        let id = document.documentID
                        let data = document.data()

                        if let reaction = data as? [String: Bool] {
                           
                            self.myReactions = reaction
                            
                            for (reaction, isSelected) in self.myReactions {
                                if isSelected{
                                    self.myOldReaction = reaction
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
    
    
    func updateMyReactionCollection(reaction: String){
        let post = postDetails
        let groupId = self.groupDetails?.groupId ?? ""
        
        var thumbsUp = self.myReactions["THUMB_UP"]
        var love = self.myReactions["LOVE"]
        var laugh = self.myReactions["LAUGH"]
        var surprise = self.myReactions["SURPRISE"]
        var sad = self.myReactions["SAD"]
        var angry = self.myReactions["ANGRY"]
        
        switch reaction {
            case "THUMB_UP":
                if thumbsUp == true {
                    thumbsUp = false
                } else {
                    thumbsUp = true
                    love = false
                    laugh = false
                    surprise = false
                    sad = false
                    angry = false
                }
            case "LOVE":
                if love == true {
                    love = false
                } else {
                    love = true
                    thumbsUp = false
                    laugh = false
                    surprise = false
                    sad = false
                    angry = false
                }
            case "LAUGH":
            if laugh == true {
                laugh = false
            } else {
                love = false
                thumbsUp = false
                laugh = true
                surprise = false
                sad = false
                angry = false
            }
            case "SURPRISE":
            if surprise == true {
                surprise = false
            } else {
                love = false
                thumbsUp = false
                laugh = false
                surprise = true
                sad = false
                angry = false
            }
            case "SAD":
            if sad == true {
                sad = false
            } else {
                love = false
                thumbsUp = false
                laugh = false
                surprise = false
                sad = true
                angry = false
            }
            case "ANGRY":
            if angry == true {
                angry = false
            } else {
                love = false
                thumbsUp = false
                laugh = false
                surprise = false
                sad = false
                angry = true
            }
            default:
                print("Default")
        }
        
        
        let from = "\(post!.id!)_"+Auth.auth().currentUser!.uid
        
        
        let docRef = Firestore.firestore().collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(post!.id!).collection("reactions").document(from)
        let reactions = [
            "THUMB_UP": thumbsUp,
            "LOVE": love,
            "SAD": sad,
            "ANGRY": angry,
            "SURPRISE": surprise,
            "LAUGH": laugh ]
        
        docRef.updateData(reactions as [AnyHashable : Any]){ err in
            if err != nil {
                print("Error updating Profile. Try again.")
            } else {
                print("my reaction collection updated successfully")
                
                DispatchQueue.main.async {
                    self.viewDidLoad()
//                    self.postMyReactionToCollection()
                }
            }
        }
    }
    
    
    func postMyReactionToCollection(reaction: String){
        
        var thumbsUp = false
        var love = false
        var laugh = false
        var surprise = false
        var sad = false
        var angry = false
       
        switch reaction {
            case "THUMB_UP":
                    thumbsUp = true
                    love = false
                    laugh = false
                    surprise = false
                    sad = false
                    angry = false
            case "LOVE":
                    love = true
                    thumbsUp = false
                    laugh = false
                    surprise = false
                    sad = false
                    angry = false
            case "LAUGH":
                love = false
                thumbsUp = false
                laugh = true
                surprise = false
                sad = false
                angry = false
            case "SURPRISE":
                love = false
                thumbsUp = false
                laugh = false
                surprise = true
                sad = false
                angry = false
            case "SAD":
                love = false
                thumbsUp = false
                laugh = false
                surprise = false
                sad = true
                angry = false
            case "ANGRY":
                love = false
                thumbsUp = false
                laugh = false
                surprise = false
                sad = false
                angry = true
            default:
                print("Default")
        }
        
        let reactions = [
            "THUMB_UP": thumbsUp,
            "LOVE": love,
            "SAD": sad,
            "ANGRY": angry,
            "SURPRISE": surprise,
            "LAUGH": laugh ]
        
        let post = postDetails
        let groupId = self.groupDetails?.groupId ?? ""
        print("post id: \(post!.id!)")
        let from = "\(post!.id!)_"+Auth.auth().currentUser!.uid

        
        let defaultStore = Firestore.firestore()
        let document = defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(post!.id!).collection("reactions").document(from)

        document.setData(reactions) { error in
            if let error = error {
                print("error creating comment")
            } else {
                print("sucessful getting a comment")
            
                DispatchQueue.main.async {
                    self.viewDidLoad()

                }

                
            }
        }
    
    }

    
    func updateReactionToFirebase(newReaction: String, oldReaction: String){
        let post = postDetails
        let groupId = self.groupDetails?.groupId ?? ""
        
        var thumbsUp = post!.postReaction.thumbsUp
        var love = post!.postReaction.love
        var laugh = post!.postReaction.laugh
        var surprise = post!.postReaction.surprise
        var sad = post!.postReaction.sad
        var angry = post!.postReaction.angry
        
        print(thumbsUp, love, laugh, surprise, sad, angry, "old counts", myOldReaction)
        
        if newReaction == oldReaction
        {
           
            switch oldReaction{
            case "THUMB_UP":
                thumbsUp -= 1
            case "LOVE":
                love -= 1
            case "LAUGH":
                laugh -= 1
            case "SURPRISE":
                surprise -= 1
            case "SAD":
                sad -= 1
            case "ANGRY":
                angry -= 1
            default:
                print("Default")
            }

        }
        else{
            
            switch oldReaction{
            case "THUMB_UP":
                thumbsUp -= 1
            case "LOVE":
                love -= 1
            case "LAUGH":
                laugh -= 1
            case "SURPRISE":
                surprise -= 1
            case "SAD":
                sad -= 1
            case "ANGRY":
                angry -= 1
            default:
                print("Default")
            }
            
            switch newReaction{
            case "THUMB_UP":
                thumbsUp += 1
            case "LOVE":
                love += 1
            case "LAUGH":
                laugh += 1
            case "SURPRISE":
                surprise += 1
            case "SAD":
                sad += 1
            case "ANGRY":
                angry += 1
            default:
                print("Default")
            }
        }
       
        
        myOldReaction = newReaction
        if oldReaction == newReaction
        {
            myOldReaction = ""
        }
        
         post!.postReaction.thumbsUp = thumbsUp
         post!.postReaction.love = love
         post!.postReaction.laugh = laugh
         post!.postReaction.surprise = surprise
         post!.postReaction.sad = sad
         post!.postReaction.angry = angry
        
        let from = "\(post!.id!)_"+Auth.auth().currentUser!.uid
        
        
        let docRef = Firestore.firestore().collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(post!.id!).collection("reactions").document(from)
        let reactions = [
            "THUMB_UP": thumbsUp,
            "LOVE": love,
            "SAD": sad,
            "ANGRY": angry,
            "SURPRISE": surprise,
            "LAUGH": laugh ]
       
        
        if self.myReactions.isEmpty{
            
            docRef.setData(reactions) { error in
                if let error = error {
                    print("error creating comment")
                } else {
                    print("sucessful getting a comment")
                    self.updateMyReactionCollection(reaction: newReaction)
                    DispatchQueue.main.async {
                        self.viewDidLoad()

                    }
                }
            }
            
        }
        else{
            docRef.updateData(reactions){ err in
                if err != nil {
                    print("Error updating Profile. Try again.")
                } else {
                    print("Profile updated successfully")
                    
                    self.updateMyReactionCollection(reaction: newReaction)
                    
                    DispatchQueue.main.async {
                        self.viewDidLoad()
                        
                    }
                }
            }
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

}
