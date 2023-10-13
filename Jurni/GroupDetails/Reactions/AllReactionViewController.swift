//
//  AllReactionViewController.swift
//  Jurni
//
//  Created by Yatharth Singh on 13/10/23.
//

import UIKit

class AllReactionViewController: UIViewController {
    
    
    var postDetails: Post?
    
    @IBOutlet weak var allReactionView: UIView!
    @IBOutlet weak var allReactionCountLbl: UILabel!
    @IBAction func allReactionBtnTap(_ sender: Any) {
    }
    
    @IBOutlet weak var loveView: UIView!
    @IBOutlet weak var loveCountLbl: UILabel!
    @IBAction func loveBtnTap(_ sender: Any) {
    }
    
    @IBOutlet weak var thumbsUpView: UIView!
    @IBOutlet weak var thumbsUpCountLbl: UILabel!
    @IBAction func thumbsUpBtnTap(_ sender: Any) {
    }
    
    
    @IBOutlet weak var surpriseView: UIView!
    @IBOutlet weak var surpriseCountLbl: UILabel!
    @IBAction func surpriseBtnTap(_ sender: Any) {
    }
    
    
    @IBOutlet weak var laughView: UIView!
    @IBOutlet weak var laughCountLbl: UILabel!
    @IBAction func laughBtnTap(_ sender: Any) {
    }
    
    @IBOutlet weak var sadView: UIView!
    @IBOutlet weak var sadCountLbl: UILabel!
    @IBAction func sadBtnTap(_ sender: Any) {
    }
    
    @IBOutlet weak var angryView: UIView!
    @IBOutlet weak var angryCountLbl: UILabel!
    @IBAction func angryBtnTap(_ sender: Any) {
    }
   
   
    
    
    
    
    
    
    
    
    
    
    @IBAction func closeBtnTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isOpaque = false
        view.backgroundColor = .clear
        // Do any additional setup after loading the view.
        
        self.hideAllView()
        
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
            self.loveCountLbl.text = "\(postDetails!.postReaction.love)"
        }
        if (postDetails!.postReaction.sad > 0)
        {
            self.sadView.isHidden = false
            self.sadCountLbl.text = "\(postDetails!.postReaction.sad)"
        }
        if (postDetails!.postReaction.thumbsUp > 0)
        {
            self.thumbsUpView.isHidden = false
            self.thumbsUpCountLbl.text = "\(postDetails!.postReaction.thumbsUp)"
        }
        if (postDetails!.postReaction.angry > 0)
        {
            self.angryView.isHidden = false
            self.angryCountLbl.text = "\(postDetails!.postReaction.angry)"
        }
        if (postDetails!.postReaction.surprise > 0)
        {
            self.surpriseView.isHidden = false
            self.surpriseCountLbl.text = "\(postDetails!.postReaction.surprise)"
        }
        if (postDetails!.postReaction.laugh > 0)
        {
            self.laughView.isHidden = false
            self.laughCountLbl.text = "\(postDetails!.postReaction.laugh)"
        }
        
        
    }
    
    
    func hideAllView (){
        self.allReactionView.isHidden = true
        self.loveView.isHidden = true
        self.thumbsUpView.isHidden = true
        self.sadView.isHidden = true
        self.angryView.isHidden = true
        self.surpriseView.isHidden = true
        self.laughView.isHidden = true
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
