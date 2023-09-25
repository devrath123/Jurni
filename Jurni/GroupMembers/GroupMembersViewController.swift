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
    var membersIdArray = [String]()
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
                    
                    if(document.get("uid") as? String != nil){
                        let uId = document.get("uid") as? String
                        self.membersIdArray.append(uId!)
                    }else{
                        self.membersIdArray.append("")
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
        
            cell.groupMemberDeleteButton.isHidden = true
            if(showDeleteButton && !memberName.contains("(Owner)")){
                cell.groupMemberDeleteButton.isHidden = false
            }
            
            let deleteUserTapped = UITapGestureRecognizer(target: self, action: #selector(deleteUserTapped))
            cell.groupMemberDeleteButton.tag = indexPath.row
            cell.groupMemberDeleteButton.addGestureRecognizer(deleteUserTapped)
            
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
    
    @objc func deleteUserTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        let row = view.tag
        let userId = membersIdArray[row]
        deleteMember(deleteUserId: userId, row: row)
    }
    
    func deleteMember(deleteUserId: String, row: Int){
        print("User id to delete :\(deleteUserId)")
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        var updatedMembersArray = [DocumentReference]()
        
        for member in chatDetail!.memberList{
            let memberArray = member.path.components(separatedBy: "/")
            let userId = memberArray.last ?? ""
            if (userId != deleteUserId){
                updatedMembersArray.append(member)
            }
        }
        
        let threadOrderDoc = defaultStore?.collection("threads").document(chatDetail!.threadId)
        
        let chatData: [String:Any] = [
            "members": updatedMembersArray
        ]
                
        threadOrderDoc?.updateData(chatData){ err in
            if err != nil {
                print("Error updating Profile. Try again.")
            } else {
                print("Profile updated successfully")
                self.chatDetail?.memberList.remove(at: row)
                self.membersIdArray.remove(at: row)
                self.membersNameArray.remove(at: row)
                self.membersImagesArray.remove(at: row)
                self.membersCountLabel.text = "\(self.chatDetail!.memberList.count) MEMBERS"
                self.groupMembersTableView.reloadData()
            }
        }
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }
}
