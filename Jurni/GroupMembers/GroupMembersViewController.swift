//
//  GroupMembersViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 10/07/23.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class GroupMembersViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var groupMembersTableView: UITableView!
    @IBOutlet weak var membersCountLabel: UILabel!
    @IBOutlet weak var groupMemberView: UIView!
    
    var chatDetail : Chat? = nil
    var membersNameArray = [String]()
    var membersImagesArray = [String]()
    var showDeleteButton = false
    var loggedUserId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        groupMemberView.layer.cornerRadius = 10
        groupMemberView.layer.masksToBounds = true
        membersCountLabel.text = "\(chatDetail!.memberList.count) MEMBERS"
        
        groupMembersTableView.backgroundColor = .white
        let ownerNib = UINib(nibName: "GroupMembersTableViewCell", bundle: nil)
        groupMembersTableView.register(ownerNib, forCellReuseIdentifier: "GroupMembersTableViewCell")
        
        loggedUserId = Auth.auth().currentUser!.uid
        
        fetchMembersDetails()
        
    }
    
    func fetchMembersDetails(){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        let jurniGroup =  DispatchGroup()
        for member in chatDetail!.memberList{
            let memberArray = member.path.components(separatedBy: "/")
            let userId = memberArray.last ?? ""
            let docRef = defaultStore?.collection("users").document(userId)
            jurniGroup.enter()
            docRef!.getDocument { (document, error) in
                if let document = document, document.exists {
                    
                    var userName: String = ""
                    if(document.get("firstName") as? String != nil){
                        userName = document.get("firstName") as? String ?? ""
                    }
                    
                    if(document.get("lastName") as? String != nil){
                        userName += " " + (document.get("lastName") as? String ?? "")
                    }
                    
                    if(userId == self.chatDetail?.chatOwnerId){
                        userName += " (Owner)"
                        if (userId == self.loggedUserId){
                            self.showDeleteButton = true
                        }
                    }
                    
                    self.membersNameArray.append(userName)
                    
                    if(document.get("avatar") as? String != nil && document.get("avatar") as? String != ""){
                        let chatImage = document.get("avatar") as! String
                        self.membersImagesArray.append(chatImage)
                    }else{
                        self.membersImagesArray.append("")
                    }
                    
                    jurniGroup.leave()
                }else{
                    self.membersNameArray.append("")
                    self.membersImagesArray.append("")
                    jurniGroup.leave()
                }
            }
        }
        jurniGroup.notify(queue: .main) {
            self.groupMembersTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.chatDetail?.memberList.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMembersTableViewCell", for: indexPath)
        as! GroupMembersTableViewCell
        
        if (self.membersNameArray.count > 0){
            let memberName = self.membersNameArray[indexPath.row]
            let memberImage = self.membersImagesArray[indexPath.row]
            cell.groupMemberNameLabel.text = memberName
        
            if(showDeleteButton && !memberName.contains("(Owner)")){
                cell.groupMemberDeleteButton.isHidden = false
            }
            
        cell.groupImageView?.image = nil
        cell.groupInitialLabel.isHidden = true
        cell.groupImageView?.layer.cornerRadius = (cell.groupImageView?.frame.size.width)! / 2
        cell.groupImageView?.layer.masksToBounds = true
            
        if(memberImage == ""){
            cell.groupInitialLabel.isHidden = false
            cell.groupInitialLabel.text = String(memberName.prefix(1))
            cell.groupImageView?.layer.backgroundColor = UIColor.lightGray.cgColor
        }else{
            cell.groupInitialLabel.isHidden = true
            let groupUrl = URL(string: memberImage)
                
            DispatchQueue.global().async {
                    let data = try? Data(contentsOf: groupUrl!)
                    if(data != nil){
                        DispatchQueue.main.async {
                            cell.groupImageView.image = UIImage(data: data!)
                        }
                    }
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }
}
