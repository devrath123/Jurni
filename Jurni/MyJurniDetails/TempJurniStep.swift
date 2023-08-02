//
//  TempJurniStep.swift
//  Jurni
//
//  Created by Devrath Rathee on 22/02/23.
//

import UIKit
import FirebaseFirestore

class TempJurniStep: NSObject {

    var orderId: Int
    var jurniId: String
    var type: String
    var title: String
    var phaseId: String
    var content: String
   
    init(orderId: Int, jurniId: String, type: String, title: String, phaseId: String, content: String) {
        self.orderId = orderId
        self.jurniId = jurniId
        self.type = type
        self.title = title
        self.phaseId = phaseId
        self.content = content
        
        super.init()
    }
}
