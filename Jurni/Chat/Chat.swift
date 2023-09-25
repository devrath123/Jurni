//
//  Chat.swift
//  Jurni
//
//  Created by Devrath Rathee on 11/05/23.
//

import UIKit
import FirebaseFirestore

class Chat: NSObject {
    var chatId: String
    var chatType:String
    var chatMessage: String
    var chatTitle: String
    var membersIds: [String]
    var members: [String]
    var membersImages: [String]
    var chatImage: String
    var chatTimeStamp: Date
    var owner: String
    var threadId: String
    var isNewChat: Bool
    var memberList: [DocumentReference]
    var chatOwnerId: String
    var lastActivitySenderId: String
    
    init(chatId: String, chatType: String, chatMessage: String, chatTitle: String,
         membersIds: [String], members: [String], membersImages: [String],
         chatImage: String, chatTimeStamp: Date,owner: String, threadId: String,
         isNewChat: Bool, memberList: [DocumentReference], chatOwnerId: String,
         lastActivitySenderId: String) {
        self.chatId = chatId
        self.chatType = chatType
        self.chatMessage = chatMessage
        self.chatTitle = chatTitle
        self.membersIds = membersIds
        self.members = members
        self.membersImages = membersImages
        self.chatImage = chatImage
        self.chatTimeStamp = chatTimeStamp
        self.owner = owner
        self.threadId = threadId
        self.isNewChat = isNewChat
        self.memberList = memberList
        self.chatOwnerId = chatOwnerId
        self.lastActivitySenderId = lastActivitySenderId
        
        super.init()
    }
}
