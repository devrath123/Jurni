//
//  GroupsViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 15/02/23.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class GroupsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var groupsTableView: UITableView!
    var groupArray = [Group]()
    var selectedGroup: Group? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        groupsTableView.dataSource = self
        groupsTableView.delegate = self
        groupsTableView.backgroundColor = UIColor.white
        
        let groupNib = UINib(nibName: "GroupTableViewCell", bundle: nil)
        groupsTableView.register(groupNib, forCellReuseIdentifier: "GroupTableViewCell")
        
        fetchGroups()
    }
    
    @IBAction func backClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func fetchGroups(){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        defaultStore?.collection("groups").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                let communityId : String = (UserDefaults.standard.string(forKey: Constants.COMMUNITY_ID) ?? "") as String
                let userId : String = Auth.auth().currentUser!.uid
               // print("************ Groups ************")
                for document in querySnapshot!.documents {
                    let community = document.get("community") as! DocumentReference
                    
                    let members = document.get("members") as! [DocumentReference]
                    var userFound = false
                    for member in members{
                        if(member.path == "users/\(userId)"){
                            userFound = true
                        }
                    }
                   
                    if(community.path == "communities/\(communityId)" && userFound == true){
                     //   print("\(document.documentID) ==> \(document.data())")
                        let name = document.get("name") as! String
                        let groupMeta : [String : Any] = document.get("meta") as! [String : Any]
                        let groupLogo = groupMeta["banner"] as? String
                        let groupBanner = groupMeta["groupBanner"] as? String
                        
                        self.groupArray.append(Group(groupId: document.documentID, groupName: name, groupLogo: groupLogo ?? "", groupBanner: groupBanner ?? "", membersCount: members.count))
                    }
                }
               
                self.groupsTableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groupArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupTableViewCell", for: indexPath)
        as! GroupTableViewCell
        
        cell.groupName.text = self.groupArray[indexPath.row].groupName
        cell.groupMembers.text = "\(self.groupArray[indexPath.row].membersCount) Members"
        
        let groupUrl = URL(string:  groupArray[indexPath.row].groupLogo)
        
        if(groupUrl != nil){
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: groupUrl!)
                DispatchQueue.main.async {
                    cell.groupImageView.image = UIImage(data: data!)
                }
            }
        }else{
            cell.groupImageView.image = UIImage(named: "logo")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedGroup = groupArray[indexPath.row]
        self.performSegue(withIdentifier: "groupDetailsSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! GroupDetailsViewController
        destinationVC.groupDetails = selectedGroup
    }
    

}
