//
//  DashboardViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 20/11/22.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth

class DashboardViewController: UIViewController{
    
    private var sideMenuViewController: SlideMenuViewController!
    private var sideMenuRevealWidth: CGFloat = 260
    private let paddingForRotation: CGFloat = 150
    private var isExpanded: Bool = false
    private var sideMenuTrailingConstraint: NSLayoutConstraint!
    private var revealSideMenuOnTop: Bool = true
    private var sideMenuShadowView: UIView!
    private var draggingIsEnabled: Bool = false
    private var panBaseLocation: CGFloat = 0.0
    var activityView: UIActivityIndicatorView?
    
    @IBAction open func revealSideMenu() {
        self.sideMenuState(expanded: self.isExpanded ? false : true)
    }
    
    override func viewDidLoad() {
        fetchUserData()
    }
    
    func fetchUserData(){
        showActivityIndicator()
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        let userId : String = Auth.auth().currentUser?.uid ?? ""
        let docRef = defaultStore?.collection("users").document(userId)
        
        docRef!.getDocument { (document, error) in
            if let document = document, document.exists {
                let firstName = document.get("firstName") as? String
                if(firstName != nil){
                    UserDefaults.standard.set(firstName, forKey: Constants.FIRST_NAME)
                }
                
                let lastName = document.get("lastName") as? String
                if(lastName != nil){
                    UserDefaults.standard.set(lastName, forKey: Constants.LAST_NAME)
                }
                
                let profilePic = document.get("avatar") as? String
                if(profilePic != nil){
                    UserDefaults.standard.set(profilePic, forKey: Constants.PROFILE_PIC)
                }
                
                let communityId = document.get("activeCommunityId")
                if(communityId != nil){
                    UserDefaults.standard.set(communityId, forKey: Constants.COMMUNITY_ID)
                    self.checkStudentLoggedIn(communityId: communityId as! String)
                }else{
                    self.setSideMenu()
                    self.hideActivityIndicator()
                }
                
                let agoraId = document.get("agoraId")
                if (agoraId != nil){
                    UserDefaults.standard.set(agoraId, forKey: Constants.AGORA_ID)
                }
            }
        }
    }
    
    func checkStudentLoggedIn(communityId: String){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        let userId : String = Auth.auth().currentUser!.uid
        if(!communityId.isEmpty){
            let docRef = defaultStore!.collection("communities").document(communityId)
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    let roles = document.get("roles") as! [String:String]
                    for (key,value) in roles{
                        if(key == userId){
                            if(!(value == "student")){
                              //  self.showLogoutAlert(message: "App is only for Students")
                            }
                        }
                    }
                    
                    let community = document.get("name") as? String
                    if(community != nil){
                        UserDefaults.standard.set(community, forKey: Constants.COMMUNITY_NAME)
                    }
                    
                    let communityDescription = document.get("description") as? String
                    if(communityDescription != nil){
                        UserDefaults.standard.set(communityDescription, forKey: Constants.COMMUNITY_DESCRIPTION)
                    }
                    if(document.get("meta") != nil){
                        let meta: [String:Any] = ((document.get("meta") as?  [String:Any])!)
                        let logo = meta["logo"]
                        if(logo != nil){
                            UserDefaults.standard.set(logo, forKey: Constants.COMMUNITY_LOGO)
                        }
                    }
                    
                    self.setSideMenu()
                    self.hideActivityIndicator()
                }
            }
        }
    }
    
    func setSideMenu(){
        //  self.view.backgroundColor = #colorLiteral(red: 0, green: 0.375862439, blue: 1, alpha: 1)
        // Side Menu Gestures
          
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
        
        self.sideMenuShadowView = UIView(frame: self.view.bounds)
        self.sideMenuShadowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.sideMenuShadowView.backgroundColor = .black
        self.sideMenuShadowView.alpha = 0.0
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TapGestureRecognizer))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
        if self.revealSideMenuOnTop {
            view.insertSubview(self.sideMenuShadowView, at: 1)
        }
        
        // Side Menu
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        self.sideMenuViewController = storyboard.instantiateViewController(withIdentifier: "SideMenuID") as? SlideMenuViewController
       // self.sideMenuViewController.defaultHighlightedCell = 0 // Default Highlighted Cell
        self.sideMenuViewController.sideMenuDelegate = self
        view.insertSubview(self.sideMenuViewController!.view, at: self.revealSideMenuOnTop ? 2 : 0)
        addChild(self.sideMenuViewController!)
        self.sideMenuViewController!.didMove(toParent: self)
        
        self.sideMenuViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        if self.revealSideMenuOnTop {
            self.sideMenuTrailingConstraint = self.sideMenuViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -self.sideMenuRevealWidth - self.paddingForRotation)
            self.sideMenuTrailingConstraint.isActive = true
        }
        NSLayoutConstraint.activate([
            self.sideMenuViewController.view.widthAnchor.constraint(equalToConstant: self.sideMenuRevealWidth),
            self.sideMenuViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.sideMenuViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        showViewController(viewController: UINavigationController.self, storyboardId: "HomeNavID")
    }
}



extension DashboardViewController: SideMenuViewControllerDelegate {
    func selectedCell(_ row: Int) {

        switch row {
        case 0:
            self.showViewController(viewController: UINavigationController.self, storyboardId: "HomeNavID")
            DispatchQueue.main.async { self.sideMenuState(expanded: false) }
        case 1: self.performSegue(withIdentifier: "groupSegue", sender: nil)
           
        case 2: self.performSegue(withIdentifier: "chatSegue", sender: nil)
            
        case 3: self.performSegue(withIdentifier: "calendarSegue", sender: nil)
        
        case 4: self.performSegue(withIdentifier: "settingSegue", sender: nil)
            
        default:
            break
        }
        
    }
    
    func showViewController<T: UIViewController>(viewController: T.Type, storyboardId: String) -> () {
        // Remove the previous View
        for subview in view.subviews {
            if subview.tag == 99 {
                subview.removeFromSuperview()
            }
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: storyboardId)
        vc.view.tag = 99
        view.insertSubview(vc.view, at: self.revealSideMenuOnTop ? 0 : 1)
        addChild(vc)
        if !self.revealSideMenuOnTop {
            if isExpanded {
                vc.view.frame.origin.x = self.sideMenuRevealWidth
            }
            if self.sideMenuShadowView != nil {
                vc.view.addSubview(self.sideMenuShadowView)
            }
        }
        vc.didMove(toParent: self)
    }
    
    func sideMenuState(expanded: Bool) {
        if expanded {
            self.animateSideMenu(targetPosition: self.revealSideMenuOnTop ? 0 : self.sideMenuRevealWidth) { _ in
                self.isExpanded = true
            }
            // Animate Shadow (Fade In)
            UIView.animate(withDuration: 0.5) { self.sideMenuShadowView.alpha = 0.6 }
        }
        else {
            self.animateSideMenu(targetPosition: self.revealSideMenuOnTop ? (-self.sideMenuRevealWidth - self.paddingForRotation) : 0) { _ in
                self.isExpanded = false
            }
            // Animate Shadow (Fade Out)
            UIView.animate(withDuration: 0.5) { self.sideMenuShadowView.alpha = 0.0 }
        }
    }
    
    func animateSideMenu(targetPosition: CGFloat, completion: @escaping (Bool) -> ()) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .layoutSubviews, animations: {
            if self.revealSideMenuOnTop {
                self.sideMenuTrailingConstraint.constant = targetPosition
                self.view.layoutIfNeeded()
            }
            else {
                self.view.subviews[1].frame.origin.x = targetPosition
            }
        }, completion: completion)
    }
}
extension UIViewController {
    
    // With this extension you can access the MainViewController from the child view controllers.
    func revealViewController() -> DashboardViewController? {
        var viewController: UIViewController? = self
        
        if viewController != nil && viewController is DashboardViewController {
            return viewController! as? DashboardViewController
        }
        while (!(viewController is DashboardViewController) && viewController?.parent != nil) {
            viewController = viewController?.parent
        }
        if viewController is DashboardViewController {
            return viewController as? DashboardViewController
        }
        return nil
    }
    // Call this Button Action from the View Controller you want to Expand/Collapse when you tap a button
    
    
}

extension DashboardViewController: UIGestureRecognizerDelegate {
    
    @objc func TapGestureRecognizer(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            if self.isExpanded {
                self.sideMenuState(expanded: false)
            }
        }
    }
    
    // Close side menu when you tap on the shadow background view
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view?.isDescendant(of: self.sideMenuViewController.view))! {
            return false
        }
        return true
    }
    
    // Dragging Side Menu
    @objc private func handlePanGesture(sender: UIPanGestureRecognizer) {
        
        // ...
        
        let position: CGFloat = sender.translation(in: self.view).x
        let velocity: CGFloat = sender.velocity(in: self.view).x
        
        switch sender.state {
        case .began:
            
            // If the user tries to expand the menu more than the reveal width, then cancel the pan gesture
            if velocity > 0, self.isExpanded {
                sender.state = .cancelled
            }
            
            // If the user swipes right but the side menu hasn't expanded yet, enable dragging
            if velocity > 0, !self.isExpanded {
                self.draggingIsEnabled = true
            }
            // If user swipes left and the side menu is already expanded, enable dragging they collapsing the side menu)
            else if velocity < 0, self.isExpanded {
                self.draggingIsEnabled = true
            }
            
            if self.draggingIsEnabled {
                // If swipe is fast, Expand/Collapse the side menu with animation instead of dragging
                let velocityThreshold: CGFloat = 550
                if abs(velocity) > velocityThreshold {
                    self.sideMenuState(expanded: self.isExpanded ? false : true)
                    self.draggingIsEnabled = false
                    return
                }
                
                if self.revealSideMenuOnTop {
                    self.panBaseLocation = 0.0
                    if self.isExpanded {
                        self.panBaseLocation = self.sideMenuRevealWidth
                    }
                }
            }
            
        case .changed:
            
            // Expand/Collapse side menu while dragging
            if self.draggingIsEnabled {
                if self.revealSideMenuOnTop {
                    // Show/Hide shadow background view while dragging
                    let xLocation: CGFloat = self.panBaseLocation + position
                    let percentage = (xLocation * 150 / self.sideMenuRevealWidth) / self.sideMenuRevealWidth
                    
                    let alpha = percentage >= 0.6 ? 0.6 : percentage
                    self.sideMenuShadowView.alpha = alpha
                    
                    // Move side menu while dragging
                    if xLocation <= self.sideMenuRevealWidth {
                        self.sideMenuTrailingConstraint.constant = xLocation - self.sideMenuRevealWidth
                    }
                }
                else {
                    if let recogView = sender.view?.subviews[1] {
                        // Show/Hide shadow background view while dragging
                        let percentage = (recogView.frame.origin.x * 150 / self.sideMenuRevealWidth) / self.sideMenuRevealWidth
                        
                        let alpha = percentage >= 0.6 ? 0.6 : percentage
                        self.sideMenuShadowView.alpha = alpha
                        
                        // Move side menu while dragging
                        if recogView.frame.origin.x <= self.sideMenuRevealWidth, recogView.frame.origin.x >= 0 {
                            recogView.frame.origin.x = recogView.frame.origin.x + position
                            sender.setTranslation(CGPoint.zero, in: view)
                        }
                    }
                }
            }
        case .ended:
            self.draggingIsEnabled = false
            // If the side menu is half Open/Close, then Expand/Collapse with animationse with animation
            if self.revealSideMenuOnTop {
                let movedMoreThanHalf = self.sideMenuTrailingConstraint.constant > -(self.sideMenuRevealWidth * 0.5)
                self.sideMenuState(expanded: movedMoreThanHalf)
            }
            else {
                if let recogView = sender.view?.subviews[1] {
                    let movedMoreThanHalf = recogView.frame.origin.x > self.sideMenuRevealWidth * 0.5
                    self.sideMenuState(expanded: movedMoreThanHalf)
                }
            }
        default:
            break
        }
    }
    
    func showLogoutAlert(message: String){
        let alert = UIAlertController(title: "Logout", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: handler))
        self.present(alert, animated: true, completion: nil)
    }
    
    func handler(alert: UIAlertAction!){
        let defaults = UserDefaults.standard
            let dictionary = defaults.dictionaryRepresentation()
            dictionary.keys.forEach { key in
                defaults.removeObject(forKey: key)
            }
        try! Auth.auth().signOut()
        self.performSegue(withIdentifier: "logoutSegue", sender: nil)
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
