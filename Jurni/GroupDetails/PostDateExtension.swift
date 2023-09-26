//
//  PostDateExtension.swift
//  Jurni
//
//  Created by Esther on 9/20/23.
//

import Foundation

extension Date {
    
    // Update to be more specific than day ("just now", "10 Minutes ago", etc.)
    func getMessagePostedDay() -> String{
        let diffInDays: Int = Calendar.current.dateComponents([.day], from: self, to: Date()).day!
        var day : String = ""
        
        switch diffInDays{
        case 0: day = "Today"
        case 1: day = "1 day ago"
        case 2..<32: day = "\(diffInDays) days ago"
        case 33..<366: day = "\(diffInDays/30) months ago"
        default: day = "\(diffInDays/365) year ago"
        }
        return day
    }
}
