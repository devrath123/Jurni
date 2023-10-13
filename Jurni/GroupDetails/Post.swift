//
//  Post.swift
//  Jurni
//
//  Created by Devrath Rathee on 20/04/23.
//

import UIKit
import FirebaseFirestoreSwift

class Post: NSObject {
    var postType: String
    var postTime: Date
    var postContent: PostContent
    var user: User
    var postReaction: PostReaction
    var commentsCount: Int
    @DocumentID var id: String?
   
    init(postType: String, postTime: Date, postContent: PostContent, user: User,
         postReaction: PostReaction, commentsCount: Int) {
        self.postType = postType
        self.postTime = postTime
        self.postContent = postContent
        self.user = user
        self.postReaction = postReaction
        self.commentsCount = commentsCount
        super.init()
    }
}

struct PostContent{
    var postText: String = ""
    var postImageUrls: [String]
    var postVideoUrl: [String]
}

struct User{
    var userName: String = ""
    var userAvatar: String = ""
    var isOwner: Bool
}

struct PostReaction{
    var angry: Int = 0
    var laugh: Int = 0
    var love: Int = 0
    var sad: Int = 0
    var surprise: Int = 0
    var thumbsUp: Int = 0
}

struct Comment {
    var id: String?
       var content: String = ""
       var from: User
       var timestamp: Date
}

