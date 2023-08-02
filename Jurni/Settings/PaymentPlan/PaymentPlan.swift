//
//  StudentBillPayment.swift
//  Jurni
//
//  Created by Devrath Rathee on 20/12/22.
//

import UIKit

class PaymentPlan: NSObject {
    var billId: String
    var billingDate: String
    var cost: String
    var name: String
    var status: String
    var isUpcoming: Bool
    var upcomingDate: Date
    
    init(billId: String, billingDate: String, cost: String, name: String, status: String,
         isUpcoming: Bool, upcomingDate: Date) {
        self.billId = billId
        self.billingDate = billingDate
        self.cost = cost
        self.name = name
        self.status = status
        self.isUpcoming = isUpcoming
        self.upcomingDate = upcomingDate
        
        super.init()
    }
    
    func withPaymentPlan(from:PaymentPlan) -> PaymentPlan {
        return PaymentPlan(billId: from.billId,
                           billingDate: from.billingDate,
                           cost: from.cost,
                           name: from.name,
                           status: from.status,
                           isUpcoming: from.isUpcoming,
                           upcomingDate: from.upcomingDate)
    }
}
