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
    weak var backDelegate: BackDelegate?
    @IBOutlet weak var avtarLblView: UIView!
    @IBOutlet weak var profileLbl: UILabel!
    @IBOutlet weak var commentView: UIView!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var avtarImgView: UIImageView!
    @IBOutlet weak var commentTextField: UITextField!
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        commentTextField.delegate = self
        self.showActivityIndicator()
        let headerNib = UINib(nibName: "CommentCell", bundle: nil)
        commentTableView.register(headerNib, forCellReuseIdentifier: "CommentCell")
        self.setBottomView()
        self.fetchComments()
        
        let height = self.view.frame.height - (commentTableView.frame.origin.y + commentView.frame.height)
        tableViewHeight = Int(height)
        tableHeightConstraint.constant = CGFloat(tableViewHeight)
        
    }
    
    
    // MARK: - Methods


    func fetchComments() {
        self.comments.removeAll()
        let defaultStore = Firestore.firestore()
        defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(self.postDetails?.id ?? "").collection("comments").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting comments documents: \(err)")
            } else {
                if let documents = querySnapshot?.documents {
                    for document in documents {
                        let id = document.documentID
                        let timestamp = document.get("timestamp") as? Timestamp
                        let commentTime = timestamp?.dateValue() ?? Date()
                        let content = document.get("content") as? String
                        
                        var userId: String?
                        if let fromReference = document.get("from") as? DocumentReference {
                            let pathComponents = fromReference.path.components(separatedBy: "/")
                            userId = pathComponents.last
                        } else if let fromString = document.get("from") as? String {
                            userId = fromString
                        }
                        
                        if let userId = userId {
                            let userRef = defaultStore.collection("users").document(userId)
                            userRef.getDocument { (document, error) in
                                var userName: String = "Unknown"
                                var userImage: String = ""
                                
                                if let document = document, document.exists {
                                    if let firstName = document.get("firstName") as? String {
                                        userName = firstName
                                    }
                                    if let lastName = document.get("lastName") as? String {
                                        userName += " " + lastName
                                    }
                                    
                                    if let image = document.get("avatar") as? String {
                                        userImage = image
                                    }
                                }
                                
                                let commentUser = User(userName: userName, userAvatar: userImage, isOwner: true)
                                let comment = Comment(id: id, content: content ?? "", from: commentUser, timestamp: commentTime)
                                
                                self.comments.append(comment)
                                self.comments = self.comments.sorted(by: { $0.timestamp.compare($1.timestamp as Date) == .orderedDescending })
                                self.commentTableView.reloadData()
                                self.hideActivityIndicator()
                            }
                        } else {
                            let commentUser = User(userName: "Unknown", userAvatar: "", isOwner: true)
                            let comment = Comment(id: id, content: content ?? "", from: commentUser, timestamp: commentTime)
                            self.comments.append(comment)
                            self.comments = self.comments.sorted(by: { $0.timestamp.compare($1.timestamp as Date) == .orderedDescending })
                            self.commentTableView.reloadData()
                            self.hideActivityIndicator()
                        }
                       
                    }
                   
                    self.commentTableView.reloadData()
                    self.hideActivityIndicator()
                }
            }
        }
    }
    
    
   func setBottomView(){
       avtarLblView.layer.cornerRadius = avtarLblView.frame.size.width / 2
       let profilePic = UserDefaults.standard.string(forKey: Constants.PROFILE_PIC) ?? ""
       let firstName =  UserDefaults.standard.string(forKey: Constants.FIRST_NAME) ?? ""
       
        setImage(url: profilePic, imageView: avtarImgView)
        avtarLblView.isHidden = true
       avtarImgView.contentMode = .scaleAspectFill
       avtarImgView.layer.cornerRadius = avtarImgView.frame.size.width / 2
       avtarImgView.layer.masksToBounds = true
       
        if (!firstName.isEmpty && profilePic == ""){
            avtarLblView.isHidden = false
           
            let nameFirstLetter:String = firstName.first!.description
            
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
        backDelegate?.didComeBack()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func scrollToBottom(){
        let index = IndexPath(row: self.comments.count-1, section: 0)
        self.commentTableView.scrollToRow(at: index, at: .bottom, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
            if error != nil {
                self.hideActivityIndicator()
                print("error creating comment", error)
            } else {
                print("sucessful getting a comment")
                self.commentTextField.text = ""
                self.fetchComments()
                
            }
        }
    }
    
    func deleteComment(postID: String,commentId: String) {
        
        let defaultStore = Firestore.firestore()
        let document = defaultStore.collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document(postID).collection("comments").document(commentId)

        document.delete() { error in
            if let error = error {
                self.hideActivityIndicator()
                print("error creating comment", error)
            } else {
                print("sucessful getting a comment")
                self.fetchComments()
                
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! CommentViewController
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tableHeightConstraint.constant = CGFloat(tableViewHeight)
        textField.resignFirstResponder()
        return true
    }
    
    @objc func keyboardWillHide() {
        tableHeightConstraint.constant = CGFloat(tableViewHeight)
    }

    @objc func keyboardWillChange(notification: NSNotification) {
        
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
