//
//  ChatMessage.swift
//  Jurni
//
//  Created by Devrath Rathee on 26/05/23.
//

import UIKit

class ChatMessage: NSObject {

    var chatId: String
    var userType: String
    var user: String
    var message: String
    var messageType: String
    var messageDate: NSDate
    var reaction: Reaction
    var messageDuration: Int
    var messageHeight: CGFloat
    var showSmileys: Bool
    var smileys: [String]
    var audioPlaying: Bool
    var replyToId: String
    
    init(chatId: String, userType: String,user: String, message: String,
         messageType: String,messageDate: NSDate, reaction: Reaction,
         messageDuration: Int,messageHeight: CGFloat, showSmileys: Bool,
         smileys: [String], audioPlaying: Bool, replyToId: String) {
        self.chatId = chatId
        self.userType = userType
        self.user = user
        self.message = message
        self.messageType = messageType
        self.messageDate = messageDate
        self.reaction = reaction
        self.messageDuration = messageDuration
        self.messageHeight = messageHeight
        self.showSmileys = showSmileys
        self.smileys = smileys
        self.audioPlaying = audioPlaying
        self.replyToId = replyToId
            
        super.init()
    }
}

struct Reaction{
    var angry: [String] = []
    var laugh: [String] = []
    var love: [String] = []
    var sad: [String] = []
    var surprise: [String] = []
    var thumbsUp: [String] = []
}
