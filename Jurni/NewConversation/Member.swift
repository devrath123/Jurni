//
//  Member.swift
//  Jurni
//
//  Created by Devrath Rathee on 23/05/23.
//

import UIKit

class Member: NSObject {

    var memberId: String
    var memberName:String
    var memberImage: String
    var memberEmail: String
    
    init(memberId: String, memberName: String, memberImage: String, memberEmail: String) {
        self.memberId = memberId
        self.memberName = memberName
        self.memberImage = memberImage
        self.memberEmail = memberEmail
        
        super.init()
    }
}
