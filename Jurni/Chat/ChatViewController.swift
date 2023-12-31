//
//  ChatViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 30/03/23.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import Kingfisher

class ChatViewController: UIViewController,UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate,
                          NewConversationProtocol, ChatDetailsProtocol {
 
    
   
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var chatArray = [Chat]()
    var searchChatArray = [Chat]()
    var selectedChat : Chat? = nil
    var activityView: UIActivityIndicatorView?
    let imageLoaderCache = ImageCacheLoader()
    var reloadFromNewConversation = false
    var newConversationThreadId = ""
    var userName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar.barStyle = .black
        searchBar.searchTextField.backgroundColor = .white
        searchBar.delegate = self
        
        chatTableView.delegate = self
        chatTableView.dataSource = self
        chatTableView.backgroundColor = UIColor.white
        let groupNib = UINib(nibName: "ChatTableViewCell", bundle: nil)
        chatTableView.register(groupNib, forCellReuseIdentifier: "ChatTableViewCell")
        
        userName = (UserDefaults.standard.string(forKey: Constants.FIRST_NAME) ?? "") + " " + (UserDefaults.standard.string(forKey: Constants.LAST_NAME) ?? "")
        
        fetchChats()
    }
    
    func fetchChats(){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        showActivityIndicator()
        defaultStore?.collection("threads").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
               // print("************ Chats ************")
                let communityId : String = (UserDefaults.standard.string(forKey: Constants.COMMUNITY_ID) ?? "") as String
                let jurniGroup =  DispatchGroup()
                let loggedUserId : String = Auth.auth().currentUser!.uid
                var threadArray = [String]()
                var newChatArray = [String]()
                self.chatArray.removeAll()
                self.searchChatArray.removeAll()
                let threadOrderDoc =  defaultStore?.collection("users").document(loggedUserId).collection("communitySettings").document(communityId)
                threadOrderDoc!.getDocument { (document, error) in
                    if let document = document, document.exists {
                        if(document.get("threadOrder") != nil){
                            let threadOrderArray = document.get("threadOrder") as! [String]
                            
                            for thread in threadOrderArray{
                                threadArray.append(thread)
                            }
                        }
                        
                        if(document.get("newChatThreads") != nil){
                            let newChatThreadArray = document.get("newChatThreads") as! [String]
                            for thread in newChatThreadArray{
                                newChatArray.append(thread)
                            }
                        }
                    }
                }
                
                for document in querySnapshot!.documents {
                  //  print("\(document.documentID) ==> \(document.data())")
                    
                    var validThreadType = false
                    var validCommunity = false
                    var validUsers = false
                    var isHidden = false
    
                    if(document.get("type") != nil && document.get("community") != nil &&
                       document.get("members") != nil){
                        let type = document.get("type") as! String
                        if(type == "thread" || type == "bot"){
                            validThreadType = true
                        }
                        
                        if document.get("community") is String{
                            if(document.get("community") as! String == "global"){
                                validCommunity = true
                            }
                        }else{
                            if((document.get("community") as! DocumentReference).path == "communities/\(communityId)"){
                                validCommunity = true
                            }
                        }
                        
                        let membersArray = document.get("members") as! [DocumentReference]
                        var userFound = false
                       
                        for member in membersArray{
                            if(member.path == "users/\(loggedUserId)"){
                                userFound = true
                            }
                        }
                        
                        if(membersArray.count > 1 && userFound){
                                validUsers = true
                        }
                        
                        if(document.get("meta") != nil){
                            let meta = document.get("meta") as! [String : Any]
                            if(meta["hideThread"] != nil){
                                isHidden = meta["hideThread"] as! Bool
                            }
                        }
                        
                        if(validThreadType == true && validCommunity == true && validUsers == true &&
                           isHidden == false){
                            
                            var message = "", messageTitle = "", chatImage = ""
                            var i = 0
                            
                            var messageTimeStamp = Date()
                            var senderId = ""
                            if(document.get("lastActivity") != nil){
                                let lastActivity = document.get("lastActivity") as! [String : Any]
                                message = lastActivity["message"] as! String
                                let timeStamp = lastActivity["timestamp"] as! Timestamp
                                messageTimeStamp = timeStamp.dateValue()
                                if (lastActivity["senderId"] != nil){
                                    senderId = lastActivity["senderId"] as! String
                                }
                            }
                            
                            
                            if(document.get("name") as! String != "") {
                                messageTitle = document.get("name") as! String
                            }
                            
                            jurniGroup.enter()
                            let ownerDocument = document.get("owner") as! DocumentReference
                            let ownerArray = ownerDocument.path.components(separatedBy: "/")
                            let ownerId = ownerArray.last ?? ""
                            let threadId = document.get("thread_id") as? String
                        
                            var membersNameArray = [String]()
                            var membersImagesArray = [String]()
                            var membersIdsArray = [String]()
                            for member in membersArray{
                                let memberArray = member.path.components(separatedBy: "/")
                                let userId = memberArray.last ?? ""
                                let docRef = defaultStore?.collection("users").document(userId)
                                membersIdsArray.append(userId)
                               
                                docRef!.getDocument { (document, error) in
                                    if let document = document, document.exists {
                                       
                                        i += 1
                                        var userName: String = ""
                                        if(document.get("firstName") as? String != nil){
                                            userName = document.get("firstName") as? String ?? ""
                                        }
                                        
                                        if(document.get("lastName") as? String != nil){
                                            userName += " " + (document.get("lastName") as? String ?? "")
                                        }
                                        
                                        membersNameArray.append(userName)
                                        
                                        if(document.get("avatar") as? String != nil && document.get("avatar") as? String != ""){
                                            chatImage = document.get("avatar") as! String
                                            membersImagesArray.append(chatImage)
                                        }else{
                                            membersImagesArray.append("")
                                        }
                                        
                                        var ownerName = ""
                                        if(ownerId == userId){
                                            ownerName = userName
                                        }
                                        
                                        if(i == memberArray.count){
                                            self.chatArray.append(Chat(chatId: document.documentID, chatType: type, chatMessage: message, chatTitle: messageTitle, membersIds: membersIdsArray, members: membersNameArray, membersImages: membersImagesArray,chatImage: chatImage, chatTimeStamp: messageTimeStamp, owner: ownerName, threadId: threadId!, isNewChat: false, memberList: membersArray,chatOwnerId : ownerId,
                                                lastActivitySenderId: senderId))
                                            jurniGroup.leave()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                
                jurniGroup.notify(queue: .main) {
                    var finalArray = [Chat]()
                    for thread in threadArray{
                        if let chat = self.chatArray.first(where: {$0.threadId == thread}) {
                            if let newChat = newChatArray.first(where: {$0 == chat.threadId}){
                                if(loggedUserId != chat.lastActivitySenderId){
                                    chat.isNewChat = true
                                }
                            }
                            finalArray.append(chat)
                        }
                    }

                    self.searchChatArray.removeAll()
                    self.chatArray.removeAll()
                    self.hideActivityIndicator()
                    self.chatArray = finalArray
                    self.searchChatArray = self.chatArray
                    DispatchQueue.main.async {
                        self.chatTableView.reloadData()
                        self.chatTableView.beginUpdates()
                        self.chatTableView.endUpdates()
                        
                        
                        if (self.reloadFromNewConversation){
                            self.loadEarlierConversation(threadId: self.newConversationThreadId)
                            print("Thread Id New Conv fetch: \(self.newConversationThreadId)")
                            self.reloadFromNewConversation = false
                        }
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchChatArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatTableViewCell", for: indexPath)
        as! ChatTableViewCell
      
        let view = UIView()
        view.backgroundColor = UIColor.lightGray
        cell.selectedBackgroundView = view
        
        let searchChat = searchChatArray[indexPath.row]
        
        if(searchChat.chatTitle == ""){
            var tempMembers = searchChat.members
            var chatTitle = ""
            if(searchChat.memberList.count == 2){
                for member in tempMembers {
                    if (member != userName){
                        chatTitle = member
                    }
                }
            }else{
                let owner = searchChat.owner
                if(owner != "" && owner != userName){
                    let ownerIndex = tempMembers.firstIndex(of: owner)
                    tempMembers.remove(at: ownerIndex ?? 0)
                    tempMembers.insert(owner, at: 0)
                }
                
                if(tempMembers.count > 5){
                    tempMembers = Array(tempMembers.prefix(5))
                }
                
                for member in tempMembers{
                    if(chatTitle == ""){
                        chatTitle = member
                    }else{
                        if(!(chatTitle.contains(member))){
                            chatTitle += ", " + member
                        }
                    }
                }
            }
            cell.chatTitle.text = chatTitle
            searchChat.chatTitle = chatTitle
        }else{
            cell.chatTitle.text = searchChat.chatTitle
        }
        
        cell.chatDesc.text = searchChat.chatMessage
        cell.unreadChatImageView.isHidden = true
        if(searchChat.isNewChat){
            cell.unreadChatImageView.isHidden = false
        }else{
            cell.unreadChatImageView.isHidden = true
        }
        
        cell.chatImageView?.layer.cornerRadius = (cell.chatImageView?.frame.size.width)! / 2
        cell.chatImageView?.layer.masksToBounds = true
        cell.chatUser.isHidden = true
        cell.chatUser.text = ""
        
        if(searchChat.memberList.count > 2){
            cell.chatImageView.image = UIImage(named: "groupblue")
        }else{
            cell.chatImageView.image = UIImage(named: "userblue")
        }
        
        let moreOptions = UITapGestureRecognizer(target: self, action: #selector(moreOptionsTapped))
        cell.chatOptionsImageView.isUserInteractionEnabled = true
        cell.chatOptionsImageView.tag = indexPath.row
        cell.chatOptionsImageView.addGestureRecognizer(moreOptions)
        
        if (reloadFromNewConversation){
            if (searchChat.threadId == newConversationThreadId){
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
                tableView.delegate?.tableView!(tableView, didSelectRowAt: indexPath)
                reloadFromNewConversation = false
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedChat = searchChatArray[indexPath.row]
        self.performSegue(withIdentifier: "chatDetailsSegue", sender: nil)
        
    }
    
    @objc func moreOptionsTapped(tapGestureRecognizer: UITapGestureRecognizer){
        
        let view = tapGestureRecognizer.view as! UIImageView
        let selectedChat = searchChatArray[view.tag]

        let actionSheetController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let firstAction: UIAlertAction = UIAlertAction(title: "Leave Chat", style: .default) { action -> Void in

            var members = [DocumentReference]()
            for chat in selectedChat.memberList{
                let loggedUserId : String = Auth.auth().currentUser!.uid
                if(chat.path != "users/\(loggedUserId)"){
                    members.append(chat)
                }
            }

            let docRef = Firestore.firestore().collection("threads").document(selectedChat.threadId)
            let chatData: [String:Any] = [
                "members": members
            ]

            docRef.updateData(chatData){ err in
                if err != nil {
                    print("Error updating Chat. Try again.")
                } else {
                    DispatchQueue.main.async {
                        self.fetchChats()
                    }
                }
            }
            
        }

        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in }
        actionSheetController.addAction(firstAction)
        actionSheetController.addAction(cancelAction)
        actionSheetController.popoverPresentationController?.sourceView = self.view
        present(actionSheetController, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! ChatDetailsViewController
        destinationVC.chatDetailsProtocol = self
        destinationVC.chatDetail = selectedChat
    }

    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        guard !searchText.isEmpty
            else {
                searchChatArray = chatArray
                chatTableView.reloadData()
                return
        }
        
        searchChatArray = chatArray.filter({Chat -> Bool in
            guard let text = searchBar.text else {return false}
            return Chat.chatTitle.contains(text)
        })
        
        chatTableView.reloadData()
    }
    
    @IBAction func newConversationAction(_ sender: Any) {
        let popUpVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "newConvId") as! NewConversationViewController  
        popUpVC.modalPresentationStyle = .overCurrentContext
        popUpVC.modalTransitionStyle = .crossDissolve
        popUpVC.newConversationProtocol = self
        popUpVC.chats = self.chatArray
        present(popUpVC, animated: true, completion: nil)
    }
    
    func newConversationSuccess(threadId: String) {
        reloadFromNewConversation = true
        newConversationThreadId = threadId
        showActivityIndicator()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.hideActivityIndicator()
            self.fetchChats()
        }
    }
    
    func newConversationFailure(message: String) {
        showAlert(message: message)
    }
    
    func showAlert(message: String){
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func loadEarlierConversation(threadId: String){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            for searchChat in self.searchChatArray{
                if (searchChat.threadId == threadId){
                    print("Thread Id New Conv Search: \(searchChat.threadId)")
                    let rowIndex: Int = self.searchChatArray.firstIndex(of: searchChat)!
                    let indexPath:IndexPath = IndexPath(row: rowIndex, section: 0);
                    self.chatTableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
                    self.chatTableView.delegate?.tableView!(self.chatTableView, didSelectRowAt: indexPath)
                    break
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
    
    func reloadChatList() {
        self.viewDidLoad()
        self.viewWillAppear(true)
    }
}
