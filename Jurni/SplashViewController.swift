//
//  SplashViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 21/11/22.
//

import Foundation
import UIKit

class SplashViewController: UIViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (_) in
            if(UserDefaults.standard.bool(forKey: Constants.LOGIN_STATUS)){
                self.performSegue(withIdentifier: "dashboardSegue", sender: nil)
            }else{
                self.performSegue(withIdentifier: "loginSegue", sender: nil)
            }
           }
    }
}
