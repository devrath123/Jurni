//
//  ContactDetailsViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 08/12/22.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FirebaseFirestore


class ContactDetailsViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var jobTitleTextField: UITextField!
    @IBOutlet weak var hobbiesTextField: UITextField!
    @IBOutlet weak var currentPwdTextField: UITextField!
    @IBOutlet weak var newPwdTextField: UITextField!
    @IBOutlet weak var saveAccountChangsButton: UIButton!
    
    var activityView: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        phoneTextField.delegate = self
        jobTitleTextField.delegate = self
        hobbiesTextField.delegate = self
        currentPwdTextField.delegate = self
        newPwdTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)
        
        fetchUserData()
    }
    
    func fetchUserData(){
        showActivityIndicator()
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        let userId : String = Auth.auth().currentUser?.uid ?? ""
        let docRef = defaultStore?.collection("users").document(userId)
        
        docRef!.getDocument { (document, error) in
            self.hideActivityIndicator()
            if let document = document, document.exists {
                let firstName = document.get("firstName") as? String
                if(firstName != nil){
                    UserDefaults.standard.set(firstName, forKey: Constants.FIRST_NAME)
                }
                
                let lastName = document.get("lastName") as? String
                if(lastName != nil){
                    UserDefaults.standard.set(lastName, forKey: Constants.LAST_NAME)
                }
                
                let email = document.get("email") as? String
                if(email != nil){
                    UserDefaults.standard.set(email, forKey: Constants.EMAIL)
                }
                
                let phone = document.get("phone") as? String
                if(phone != nil){
                    UserDefaults.standard.set(phone, forKey: Constants.PHONE_NUMBER)
                }
                
                let jobTitle = document.get("jobTitle") as? String
                if(jobTitle != nil){
                    UserDefaults.standard.set(jobTitle, forKey: Constants.JOB_TITLE)
                }
                
                let avatar = document.get("avatar") as? String
                if(avatar != nil){
                    UserDefaults.standard.set(avatar, forKey: Constants.PROFILE_PIC)
                }
                
                let hobbies = document.get("hobbies") as? String
                if(hobbies != nil){
                    UserDefaults.standard.set(hobbies, forKey: Constants.HOBBIES)
                }
                
                let communityId = document.get("activeCommunityId")
                if(communityId != nil){
                    UserDefaults.standard.set(communityId, forKey: Constants.COMMUNITY_ID)
                }
                
                self.setUserData()
                
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func setUserData(){
        self.firstNameTextField.text = UserDefaults.standard.string(forKey: Constants.FIRST_NAME)
        self.lastNameTextField.text = UserDefaults.standard.string(forKey: Constants.LAST_NAME)
        self.emailTextField.text = UserDefaults.standard.string(forKey: Constants.EMAIL)
        self.phoneTextField.text = UserDefaults.standard.string(forKey: Constants.PHONE_NUMBER)
        self.jobTitleTextField.text = UserDefaults.standard.string(forKey: Constants.JOB_TITLE)
        self.hobbiesTextField.text = UserDefaults.standard.string(forKey: Constants.HOBBIES)

    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func saveAction(_ sender: Any) {
        showActivityIndicator()
        let firstName : String = firstNameTextField.text ?? ""
        let lastName : String = lastNameTextField.text ?? ""
        let email: String = emailTextField.text ?? ""
        let phone: String = phoneTextField.text ?? ""
        let jobTitle: String = jobTitleTextField.text ?? ""
        let hobbies: String = hobbiesTextField.text ?? ""
        
        
        let userData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "phone": phone,
            "jobTitle":jobTitle,
            "hobbies": hobbies
        ]
        saveUserData(userData: userData)
    }

    func saveUserData(userData: [String: Any]){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        let userId : String = Auth.auth().currentUser!.uid
        let docRef = defaultStore?.collection("users").document(userId)
        docRef?.setData(userData){ err in
            self.hideActivityIndicator()
            if let err = err {
                self.showAlert(message: "Error updating Profile. Try again.")
            } else {
                self.showAlert(message: "Profile updated successfully")
            }
        }
    }
    
    func showAlert(message: String){
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showActivityIndicator() {
        activityView = UIActivityIndicatorView(style: .large)
        activityView?.center = self.view.center
        self.view.addSubview(activityView!)
        activityView?.startAnimating()
    }
    
    func hideActivityIndicator(){
        if (activityView != nil){
            activityView?.stopAnimating()
        }
    }
    
}
