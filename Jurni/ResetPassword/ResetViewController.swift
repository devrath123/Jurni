//
//  ResetViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 19/11/22.
//

import Foundation
import UIKit
import FirebaseAuth

class ResetViewController : UIViewController,UITextFieldDelegate{
    
    @IBOutlet weak var emailTextField: UITextField!
    var activityView: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        
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
    }
    
    @IBAction func resetPasswordAction(_ sender: Any) {
        let email : String = emailTextField.text ?? ""
        
        if(!email.isEmpty){
            showActivityIndicator()
            sendResetPasswordLink(email: email)
        }else{
           showAlert(message: "Enter Email")
        }
    }
    
    func sendResetPasswordLink(email: String){
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            self.hideActivityIndicator()
            if(error == nil){
                self.showPasswordResetLinkAlert(message: "Password reset link sent to your email")
            }else{
                self.showAlert(message: "Enter valid email")
            }
        }
    }

    func showAlert(message: String){
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showPasswordResetLinkAlert(message: String){
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: handler))
        self.present(alert, animated: true, completion: nil)
    }
    
    func handler(alert: UIAlertAction!){
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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
