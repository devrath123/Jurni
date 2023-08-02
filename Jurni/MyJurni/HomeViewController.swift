//
//  SlideMenuViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 29/11/22.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth

class HomeViewController : UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet weak var sideMenuBtn: UIBarButtonItem!
    @IBOutlet weak var myJurniTableView: UITableView!
    var jurniArray = [MyJurni]()
    var jurniDocumentArray = [QueryDocumentSnapshot]()
    var selectedJurniDocument: QueryDocumentSnapshot? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sideMenuBtn.target = revealViewController()
                sideMenuBtn.action = #selector(revealViewController()?.revealSideMenu)
        
        myJurniTableView.delegate = self
        myJurniTableView.dataSource = self
        myJurniTableView.backgroundColor = UIColor.white
        let myJurniNib = UINib(nibName: "MyJurniTableViewCell", bundle: nil)
        myJurniTableView.register(myJurniNib, forCellReuseIdentifier: "MyJurniTableViewCell")
        
        fetchJurnis()
    }
    
    func fetchJurnis(){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        defaultStore?.collection("jurnis").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                let communityId : String = (UserDefaults.standard.string(forKey: Constants.COMMUNITY_ID) ?? "") as String
                if (communityId == ""){
                    return
                }
                let userId : String = Auth.auth().currentUser?.uid ?? ""
                for document in querySnapshot!.documents {
                  //  print("\(document.documentID) ==> \(document.data())")
                    var community : DocumentReference?
                    if(document.get("community") != nil){
                        community = document.get("community") as? DocumentReference
                    }
                    
                    var isArchived : Int = 0
                    if(document.get("meta") != nil){
                        let jurniMeta : [String : Any] = document.get("meta") as! [String : Any]
                        if(jurniMeta["isArchived"] != nil){
                            isArchived = jurniMeta["isArchived"] as! Int
                        }
                    }
                    
                    let members = document.get("members") as! [DocumentReference]
                    var userFound = false
                    for member in members{
                        if(member.path == "users/\(userId)"){
                            userFound = true
                        }
                    }
                   
                    if(community != nil && community?.path == "communities/\(communityId)" && isArchived == 0 && userFound == true){
                       // print("\(document.documentID) ==> \(document.data())")
                        let name = document.get("name") as! String
                        let meta: [String:Any] = (document.get("meta") as?  [String:Any])!
                        let logo = meta["banner"] as? String
                        
                        self.jurniArray.append(MyJurni(jurniId: document.documentID, jurniName: name, jurniLogo: logo ?? "", membersCount: members.count, activeGroupCount: 0))
                        self.jurniDocumentArray.append(document)
                    }
                }
                
                self.myJurniTableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jurniArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyJurniTableViewCell", for: indexPath)
        as! MyJurniTableViewCell
        
        cell.myJurniTitle.text = jurniArray[indexPath.row].jurniName
        cell.membersLabel.text = "\(jurniArray[indexPath.row].membersCount) Member(s)"
        cell.activeGroupsLabel.text = "\(jurniArray[indexPath.row].activeGroupCount) active group"
        
        let jurniLogoUrl = URL(string:  jurniArray[indexPath.row].jurniLogo)
        
        if(jurniLogoUrl != nil){
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: jurniLogoUrl!)
                if(data != nil){
                    DispatchQueue.main.async {
                        cell.myJurniImageView.image = UIImage(data: data!)
                    }
                }
            }
        }else{
            cell.myJurniImageView.image = UIImage(named: "logo")
        }
        
        let cellNameTapped = UITapGestureRecognizer(target: self, action: #selector(nameTapped))
        cell.isUserInteractionEnabled = true
        cell.addGestureRecognizer(cellNameTapped)
        
        return cell
    }
    
    @objc func nameTapped(tapGestureRecognizer: UITapGestureRecognizer){
        
        let view = tapGestureRecognizer.view
        let indexPath = myJurniTableView.indexPathForView(view!)
        selectedJurniDocument = jurniDocumentArray[indexPath!.row]
        self.performSegue(withIdentifier: "jurniDetailsSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! MyJurniDetailsViewController
            destinationVC.jurniDocument = selectedJurniDocument
    }
}

