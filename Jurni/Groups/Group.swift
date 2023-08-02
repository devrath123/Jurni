//
//  Group.swift
//  Jurni
//
//  Created by Devrath Rathee on 17/02/23.
//

import UIKit

class Group: NSObject {
    var groupId: String
    var groupName: String
    var groupLogo: String
    var groupBanner: String
    var membersCount: Int
    
    init(groupId: String, groupName: String, groupLogo: String,
         groupBanner:String, membersCount: Int) {
        self.groupId = groupId
        self.groupName = groupName
        self.groupLogo = groupLogo
        self.groupBanner = groupBanner
        self.membersCount = membersCount
        
        super.init()
    }
}
