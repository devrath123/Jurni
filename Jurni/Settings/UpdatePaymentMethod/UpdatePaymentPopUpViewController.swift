//
//  UpdatePaymentPopUpViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 18/12/22.
//

import UIKit
import FirebaseFirestore
import FirebaseFunctions
import FirebaseAuth

class UpdatePaymentPopUpViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var updatePaymentArray = [PaymentMethodBean]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "UpdatePaymentTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "UpdatePaymentTableViewCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.white
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("clicked ")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return updatePaymentArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UpdatePaymentTableViewCell", for: indexPath) as! UpdatePaymentTableViewCell
        let paymentMethod = updatePaymentArray[indexPath.row]
        
        cell.cardType.text = paymentMethod.brand
        cell.lastFour.text = paymentMethod.last4
        cell.action.text = "Active"
        
        cell.removeBtn.addTarget(self, action: #selector(removeButtonAction(sender:)), for: .touchUpInside)
        cell.removeBtn.tag = indexPath.row
        
        return cell
    }

    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func removeButtonAction(sender: UIButton){
        let removeIndex = sender.tag
        let payment = updatePaymentArray[removeIndex]
        let userId : String = Auth.auth().currentUser!.uid
        let communityId: String = UserDefaults.standard.string(forKey: Constants.COMMUNITY_ID) ?? ""
        lazy var functions = Functions.functions()
        functions.httpsCallable("removePaymentMethod").call(["paymentMethodId": payment.billId,"uid": userId, "communityId":communityId]){result, error in
            
            if(error == nil){
               // print(result?.data)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func customerBilling(){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        defaultStore?.collection("customerBillingDetails").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                }
            }
        }
    }
}
