//
//  JurniChapter.swift
//  Jurni
//
//  Created by Devrath Rathee on 03/02/23.
//

import UIKit

class JurniChapter: NSObject {

    var chapterId: String
    var chapterName: String
    var chapterImage: String
    var chapterUrl: String
    var chapterDescription :String
    var chapterVideoPlaying: Bool
    
    init(chapterId: String, chapterName: String, chapterImage: String,
         chapterUrl: String,chapterDescription: String,chapterVideoPlaying: Bool) {
        self.chapterId = chapterId
        self.chapterName = chapterName
        self.chapterImage = chapterImage
        self.chapterUrl = chapterUrl
        self.chapterDescription = chapterDescription
        self.chapterVideoPlaying = chapterVideoPlaying
        
        super.init()
    }
}
