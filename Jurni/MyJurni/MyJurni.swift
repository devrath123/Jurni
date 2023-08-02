//
//  MyJurni.swift
//  Jurni
//
//  Created by Devrath Rathee on 07/01/23.
//

import UIKit

class MyJurni: NSObject {
    var jurniId: String
    var jurniName: String
    var jurniLogo: String
    var membersCount: Int
    var activeGroupCount:Int
    
    init(jurniId: String, jurniName: String, jurniLogo: String,
         membersCount: Int,activeGroupCount: Int) {
        self.jurniId = jurniId
        self.jurniName = jurniName
        self.jurniLogo = jurniLogo
        self.membersCount = membersCount
        self.activeGroupCount = activeGroupCount
        
        super.init()
    }
}
