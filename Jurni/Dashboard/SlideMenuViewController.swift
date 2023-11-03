//
//  SlideMenuViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 29/11/22.
//

import Foundation
import UIKit

protocol SideMenuViewControllerDelegate {
    func selectedCell(_ row: Int)
}

class SlideMenuViewController : UIViewController{
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var settingsImageView: UIImageView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var communityImageView: UIImageView!
    @IBOutlet weak var communityNameLabel: UILabel!
    @IBOutlet weak var communityDescriptionLabel: UILabel!
    @IBOutlet weak var myJurniImageView: UIImageView!
    @IBOutlet weak var groupsImageView: UIImageView!
    @IBOutlet weak var chatImageView: UIImageView!
    @IBOutlet weak var calendarImageView: UIImageView!
    @IBOutlet weak var userNameInitialLabel: UILabel!
    
    var sideMenuDelegate: SideMenuViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pictureTap = UITapGestureRecognizer(target: self, action: #selector(SlideMenuViewController.imageTapped))
        settingsImageView.addGestureRecognizer(pictureTap)
        settingsImageView.isUserInteractionEnabled = true
        
        let myJurniTap = UITapGestureRecognizer(target: self, action: #selector(SlideMenuViewController.myJurniTapped))
        myJurniImageView.addGestureRecognizer(myJurniTap)
        myJurniImageView.isUserInteractionEnabled = true
        
        let groupsTap = UITapGestureRecognizer(target: self, action: #selector(SlideMenuViewController.groupsTapped))
        groupsImageView.addGestureRecognizer(groupsTap)
        groupsImageView.isUserInteractionEnabled = true
        
        let chatTap = UITapGestureRecognizer(target: self, action: #selector(SlideMenuViewController.chatTapped))
        chatImageView.addGestureRecognizer(chatTap)
        chatImageView.isUserInteractionEnabled = true
        
        let calendarTap = UITapGestureRecognizer(target: self, action: #selector(SlideMenuViewController.calendarTapped))
        calendarImageView.addGestureRecognizer(calendarTap)
        calendarImageView.isUserInteractionEnabled = true
        
        self.userNameLabel.text = UserDefaults.standard.string(forKey: Constants.FIRST_NAME)
        self.communityNameLabel.text = UserDefaults.standard.string(forKey: Constants.COMMUNITY_NAME)
        self.communityDescriptionLabel.text = UserDefaults.standard.string(forKey: Constants.COMMUNITY_DESCRIPTION)
        
        let communityLogo = UserDefaults.standard.string(forKey: Constants.COMMUNITY_LOGO)
        if(communityLogo != nil && communityLogo != ""){
            let communityLogoUrl = URL(string:  communityLogo ?? "")
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: communityLogoUrl!)
                if(data != nil){
                    DispatchQueue.main.async {
                        self.communityImageView.image = UIImage(data: data!)
                    }
                }
            }
        }
        
        self.userImageView?.layer.cornerRadius = (self.userImageView?.frame.size.width)! / 2
        self.userImageView?.layer.masksToBounds = true
        self.userImageView.backgroundColor = UIColor.lightGray
        let profilePic = UserDefaults.standard.string(forKey: Constants.PROFILE_PIC)
        if(profilePic != nil && profilePic != ""){
            let profilePicUrl = URL(string:  profilePic!)
            
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: profilePicUrl!)
                if(data != nil){
                    DispatchQueue.main.async {
                        self.userImageView.image = UIImage(data: data!)
                    }
                }
            }
        }else{
            let user : String = UserDefaults.standard.string(forKey: Constants.FIRST_NAME) ?? ""
            self.userNameInitialLabel.isHidden = false
            self.userNameInitialLabel.text = String(user.prefix(1))
           // self.userImageView?.layer.backgroundColor = UIColor.lightGray.cgColor
        }
       
    }
    
    @objc func imageTapped() {
        self.sideMenuDelegate?.selectedCell(4)
    }
    
    @objc func myJurniTapped() {
        self.sideMenuDelegate?.selectedCell(0)
    }
    
    @objc func groupsTapped() {
        self.sideMenuDelegate?.selectedCell(1)
    }
    
    @objc func chatTapped() {
        self.sideMenuDelegate?.selectedCell(2)
    }
    
    @objc func calendarTapped() {
        self.sideMenuDelegate?.selectedCell(3)
    }
}
