//
//  JurniStep.swift
//  Jurni
//
//  Created by Devrath Rathee on 18/01/23.
//

import Foundation

class JurniStep: NSObject {
    var jurniId: String
    var stepId:String
    var type: String
    var title: String
    var jurniDescription: String
    var stepCount: Int
    var completed:Int
    var percent:Int
    var total: Int
    var phaseIndex:Int
    var chapterPosterUrl: String
    var phase: String
    var phaseOpen: Bool
    var stepContent: String
    
    init(jurniId: String, stepId:String = "",type: String, title: String,jurniDescription: String = "",
         stepCount: Int = 0, completed: Int = 0, percent: Int = 0, total: Int = 0, phaseIndex: Int = 0,
         chapterPosterUrl: String = "", phase: String, phaseOpen: Bool = false, stepContent: String = "") {
        self.jurniId = jurniId
        self.stepId = stepId
        self.type = type
        self.title = title
        self.jurniDescription = jurniDescription
        self.stepCount = stepCount
        self.completed = completed
        self.percent = percent
        self.total = total
        self.phaseIndex = phaseIndex
        self.chapterPosterUrl = chapterPosterUrl
        self.phase = phase
        self.phaseOpen = phaseOpen
        self.stepContent = stepContent
        
        super.init()
    }
    
    func withJurniStep(from: JurniStep) -> JurniStep{
        return JurniStep(jurniId: from.jurniId, stepId: from.stepId, type: from.type, title: from.title, jurniDescription: from.jurniDescription, stepCount: from.stepCount, completed: from.completed, percent: from.percent, total: from.total, phaseIndex: from.phaseIndex, chapterPosterUrl: from.chapterPosterUrl, phase: from.phase, phaseOpen: from.phaseOpen, stepContent: from.stepContent)
    }
}
