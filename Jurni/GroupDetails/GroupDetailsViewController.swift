//
//  GroupDetailsViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 27/02/23.
//

import UIKit
import AVKit

class GroupDetailsViewController: UIViewController {

    @IBOutlet weak var groupNameLabel: UILabel!
    @IBOutlet weak var membersCountLabel: UILabel!
    @IBOutlet weak var groupPostTableView: UITableView!
    var groupDetails: Group? = nil
   
    var player: AVPlayer!
    var avpPlayerController = AVPlayerViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        groupPostTableView.backgroundColor = UIColor.white 
        groupNameLabel.text = groupDetails?.groupName
        membersCountLabel.text =  "\(groupDetails?.membersCount ?? 0) MEMBERS"
        
    }
    
    @IBAction func backClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func playVideo(videoUrl: String, videoView: UIView){
        let videoUrl = URL(string: videoUrl)
        if(videoUrl != nil){
            player = AVPlayer(url: videoUrl!)
            avpPlayerController.player = player
            avpPlayerController.view.frame.size.height = videoView.frame.size.height
            avpPlayerController.view.frame.size.width = videoView.frame.size.width
            videoView.addSubview(avpPlayerController.view)
            player.play()
        }
    }
    
    func getMessagePostedDay(date: Date) -> String{
        let diffInDays: Int = Calendar.current.dateComponents([.day], from: date, to: Date()).day!
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

extension String {
    func htmlAttributedString() -> String? {
        guard let data = self.data(using: String.Encoding.utf16, allowLossyConversion: false) else { return nil }
        guard let html = try? NSMutableAttributedString(
            data: data,
            options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil) else { return nil }
        return html.string
    }
}
