//
//  CommentViewController.swift
//  Jurni
//
//  Created by Yatharth Singh on 02/10/23.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class CommentViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    
    
    @IBOutlet weak var commentTableView: UITableView!
    var groupDetails: Group?
    var postDetails: Post?
    var comments: [Comment] = []
    var tableViewHeight = 0
    var activityView: UIActivityIndicatorView?
    
    @IBOutlet weak var avtarLblView: UIView!
    @IBOutlet weak var profileLbl: UILabel!
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var avtarImgView: UIImageView!
    @IBOutlet weak var commentTextField: UITextField!
    
   
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        commentTextField.delegate = self
        
       
        
        let headerNib = UINib(nibName: "CommentCell", bundle: nil)
        commentTableView.register(headerNib, forCellReuseIdentifier: "CommentCell")
        
        self.fetchComments()
        
        var height = self.view.frame.height - (commentTableView.frame.origin.y + commentView.frame.height)
        tableViewHeight = Int(height)
        tableHeightConstraint.constant = CGFloat(tableViewHeight)
        
    }
    
    
    // MARK: - Methods
    func fetchComments(){
        self.comments.removeAll()
        print("documents", self.groupDetails?.groupId, self.postDetails?.id)
            let defaultStore = Firestore.firestore()
            defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(self.postDetails?.id ?? "").collection("comments").getDocuments(){ (querySnapshot, err) in
                if let err = err {
                    print("Error getting comments documents: \(err) :(")
                } else {
                    print("documents", self.groupDetails?.groupId, self.postDetails?.id)
                    if let documents = querySnapshot?.documents {
                        for document in documents {
                            print("Error getting comments documents: \(document.data()) :(")
                            let id = document.documentID
                            let timestamp = document.get("timestamp") as? Timestamp
                            let commentTime = timestamp?.dateValue() ?? Date()
                            let content = document.get("content") as? String
                            
                            if let commenterIDPath = document.get("from") as? DocumentReference {
                                let pathString = commenterIDPath.path
                                let components = pathString.components(separatedBy: "/")
                                if let uid = components.last{
                                    print("commenter UID = \(uid)")
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
                                                } else {
                                                    userImage.append("")
                                                }
                                            }
                                            let commentUser = User(userName: userName, userAvatar: userImage)
                                            let comment = Comment(id: id, content: content ?? "", from: commentUser, timestamp: commentTime)
                                           
                                            self.comments.append(comment)
                                            self.comments = self.comments.sorted(by: { $0.timestamp.compare($1.timestamp as Date) == .orderedDescending })
                                            self.commentTableView.reloadData()
                                            self.setBottomView()
//                                            self.scrollToBottom()
                                        }
                                    }
                                }
                            }
                        }
                        
                        self.hideActivityIndicator()
                    }
                }
            }
        }
    
    
   func setBottomView(){
       let profilePic = UserDefaults.standard.string(forKey: Constants.PROFILE_PIC) ?? ""
        setImage(url: profilePic, imageView: avtarImgView)
        avtarLblView.isHidden = true
       
//       commentTextField.layer.borderColor = UIColor.darkGray.cgColor
//       commentTextField.layer.cornerRadius = 5
//
       
        if (!comments[0].from.userName.isEmpty && comments[0].from.userAvatar == ""){
            avtarLblView.isHidden = false
            avtarLblView.layer.cornerRadius = avtarLblView.frame.size.width / 2
            let nameFirstLetter:String = comments[0].from.userName.first!.description
            
            profileLbl.text = nameFirstLetter
        }
        
    }
    
    func setImage(url: String, imageView: UIImageView){
        if(url != ""){
            let imageUrl = URL(string:  url)
            imageView.kf.setImage(with: imageUrl)
        }
    }
    
    @IBAction func bckBtn(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func scrollToBottom(){
        let index = IndexPath(row: self.comments.count-1, section: 0)
        self.commentTableView.scrollToRow(at: index, at: .bottom, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if comments.count == 0 {
//            self.commentTableView.setEmptyMessage("No Comments yet")
//
//        }
//        else{
//
//            self.commentTableView.restore()
//
//        }
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
        as! CommentCell
        
        cell.commentView.layer.cornerRadius = 10
        cell.setCommentsData(with: comments[indexPath.row])
        
       
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            self.showActivityIndicator()
            self.deleteComment(postID: (self.postDetails?.id)!, commentId: self.comments[indexPath.row].id!)
            
        }
    }
    
    @IBAction func sendBtnTap(_ sender: Any) {
        
        if commentTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == false
        {
            self.showActivityIndicator()
            createComment(postID: (self.postDetails?.id)!, content: commentTextField.text ?? "")
        }
        
    }
    
    
    
    func createComment(postID: String,content: String) {
        
        let defaultStore = Firestore.firestore()
        let document = defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(postID).collection("comments").document()
        
        let from = Auth.auth().currentUser!.uid
        let ownerString = Firestore.firestore().collection("users").document(from)
        let ownerReference = Firestore.firestore().document(ownerString.path)
        
        let dataToSend : [String: Any] = ["content": content,"from": ownerReference, "timestamp":FieldValue.serverTimestamp()]
        document.setData(dataToSend) { error in
            if let error = error {
                print("error creating comment")
            } else {
                print("sucessful getting a comment")
                self.commentTextField.text = ""
                self.fetchComments()
//                self.scrollToBottom()
                
            }
        }
    }
    
    func deleteComment(postID: String,commentId: String) {
        
        let defaultStore = Firestore.firestore()
        let document = defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(postID).collection("comments").document(commentId)
        
        let from = Auth.auth().currentUser!.uid
        let ownerString = Firestore.firestore().collection("users").document(from)
        let ownerReference = Firestore.firestore().document(ownerString.path)
        
       
        document.delete() { error in
            if let error = error {
                print("error creating comment", error)
            } else {
                print("sucessful getting a comment")
                self.fetchComments()
                
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! CommentViewController
//        destinationVC.groupDetails = selectedGroup
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tableHeightConstraint.constant = CGFloat(tableViewHeight)
//        self.scrollToBottom()
        textField.resignFirstResponder()
        return true
    }
    
    @objc func keyboardWillHide() {
      //  self.view.frame.origin.y = 0
        tableHeightConstraint.constant = CGFloat(tableViewHeight)
    }

    @objc func keyboardWillChange(notification: NSNotification) {
//            if messageTextField.isFirstResponder {
//                self.view.frame.origin.y = -350
//            }
        
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
              let keyboardHeight = value.cgRectValue.height
        tableHeightConstraint.constant = CGFloat(tableViewHeight) - keyboardHeight
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func showActivityIndicator() {
      //  self.view.isUserInteractionEnabled = false
        activityView = UIActivityIndicatorView(style: .large)
        activityView?.center = self.view.center
        activityView?.color = .black
        self.view.addSubview(activityView!)
        activityView?.startAnimating()
    }
    
    func hideActivityIndicator(){
      //  self.view.isUserInteractionEnabled = true
        if (activityView != nil){
            activityView?.stopAnimating()
        }
    }
    

}

extension UITableView {

    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .black
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont(name: "TrebuchetMS", size: 15)
        messageLabel.sizeToFit()

        self.backgroundView = messageLabel
        self.separatorStyle = .none
    }

    func restore() {
        self.backgroundView = nil
        self.separatorStyle = .none
    }
}
