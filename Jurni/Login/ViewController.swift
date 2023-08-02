//
//  ViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 16/11/22.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    var activityView: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)
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
    
    @objc func keyboardWillHide() {
        self.view.frame.origin.y = 0
    }

    @objc func keyboardWillChange(notification: NSNotification) {

            if emailTextField.isFirstResponder {
                self.view.frame.origin.y = -150
            }
            if passwordTextField.isFirstResponder {
                self.view.frame.origin.y = -150
            }
    }
    
    @IBAction func loginAction(_ sender: Any) {
        let email : String = emailTextField.text ?? ""
        let password : String = passwordTextField.text ?? ""
        if(!email.isEmpty && !password.isEmpty){
            showActivityIndicator()
            login(email: email, password: password)
        }else{
           showAlert(message: "Enter both Email and Password")
        }
    }
    
    func login(email: String, password:String){
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            self?.hideActivityIndicator()
            if(authResult == nil){
                self!.showAlert(message: "Enter valid Email and Password")
            }else{
                UserDefaults.standard.set(true, forKey: Constants.LOGIN_STATUS)
                self!.performSegue(withIdentifier: "loginSegue", sender: nil)
            }
        }
    }

    func showAlert(message: String){
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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

