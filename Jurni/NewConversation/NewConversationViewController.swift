//
//  NewConversationViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 23/05/23.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class NewConversationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var selectedMemberView: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var membersTableView: UITableView!
    @IBOutlet weak var newMemberView: UIView!
    @IBOutlet weak var selectedMemberCollectionView: UICollectionView!
    
    var memberArray = [Member]()
    var searchMemberArray = [Member]()
    var selectedMemberArray = [Member]()
    var newConversationProtocol : NewConversationProtocol?
    
    var chats : [Chat]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newMemberView.layer.cornerRadius = 10
        newMemberView.layer.masksToBounds = true
        
        selectedTableViewVisibility(isHidden: true)
        
        searchBar.barStyle = .black
        searchBar.searchTextField.backgroundColor = .white
        searchBar.delegate = self
        
        membersTableView.backgroundColor = UIColor.white
        let groupNib = UINib(nibName: "MemberDetailTableViewCell", bundle: nil)
        membersTableView.register(groupNib, forCellReuseIdentifier: "MemberDetailTableViewCell")
    
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        selectedMemberCollectionView.collectionViewLayout = flowLayout
        selectedMemberCollectionView.backgroundColor = UIColor.white
        
        fetchMembers()
    }

    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func fetchMembers(){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        let communityId : String = (UserDefaults.standard.string(forKey: Constants.COMMUNITY_ID) ?? "") as String
        if(!communityId.isEmpty){
            let docRef = defaultStore!.collection("communities").document(communityId)
            let loggedUserId : String = Auth.auth().currentUser?.uid ?? ""
            let jurniGroup =  DispatchGroup()
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let members = document.get("members") as! [DocumentReference]
                    for member in members{
                            let memberArray = member.path.components(separatedBy: "/")
                            let userId = memberArray.last ?? ""
                            let docRef = defaultStore?.collection("users").document(userId)
                            
                        if(userId != loggedUserId){
                            jurniGroup.enter()
                            docRef!.getDocument { (document, error) in
                                if let document = document, document.exists {
                                    print("Doc: \(document.data())")
                                    var userName: String = ""
                                    var userImage: String = ""
                                    var userEmail: String = ""
                                    
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
                                    
                                    if(document.get("email") != nil){
                                        userEmail = document.get("email") as! String
                                    }
                                    
                                    if(!userEmail.isEmpty){
                                        self.memberArray.append(Member(memberId: document.documentID, memberName: userName, memberImage: userImage, memberEmail: userEmail))
                                    }
                                    
                                    jurniGroup.leave()
                                }
                            }
                        }
                        }
                    jurniGroup.notify(queue: .main) {
                        self.searchMemberArray = self.memberArray
                        self.membersTableView.reloadData()
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return self.searchMemberArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MemberDetailTableViewCell", for: indexPath)
        as! MemberDetailTableViewCell
        
        
            cell.memberNameLabel.text = self.searchMemberArray[indexPath.row].memberName
            cell.memberEmailLabel.text = self.searchMemberArray[indexPath.row].memberEmail
            
            cell.memberImageView?.image = nil
            cell.memberInitialLabel.text = ""
            
            if(searchMemberArray[indexPath.row].memberImage == ""){
                cell.memberInitialLabel.isHidden = false
                cell.memberInitialLabel.text = String(searchMemberArray[indexPath.row].memberName.prefix(1))
                cell.memberImageView?.layer.cornerRadius = (cell.memberImageView?.frame.size.width)! / 2
                cell.memberImageView?.layer.masksToBounds = true
                cell.memberImageView?.layer.backgroundColor = UIColor.lightGray.cgColor
            }else{
                cell.memberInitialLabel.isHidden = true
                let groupUrl = URL(string:  searchMemberArray[indexPath.row].memberImage)
                cell.memberImageView?.layer.cornerRadius = (cell.memberImageView?.frame.size.width)! / 2
                cell.memberImageView?.layer.masksToBounds = true
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: groupUrl!)
                    if(data != nil){
                        DispatchQueue.main.async {
                            cell.memberImageView.image = UIImage(data: data!)
                        }
                    }
                }
            }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            selectedTableViewVisibility(isHidden: false)
            
            let selectedMember = searchMemberArray[indexPath.row]
            selectedMemberArray.append(selectedMember)
            
            let searchedIndex: Int = searchMemberArray.firstIndex(of: selectedMember)!
            searchMemberArray.remove(at: searchedIndex)
            let memberIndex: Int = memberArray.firstIndex(of: selectedMember)!
            memberArray.remove(at: memberIndex)
            
            membersTableView.reloadData()
            selectedMemberCollectionView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty
            else {
                searchMemberArray = memberArray
                membersTableView.reloadData()
                return
        }
        
        searchMemberArray = memberArray.filter({Member -> Bool in
            guard let text = searchBar.text else {return false}
            return Member.memberName.contains(text)
        })
        
        membersTableView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedMemberArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectedCollectionViewCell", for: indexPath) as! SelectedCollectionViewCell
        
        cell.userLabel.text = selectedMemberArray[indexPath.row].memberName
        cell.userInitialLabel.text = ""
        cell.userImageView?.image = nil
        
        if(selectedMemberArray[indexPath.row].memberImage == ""){
            cell.userInitialLabel.isHidden = false
            cell.userInitialLabel.text = String(selectedMemberArray[indexPath.row].memberName.prefix(1))
            cell.userImageView?.layer.cornerRadius = (cell.userImageView?.frame.size.width)! / 2
            cell.userImageView?.layer.masksToBounds = true
            cell.userImageView?.layer.backgroundColor = UIColor.lightGray.cgColor
        }else{
            cell.userInitialLabel.isHidden = true
            let groupUrl = URL(string:  selectedMemberArray[indexPath.row].memberImage)
            cell.userImageView?.layer.cornerRadius = (cell.userImageView?.frame.size.width)! / 2
            cell.userImageView?.layer.masksToBounds = true
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: groupUrl!)
                DispatchQueue.main.async {
                    cell.userImageView.image = UIImage(data: data!)
                }
            }
        }
        
        let cancelImageTapped = UITapGestureRecognizer(target: self, action: #selector(cancelTapped))
        cell.cancelImageView.isUserInteractionEnabled = true
        cell.cancelImageView.tag = indexPath.row
        cell.cancelImageView.addGestureRecognizer(cancelImageTapped)
        
        
        return cell
    }
    
    @objc func cancelTapped(tapGestureRecognizer: UITapGestureRecognizer){
       let view = tapGestureRecognizer.view as! UIImageView
       let cancelledItem = selectedMemberArray[view.tag]
        
       searchMemberArray.append(cancelledItem)
       memberArray.append(cancelledItem)
        
       selectedMemberArray.remove(at: view.tag)
        
       membersTableView.reloadData()
       selectedMemberCollectionView.reloadData()
        
        if(selectedMemberArray.isEmpty){
            selectedTableViewVisibility(isHidden: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = (collectionView.frame.size.width - 20)/4
        return CGSize(width: size, height: size)
    }
    
    
    @IBAction func startConversationAction(_ sender: Any) {
        let communityId : String = (UserDefaults.standard.string(forKey: Constants.COMMUNITY_ID) ?? "") as String
        let userId : String = Auth.auth().currentUser!.uid
        let firestore = Firestore.firestore()
        
        let communityReferenceString = firestore.collection("communities").document(communityId)
        let communityReference = firestore.document(communityReferenceString.path)
        
        let ownerString = firestore.collection("users").document(userId)
        let ownerReference = firestore.document(ownerString.path)
        
        var members = [DocumentReference]()
        var membersIds = [String]()
        membersIds.append(userId)
        members.append(ownerReference)
        for member in selectedMemberArray{
            let memberString = firestore.collection("users").document(member.memberId)
            let memberReference = firestore.document(memberString.path)
            members.append(memberReference)
            membersIds.append(member.memberId)
        }
        
       
        for chat in self.chats!{
            if(chat.membersIds.count == membersIds.count && chat.membersIds.sorted() == membersIds.sorted()){
                self.dismiss(animated: true, completion: nil)
                self.newConversationProtocol?.newConversationFailure(message: "Chat Already exists with selected members.")
                return
            }
        }
        
        let docRef = Firestore.firestore().collection("threads").document()

        docRef.setData([
            "community": communityReference,
            "thread_id": docRef.documentID,
            "members": members,
            "name": "",
            "owner": ownerReference,
            "type": "thread"
        ]){ err in
            if let err = err {
                print("Error updating document: \(err)")
                self.newConversationProtocol?.newConversationFailure(message: "Please try again later.")
            } else {
                self.newConversationProtocol?.newConversationSuccess(threadId: docRef.documentID)
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func selectedTableViewVisibility(isHidden: Bool){
        selectedMemberView.isHidden = isHidden
    }
    
}

protocol NewConversationProtocol{
    func newConversationSuccess(threadId: String)
    func newConversationFailure(message: String)
}

