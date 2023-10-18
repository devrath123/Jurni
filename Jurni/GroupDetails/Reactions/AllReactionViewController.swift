//
//  AllReactionViewController.swift
//  Jurni
//
//  Created by Yatharth Singh on 13/10/23.
//

import UIKit
import FirebaseFirestore

class AllReactionViewController: UIViewController {
    
    
    var postDetails: Post?
    var groupDetails: Group?
    weak var backDelegate: BackDelegate?
    
    @IBOutlet weak var reactionMainView: UIView!
    @IBOutlet weak var allReactionView: UIView!
    @IBOutlet weak var allReactionCountLbl: UILabel!
    @IBAction func allReactionBtnTap(_ sender: Any) {
    }
    
    @IBOutlet weak var loveView: UIView!
    @IBOutlet weak var loveCountLbl: UILabel!
    @IBAction func loveBtnTap(_ sender: Any) {
        updateReactionToFirebase(reaction: "LOVE")
    }
    
    @IBOutlet weak var thumbsUpView: UIView!
    @IBOutlet weak var thumbsUpCountLbl: UILabel!
    @IBAction func thumbsUpBtnTap(_ sender: Any) {
        updateReactionToFirebase(reaction: "THUMBS_UP")
    }
    
    
    @IBOutlet weak var surpriseView: UIView!
    @IBOutlet weak var surpriseCountLbl: UILabel!
    @IBAction func surpriseBtnTap(_ sender: Any) {
        updateReactionToFirebase(reaction: "SURPRISE")
    }
    
    
    @IBOutlet weak var laughView: UIView!
    @IBOutlet weak var laughCountLbl: UILabel!
    @IBAction func laughBtnTap(_ sender: Any) {
        updateReactionToFirebase(reaction: "LAUGH")
    }
    
    @IBOutlet weak var sadView: UIView!
    @IBOutlet weak var sadCountLbl: UILabel!
    @IBAction func sadBtnTap(_ sender: Any) {
        updateReactionToFirebase(reaction: "SAD")
    }
    
    @IBOutlet weak var angryView: UIView!
    @IBOutlet weak var angryCountLbl: UILabel!
    @IBAction func angryBtnTap(_ sender: Any) {
        updateReactionToFirebase(reaction: "ANGRY")
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

    
    func updateReactionToFirebase(reaction: String){
        let post = postDetails
        let groupId = self.groupDetails?.groupId ?? ""
        
        var thumbsUp = post!.postReaction.thumbsUp
        var love = post!.postReaction.love
        var laugh = post!.postReaction.laugh
        var surprise = post!.postReaction.surprise
        var sad = post!.postReaction.sad
        var angry = post!.postReaction.angry
        switch reaction{
        case "THUMBS_UP": thumbsUp += 1
        case "LOVE": love += 1
        case "LAUGH": laugh += 1
        case "SURPRISE": surprise += 1
        case "SAD": sad += 1
        case "ANGRY": angry += 1
            
        default: print("Default")
        }
        
        let docRef = Firestore.firestore().collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(post!.id!)
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
                case "THUMBS_UP": post!.postReaction.thumbsUp += 1
                case "LOVE": post!.postReaction.love += 1
                case "LAUGH": post!.postReaction.laugh += 1
                case "SURPRISE": post!.postReaction.surprise += 1
                case "SAD": post!.postReaction.sad += 1
                case "ANGRY": post!.postReaction.angry += 1
                    
                default: print("Default")
                }
                DispatchQueue.main.async {
                    self.viewDidLoad()
                }
            }
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
     // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
