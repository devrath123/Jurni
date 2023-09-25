//
//  ChatDetailsViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 25/05/23.
//

import UIKit
import FirebaseDatabase
import FirebaseFirestore
import FirebaseAuth
import AVFoundation
import FirebaseStorage
import FirebaseFirestore

class ChatDetailsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UISearchBarDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVAudioRecorderDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout,UITextFieldDelegate     {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var chatDetailsImageView: UIImageView!
    @IBOutlet weak var chatDetailsNameLabel: UILabel!
    @IBOutlet weak var chatDetailsTableView: UITableView!
    @IBOutlet weak var chatDetailsIconNameLabel: UILabel!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var replyToLabel: UILabel!
    @IBOutlet weak var closeReplyToButton: UIButton!
    @IBOutlet weak var replyToView: UIView!
    @IBOutlet weak var galleryButton: UIButton!
    @IBOutlet weak var chatBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatView: UIView!
    @IBOutlet weak var audioImageView: UIImageView!
    @IBOutlet weak var audioTimerLabel: UILabel!
    @IBOutlet weak var sendMessageButton: UIButton!
    @IBOutlet weak var textMessageImageView: UIImageView!
    @IBOutlet weak var cancelImageView: UIButton!
    @IBOutlet weak var showMemberListButton: UIButton!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    var chatDetail : Chat? = nil
    var chats = [ChatMessage]()
    var searchChats = [ChatMessage]()
    var smileys = [String]()
    var imagePicker = UIImagePickerController()
    var replyToId = ""
    var shouldScrollToBottom = true
    let imageLoaderCache = ImageCacheLoader()
    
    let TYPE_USER = "User"
    let TYPE_OWNER = "Owner"
    let MESSAGE_TYPE_TEXT = "text"
    let MESSAGE_TYPE_IMAGE = "image"
    let MESSAGE_TYPE_AUDIO = "audio"
    let MESSAGE_TYPE_VIDEO = "video"
    let MESSAGE_TYPE_OTHER = "other"
    let AUDIO_STATE_PLAY = "play"
    let AUDIO_STATE_PAUSE = "pause"
    let AUDIO_STATE_STOP = "stop"
    
    var timer: Timer?
    var audioTimer:Timer = Timer()
    var audioRecorder : AVAudioRecorder?
    var player = AVPlayer()
    var activityView: UIActivityIndicatorView?
    var previousSmileyIndex = -1
    var previousAudioIndex = -1
    var currentAudioPlayState = ""
    var timeCount:Int = 0
    var initialChatViewY : Int = 0
    var keyboardVisible = false
    var tableViewHeight = 0
    
    var chatDetailsProtocol : ChatDetailsProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatDetailsTableView.backgroundColor = UIColor.white
        
        searchBar.barStyle = .black
        searchBar.searchTextField.backgroundColor = .white
        searchBar.delegate = self
        
        chatDetailsNameLabel.text = chatDetail?.chatTitle
        
        chatDetailsImageView?.layer.cornerRadius = (chatDetailsImageView?.frame.size.width)! / 2
        chatDetailsImageView?.layer.masksToBounds = true
        
        if((chatDetail?.memberList.count)! > 2){
            chatDetailsImageView.image = UIImage(named: "groupblue")
        }else
        {
            chatDetailsImageView.image = UIImage(named: "userblue")
            showMemberListButton.isHidden = true
        }
        
        
        let ownerNib = UINib(nibName: "ChatOwnerTableViewCell", bundle: nil)
        chatDetailsTableView.register(ownerNib, forCellReuseIdentifier: "ChatOwnerTableViewCell")
        
        let userNib = UINib(nibName: "ChatUserTableViewCell", bundle: nil)
        chatDetailsTableView.register(userNib, forCellReuseIdentifier: "ChatUserTableViewCell")
        
        fetchChats()
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(micButtonLongPressed(_:)))
        longPressRecognizer.numberOfTouchesRequired = 1
        longPressRecognizer.allowableMovement = 10
        longPressRecognizer.minimumPressDuration = 0.5
        micButton.addGestureRecognizer(longPressRecognizer)
        
        messageTextField.delegate = self
        galleryButton.isHidden = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewClickSelector))
        view.addGestureRecognizer(tapGesture)
        
        messageTextField.addTarget(self, action: #selector(textFieldDidChange(_:)),
                                  for: .editingChanged)
        // chatDetailsTableView.rowHeight = UITableView.automaticDimension
        // chatDetailsTableView.estimatedRowHeight = 150
        
        checkForUnreadMessage()
        
        var height = self.view.frame.height - (chatDetailsTableView.frame.origin.y + chatView.frame.height + 50)
        tableViewHeight = Int(height)
        tableViewHeightConstraint.constant = CGFloat(tableViewHeight)
       
        print("X: \(chatDetailsTableView.frame.origin.y)")
        print("View bottom x : \(self.view.frame.height)")
        print("Height: \(height)")
    }
    
    func checkForUnreadMessage(){
        if (chatDetail?.isNewChat == true){
            print("Is new chat")
            var newChatArray = [String]()
            let defaultStore: Firestore?
            defaultStore = Firestore.firestore()
            let communityId : String = (UserDefaults.standard.string(forKey: Constants.COMMUNITY_ID) ?? "") as String
            let loggedUserId : String = Auth.auth().currentUser!.uid
            let threadOrderDoc = defaultStore?.collection("users").document(loggedUserId).collection("communitySettings").document(communityId)
            threadOrderDoc!.getDocument { (document, error) in
                if let document = document, document.exists {
                    if(document.get("newChatThreads") != nil){
                        let newChatThreadArray = document.get("newChatThreads") as! [String]
                        for thread in newChatThreadArray{
                            newChatArray.append(thread)
                        }
                        
                        let threadToRemove = self.chatDetail?.threadId
                        let index = newChatArray.firstIndex(of: threadToRemove!)
                        if(index != nil){
                            newChatArray.remove(at: index!)
                            
                            for newChat in newChatArray{
                                print("Final Array: \(newChat)")
                            }
                            
                            let chatData: [String:Any] = [
                                "newChatThreads": newChatArray
                            ]
                            
                            threadOrderDoc?.updateData(chatData){ err in
                                if err != nil {
                                    print("Error updating Profile. Try again.")
                                } else {
                                    print("Profile updated successfully")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func viewClickSelector(){
        view.endEditing(true)
        if(previousSmileyIndex != -1){
            let chat = searchChats[previousSmileyIndex]
            chat.showSmileys = false
            let previousIndexPath = IndexPath(row: previousSmileyIndex, section: 0)
            chatDetailsTableView.reloadRows(at: [previousIndexPath], with: .none)
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField.text!.count > 0){
            galleryButton.isHidden = true
        }else{
            galleryButton.isHidden = false
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
    
    func getAudioDuration(messageDuration: Int) -> String{
        var audioDuration=""
        let seconds = Int(messageDuration/1000)
        switch seconds{
        case 0..<10: audioDuration = "00:0\(seconds)"
        case 10..<60: audioDuration = "00:\(seconds)"
        case 60..<10000:
            let sec = Double(messageDuration/1000)
            audioDuration = sec.minuteSecond
        default: audioDuration = "00:00"
        }
        return audioDuration
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (searchChats.count > indexPath.row ){
            let chat = searchChats[indexPath.row]
            
            switch chat.userType{
            case TYPE_OWNER:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChatOwnerTableViewCell", for: indexPath)
                as! ChatOwnerTableViewCell
                
                cell.chatOwnerView.layer.cornerRadius = 10
                cell.chatOwnerView.layer.masksToBounds = true
                if ((chatDetail?.memberList.count)! > 2){
                    cell.chatOwnerNameLabel.text = chat.user
                }
                cell.chatOwnerMessageDateLabel.text = getMessagePostedDay(date: chat.messageDate as Date)
                
                cell.chatOwnerReplyLabel.isHidden = true
                if(chat.replyToId != ""){
                    let replyChat = searchChats.first(where: {$0.chatId == chat.replyToId})
                    cell.chatOwnerReplyLabel.isHidden = false
                    cell.chatOwnerReplyLabel.text = " " + (replyChat?.message ?? "")
                }
                
                if(chat.showSmileys == true){
                    cell.smileysView.isHidden = false
                }else{
                    cell.smileysView.isHidden = true
                }
                
                let showSmileysTapped = UITapGestureRecognizer(target: self, action: #selector(showSmileysTapped))
                cell.chatOwnerShowSmileysButton.isUserInteractionEnabled = true
                cell.chatOwnerShowSmileysButton.tag = indexPath.row
                cell.chatOwnerShowSmileysButton.addGestureRecognizer(showSmileysTapped)
                
                let showLaughTapped = UITapGestureRecognizer(target: self, action: #selector(showLaughTapped))
                cell.happyButton.tag = indexPath.row
                cell.happyButton.addGestureRecognizer(showLaughTapped)
                
                let showSurpriseTapped = UITapGestureRecognizer(target: self, action: #selector(showSurpriseTapped))
                cell.surpriseButton.tag = indexPath.row
                cell.surpriseButton.addGestureRecognizer(showSurpriseTapped)
                
                let showSadTapped = UITapGestureRecognizer(target: self, action: #selector(showSadTapped))
                cell.sadButton.tag = indexPath.row
                cell.sadButton.addGestureRecognizer(showSadTapped)
                
                let showAngryTapped = UITapGestureRecognizer(target: self, action: #selector(showAngryTapped))
                cell.angryButton.tag = indexPath.row
                cell.angryButton.addGestureRecognizer(showAngryTapped)
                
                let showThumbsTapped = UITapGestureRecognizer(target: self, action: #selector(showThumbsTapped))
                cell.thumbsUpButton.tag = indexPath.row
                cell.thumbsUpButton.addGestureRecognizer(showThumbsTapped)
                
                let loveTapped = UITapGestureRecognizer(target: self, action: #selector(showLoveTapped))
                cell.loveButton.tag = indexPath.row
                cell.loveButton.addGestureRecognizer(loveTapped)
                
                let margins = view.layoutMarginsGuide
                cell.chatOwnerParentView.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 20).isActive = true
                
                cell.chatOwnerMessageLabel.isHidden = false
                cell.chatOwnerMessageLabel.translatesAutoresizingMaskIntoConstraints = false
                cell.chatOwnerImageView.isHidden = true
                cell.chatOwnerAudioView.isHidden = true
                cell.chatOwnerImageView.removeConstraints(cell.chatOwnerImageView.constraints)
                cell.chatOwnerAudioView.removeConstraints(cell.chatOwnerAudioView.constraints)
                
                cell.chatOwnerSmileyCollectionView.dataSource = self
                cell.chatOwnerSmileyCollectionView.delegate = self
                let collectionNib = UINib(nibName: "ChatOwnerCollectionViewCell", bundle: nil)
                cell.chatOwnerSmileyCollectionView.register(collectionNib, forCellWithReuseIdentifier: "ChatOwnerCollectionViewCell")
                self.smileys.removeAll()
                self.smileys = chat.smileys
                cell.chatOwnerSmileyCollectionView.reloadData()
                
                switch chat.messageType{
                case MESSAGE_TYPE_TEXT:
                    cell.chatOwnerMessageLabel.text = chat.message
                case MESSAGE_TYPE_IMAGE:
                    cell.chatOwnerMessageLabel.isHidden = true
                    cell.chatOwnerImageView.isHidden = false
                    cell.chatOwnerImageView.image = nil
                    cell.chatOwnerView.addSubview(cell.chatOwnerImageView)
                    cell.chatOwnerImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
                    
                    if(chat.message != ""){
                        imageLoaderCache.obtainImageWithPath(imagePath: chat.message) { (image) in
                            if let updateCell = tableView.cellForRow(at: indexPath) {
                                cell.chatOwnerImageView.image = image
                            }
                        }
                    }
                    
                    
                case MESSAGE_TYPE_AUDIO:
                    cell.chatOwnerTimerLabel.text = getAudioDuration(messageDuration: chat.messageDuration)
                    cell.chatOwnerMessageLabel.isHidden = true
                    cell.chatOwnerImageView.isHidden = true
                    cell.chatOwnerAudioView.isHidden = false
                    cell.chatOwnerAudioView.heightAnchor.constraint(equalToConstant: 60).isActive = true
                    
                    let playTapped = UITapGestureRecognizer(target: self, action: #selector(playTapped))
                    cell.chatOwnerPlayPauseButton.isUserInteractionEnabled = true
                    cell.chatOwnerPlayPauseButton.tag = indexPath.row
                    cell.chatOwnerPlayPauseButton.addGestureRecognizer(playTapped)
                    
                    if(chat.audioPlaying == true){
                        if (currentAudioPlayState == AUDIO_STATE_PAUSE) {
                            cell.chatOwnerPlayPauseButton.setImage(UIImage(named: "playblue.png"), for: .normal)
                            chat.audioPlaying = false
                            let currentTime : Float64 = CMTimeGetSeconds(self.player.currentTime())
                            cell.chatOwnerHorizontalSlider.value = Float(currentTime)
                            if(currentTime > 0){
                                let intTime = Int(currentTime)
                                cell.chatOwnerTimerLabel.text = "00:\(intTime)"
                            }
                            timer?.invalidate()
                        }else{
                            cell.chatOwnerPlayPauseButton.setImage(UIImage(named: "pause.png"), for: .normal)
                            
                            let duration = CMTime(seconds: Double(chat.messageDuration/1000), preferredTimescale: 1000000)
                            let durationSec : Float64 = CMTimeGetSeconds(duration)
                            cell.chatOwnerHorizontalSlider.maximumValue = Float(CMTimeGetSeconds(duration))
                            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true){ timer in
                                let currentTime : Float64 = CMTimeGetSeconds(self.player.currentTime())
                                cell.chatOwnerHorizontalSlider.value = Float(currentTime)
                                if(currentTime > 0){
                                    let intTime = Int(currentTime)
                                    cell.chatOwnerTimerLabel.text = "00:\(intTime)"
                                }
                                guard !(currentTime.isNaN || currentTime.isInfinite) else {
                                    return
                                }
                                if(Int(durationSec) == Int(currentTime)){
                                    timer.invalidate()
                                }
                            }
                        }
                    }else{
                        cell.chatOwnerPlayPauseButton.setImage(UIImage(named: "playblue.png"), for: .normal)
                        cell.chatOwnerHorizontalSlider.value = 0
                        timer?.invalidate()
                    }
                    
                case MESSAGE_TYPE_VIDEO: print("Video")
                    
                default: print("Default")
                }
                
                return cell
                
            case TYPE_USER:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChatUserTableViewCell", for: indexPath)
                as! ChatUserTableViewCell
                
                cell.chatUserView.layer.cornerRadius = 10
                cell.chatUserView.layer.masksToBounds = true
                if ((chatDetail?.memberList.count)! > 2){
                    cell.chatUserNameLabel.text = chat.user
                }
                cell.chatUserMessageDateLabel.text = getMessagePostedDay(date: chat.messageDate as Date)
                
                cell.chatUserReplyLabel.isHidden = true
                if(chat.replyToId != ""){
                    let replyChat = searchChats.first(where: {$0.chatId == chat.replyToId})
                    cell.chatUserReplyLabel.isHidden = false
                    cell.chatUserReplyLabel.text = " " + (replyChat?.message ?? "")
                }
                
                if(chat.showSmileys == true){
                    cell.chatUserSmileysView.isHidden = false
                }else{
                    cell.chatUserSmileysView.isHidden = true
                }
                
                let showSmileysTapped = UITapGestureRecognizer(target: self, action: #selector(showSmileysTapped))
                cell.showUserSmileysButton.isUserInteractionEnabled = true
                cell.showUserSmileysButton.tag = indexPath.row
                cell.showUserSmileysButton.addGestureRecognizer(showSmileysTapped)
                
                let showLaughTapped = UITapGestureRecognizer(target: self, action: #selector(showLaughTapped))
                cell.userHappyButton.tag = indexPath.row
                cell.userHappyButton.addGestureRecognizer(showLaughTapped)
                
                let showSurpriseTapped = UITapGestureRecognizer(target: self, action: #selector(showSurpriseTapped))
                cell.userSurpriseButton.tag = indexPath.row
                cell.userSurpriseButton.addGestureRecognizer(showSurpriseTapped)
                
                let showSadTapped = UITapGestureRecognizer(target: self, action: #selector(showSadTapped))
                cell.userSadButton.tag = indexPath.row
                cell.userSadButton.addGestureRecognizer(showSadTapped)
                
                let showAngryTapped = UITapGestureRecognizer(target: self, action: #selector(showAngryTapped))
                cell.userAngryButton.tag = indexPath.row
                cell.userAngryButton.addGestureRecognizer(showAngryTapped)
                
                let showThumbsTapped = UITapGestureRecognizer(target: self, action: #selector(showThumbsTapped))
                cell.userThumbsUpButton.tag = indexPath.row
                cell.userThumbsUpButton.addGestureRecognizer(showThumbsTapped)
                
                let loveTapped = UITapGestureRecognizer(target: self, action: #selector(showLoveTapped))
                cell.userLoveButton.tag = indexPath.row
                cell.userLoveButton.addGestureRecognizer(loveTapped)
                
                let replyToTapped = UITapGestureRecognizer(target: self, action: #selector(replyToTapped))
                cell.userReplyButton.tag = indexPath.row
                cell.userReplyButton.addGestureRecognizer(replyToTapped)
                
                cell.chatUserMessageLabel.isHidden = false
                cell.chatUserMessageLabel.translatesAutoresizingMaskIntoConstraints = false
                cell.chatUserImageView.isHidden = true
                cell.chatUserAudioView.isHidden = true
                cell.chatUserImageView.removeConstraints(cell.chatUserImageView.constraints)
                cell.chatUserAudioView.removeConstraints(cell.chatUserAudioView.constraints)
                
                cell.chatUserSmileysCollectionView.dataSource = self
                cell.chatUserSmileysCollectionView.delegate = self
                let collectionNib = UINib(nibName: "ChatUserCollectionViewCell", bundle: nil)
                cell.chatUserSmileysCollectionView.register(collectionNib, forCellWithReuseIdentifier: "ChatUserCollectionViewCell")
                self.smileys.removeAll()
                self.smileys = chat.smileys
                cell.chatUserSmileysCollectionView.reloadData()
                
                switch chat.messageType{
                case MESSAGE_TYPE_TEXT:
                    cell.chatUserMessageLabel.text = chat.message
                case MESSAGE_TYPE_IMAGE:
                    cell.chatUserMessageLabel.isHidden = true
                    cell.chatUserImageView.isHidden = false
                    cell.chatUserImageView.image = nil
                    cell.chatUserImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
                    
                    if(chat.message != ""){
                        imageLoaderCache.obtainImageWithPath(imagePath: chat.message) { (image) in
                            if let updateCell = tableView.cellForRow(at: indexPath) {
                                cell.chatUserImageView.image = image
                            }
                        }
                    }
                    
                case MESSAGE_TYPE_AUDIO:
                    cell.chatUserTimerLabel.text = getAudioDuration(messageDuration: chat.messageDuration)
                    cell.chatUserMessageLabel.isHidden = true
                    cell.chatUserImageView.isHidden = true
                    cell.chatUserAudioView.isHidden = false
                    cell.chatUserAudioView.heightAnchor.constraint(equalToConstant: 60).isActive = true
                    
                    let playTapped = UITapGestureRecognizer(target: self, action: #selector(playTapped))
                    cell.chatUserPlayPauseButton.isUserInteractionEnabled = true
                    cell.chatUserPlayPauseButton.tag = indexPath.row
                    cell.chatUserPlayPauseButton.addGestureRecognizer(playTapped)
                    
                    if(chat.audioPlaying == true){
                        if (currentAudioPlayState == AUDIO_STATE_PAUSE) {
                            cell.chatUserPlayPauseButton.setImage(UIImage(named: "playblue.png"), for: .normal)
                            chat.audioPlaying = false
                            let currentTime : Float64 = CMTimeGetSeconds(self.player.currentTime())
                            cell.chatUserHorizontalSlider.value = Float(currentTime)
                            if(currentTime > 0){
                                let intTime = Int(currentTime)
                                cell.chatUserTimerLabel.text = "00:\(intTime)"
                            }
                            timer?.invalidate()
                        }else{
                            cell.chatUserPlayPauseButton.setImage(UIImage(named: "pause.png"), for: .normal)
                            let duration = CMTime(seconds: Double(chat.messageDuration/1000), preferredTimescale: 1000000)
                            let durationSec : Float64 = CMTimeGetSeconds(duration)
                            cell.chatUserHorizontalSlider.maximumValue = Float(CMTimeGetSeconds(duration))
                            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true){ timer in
                                let currentTime : Float64 = CMTimeGetSeconds(self.player.currentTime())
                                cell.chatUserHorizontalSlider.value = Float(currentTime)
                                
                                if(currentTime > 0){
                                    let intTime = Int(currentTime)
                                    cell.chatUserTimerLabel.text = "00:\(intTime)"
                                }
                                
                                guard !(currentTime.isNaN || currentTime.isInfinite) else {
                                    return
                                }
                                if(Int(durationSec) == Int(currentTime)){
                                    timer.invalidate()
                                }
                            }
                        }
                    }else{
                        cell.chatUserPlayPauseButton.setImage(UIImage(named: "playblue.png"), for: .normal)
                        cell.chatUserHorizontalSlider.value = 0
                        timer?.invalidate()
                    }
                    
                case MESSAGE_TYPE_VIDEO: print("Video")
                    
                default: print("Default")
                }
                
                return cell
                
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "ChatUserTableViewCell", for: indexPath)
                as! ChatUserTableViewCell
                
                return cell
            }
        }
        
        return tableView.dequeueReusableCell(withIdentifier: "ChatOwnerTableViewCell", for: indexPath)
        as! ChatOwnerTableViewCell
    }
    
    @objc func playTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        let chat = searchChats[view.tag]
        if(chat.audioPlaying == true){
            pauseAudio(view: view)
        }else{
            if(previousAudioIndex != -1 && view.tag != previousAudioIndex){
                stopAudio()
                let previousAudioItem = searchChats[previousAudioIndex]
                previousAudioItem.audioPlaying = false
                let previousIndexPath = IndexPath(row: previousAudioIndex, section: 0)
                chatDetailsTableView.reloadRows(at: [previousIndexPath], with: .none)
            }
            
            previousAudioIndex = view.tag
            
            if (currentAudioPlayState == AUDIO_STATE_PAUSE){
                playAudio(chat: chat, view: view, playState: "continue")
            }else{
                playAudio(chat: chat, view: view)
            }
        }
    }
    
    func playAudio(chat: ChatMessage, view: UIView, playState: String = "play"){
        currentAudioPlayState = AUDIO_STATE_PLAY
        chat.audioPlaying = true
        let indexPath = IndexPath(row: view.tag, section: 0)
        chatDetailsTableView.reloadRows(at: [indexPath], with: .none)
        if(playState == "play"){
            playSound(chatMessage: chat, row: view.tag )
        }else{
            self.player.play()
        }
    }
    
    func pauseAudio(view: UIView){
        currentAudioPlayState = AUDIO_STATE_PAUSE
        let indexPath = IndexPath(row: view.tag, section: 0)
        chatDetailsTableView.reloadRows(at: [indexPath], with: .none)
        self.player.pause()
    }
    
    func stopAudio(){
        currentAudioPlayState = AUDIO_STATE_STOP
        self.player.pause()
        self.player.replaceCurrentItem(with: nil)
    }
    
    func playSound(chatMessage: ChatMessage, row: Int) {
        let storage = Storage.storage()
        let storageReference = storage.reference(forURL: chatMessage.message)
        storageReference.downloadURL { (hardUrl, error) in
            if error == nil, let url = hardUrl {
                //print("URL: \(url)")
                let playerItem = AVPlayerItem(url: url)
                self.player = AVPlayer(playerItem: playerItem)
                self.player.play()
                self.player.volume = 1.0
                self.player.addObserver(self, forKeyPath: "status", options: .new, context: nil)
                }
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { noti in
                    guard noti.object is AVPlayerItem else{
                            return
                        }
                    self.player.pause()
                    self.player.replaceCurrentItem(with: nil)
                    chatMessage.audioPlaying = false
                    let indexPath = IndexPath(row: row, section: 0)
                    self.chatDetailsTableView.reloadRows(at: [indexPath], with: .none)
                }
            }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "status") {
            let status: AVPlayer.Status = self.player.status
            if(status == AVPlayer.Status.readyToPlay){
                print("Ready to play")
            }
            else{
                if( status == AVPlayer.Status.unknown){
                    print("failed")
                }
            }
        }
    }
    
    @objc func showSmileysTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        let chat = searchChats[view.tag]
        chat.showSmileys = true
      
        let indexPath = IndexPath(row: view.tag, section: 0)
        chatDetailsTableView.reloadRows(at: [indexPath], with: .none)
        
        if(previousSmileyIndex != -1 && view.tag != previousSmileyIndex){
            let chat = searchChats[previousSmileyIndex]
            chat.showSmileys = false
            let previousIndexPath = IndexPath(row: previousSmileyIndex, section: 0)
            chatDetailsTableView.reloadRows(at: [previousIndexPath], with: .none)
            self.player.pause()
        }
        
        previousSmileyIndex = view.tag
    }
    
    @objc func showThumbsTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        let chat = searchChats[view.tag]
        chat.showSmileys = false
        let indexPath = IndexPath(row: view.tag, section: 0)
        chatDetailsTableView.reloadRows(at: [indexPath], with: .none)
        updateSmileyToFirebase(smiley: "THUMB_UP", chat: chat)
    }
    
    @objc func showLoveTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        let chat = searchChats[view.tag]
        chat.showSmileys = false
        let indexPath = IndexPath(row: view.tag, section: 0)
        chatDetailsTableView.reloadRows(at: [indexPath], with: .none)
        updateSmileyToFirebase(smiley: "LOVE", chat: chat)
    }
    
    @objc func showLaughTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        let chat = searchChats[view.tag]
        chat.showSmileys = false
        let indexPath = IndexPath(row: view.tag, section: 0)
        chatDetailsTableView.reloadRows(at: [indexPath], with: .none)
        updateSmileyToFirebase(smiley: "LAUGH", chat: chat)
    }
    
    @objc func showSurpriseTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        let chat = searchChats[view.tag]
        chat.showSmileys = false
        let indexPath = IndexPath(row: view.tag, section: 0)
        chatDetailsTableView.reloadRows(at: [indexPath], with: .none)
        updateSmileyToFirebase(smiley: "SURPRISE", chat: chat)
    }
    
    @objc func showSadTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        let chat = searchChats[view.tag]
        chat.showSmileys = false
        let indexPath = IndexPath(row: view.tag, section: 0)
        chatDetailsTableView.reloadRows(at: [indexPath], with: .none)
        updateSmileyToFirebase(smiley: "SAD", chat: chat)
    }
    
    @objc func showAngryTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        let chat = searchChats[view.tag]
        chat.showSmileys = false
        let indexPath = IndexPath(row: view.tag, section: 0)
        chatDetailsTableView.reloadRows(at: [indexPath], with: .none)
        updateSmileyToFirebase(smiley: "ANGRY", chat: chat)
    }
    
    func updateSmileyToFirebase(smiley: String, chat: ChatMessage){
        
        let userId : String = Auth.auth().currentUser?.uid ?? ""
        var reaction : [String:[String]] = ["ANGRY": chat.reaction.angry, "LAUGH": chat.reaction.laugh,
                                            "SAD": chat.reaction.sad, "LOVE": chat.reaction.love,
                                            "SURPRISE": chat.reaction.surprise, "THUMB_UP": chat.reaction.thumbsUp]
        switch smiley{
        case "ANGRY":
            if chat.reaction.angry.contains(userId){
                let index = chat.reaction.angry.firstIndex(of: userId)
                chat.reaction.angry.remove(at: index!)
            }else{
                chat.reaction.angry.append(userId)
            }
            var angry = [String]()
            for obj in chat.reaction.angry{
                angry.append(obj)
            }
            reaction.updateValue(angry, forKey: "ANGRY")
        case "LAUGH":
            if chat.reaction.laugh.contains(userId){
                let index = chat.reaction.laugh.firstIndex(of: userId)
                chat.reaction.laugh.remove(at: index!)
            }else{
                chat.reaction.laugh.append(userId)
            }
            var laugh = [String]()
            for obj in chat.reaction.angry{
                laugh.append(obj)
            }
            reaction.updateValue(laugh, forKey: "LAUGH")
        case "SURPRISE":
            if chat.reaction.surprise.contains(userId){
                let index = chat.reaction.surprise.firstIndex(of: userId)
                chat.reaction.surprise.remove(at: index!)
            }else{
                chat.reaction.surprise.append(userId)
            }
            var surprise = [String]()
            for obj in chat.reaction.surprise{
                surprise.append(obj)
            }
            reaction.updateValue(surprise, forKey: "SURPRISE")
        case "SAD":
            if chat.reaction.sad.contains(userId){
                let index = chat.reaction.sad.firstIndex(of: userId)
                chat.reaction.sad.remove(at: index!)
            }else{
                chat.reaction.sad.append(userId)
            }
            var sad = [String]()
            for obj in chat.reaction.sad{
                sad.append(obj)
            }
            reaction.updateValue(sad, forKey: "SAD")
        case "LOVE":
            if chat.reaction.love.contains(userId){
                let index = chat.reaction.love.firstIndex(of: userId)
                chat.reaction.love.remove(at: index!)
            }else{
                chat.reaction.love.append(userId)
            }
            var love = [String]()
            for obj in chat.reaction.love{
                love.append(obj)
            }
            reaction.updateValue(love, forKey: "LOVE")
        case "THUMB_UP":
            if chat.reaction.thumbsUp.contains(userId){
                let index = chat.reaction.thumbsUp.firstIndex(of: userId)
                chat.reaction.thumbsUp.remove(at: index!)
            }else{
                chat.reaction.thumbsUp.append(userId)
            }
            var thumbsUp = [String]()
            for obj in chat.reaction.thumbsUp{
                thumbsUp.append(obj)
            }
            reaction.updateValue(thumbsUp, forKey: "THUMB_UP")
        
        default: print("Default")
        }
        
        let childUpdates = ["/chats/\(self.chatDetail!.threadId)/messages/\(chat.chatId)/reactions": reaction]
        Database.database().reference().updateChildValues(childUpdates)
        self.viewDidLoad()
        shouldScrollToBottom = false
    }
    
    @objc func replyToTapped(tapGestureRecognizer: UITapGestureRecognizer){
        let view = tapGestureRecognizer.view as! UIButton
        let chat = searchChats[view.tag]
        switch chat.messageType{
        case MESSAGE_TYPE_TEXT:  replyToLabel.text = "Reply To: \(chat.message)"
        case MESSAGE_TYPE_IMAGE:  replyToLabel.text = "Reply To: Image"
        case MESSAGE_TYPE_AUDIO:  replyToLabel.text = "Reply To: Audio"
        default: print("Other")
        }
        replyToId = chat.chatId
        replyToView.isHidden = false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (searchChats.count > indexPath.row){
            return self.searchChats[indexPath.row].messageHeight
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchChats.count
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        self.player.pause()
        self.player.replaceCurrentItem(with: nil)
        chatDetailsProtocol?.reloadChatList()
    }
    
    @IBAction func callAction(_ sender: Any) {
        self.performSegue(withIdentifier: "videoCallSegue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! VideoCallViewController
        destinationVC.channelName = chatDetail?.threadId ?? ""
        destinationVC.fromNotification = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
                guard !searchText.isEmpty
                    else {
                        searchChats = chats
                        chatDetailsTableView.reloadData()
                        return
                }
        
                searchChats = chats.filter({Chat -> Bool in
                    guard let text = searchBar.text else {return false}
                    return Chat.message.contains(text)
                })
        
                chatDetailsTableView.reloadData()
    }
    
    func fetchChats(){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        
        if(chatDetail?.threadId == nil || chatDetail?.threadId == ""){
            return
        }
        
        var ref: DatabaseReference!
        ref = Database.database().reference().child("chats").child(chatDetail!.threadId).child("messages")
        
        let jurniGroup =  DispatchGroup()
        chats.removeAll()
        searchChats.removeAll()
        showActivityIndicator()
        ref.getData(completion:  { error, snapshot in
            guard error == nil else {
                print(error!.localizedDescription)
                return;
            }
            
            let userId : String = Auth.auth().currentUser!.uid
            for document in snapshot!.children {
               // print("\(document)")
                let documentSnapshot = document as? DataSnapshot
                let dict = documentSnapshot?.value as? NSDictionary
                
                var messageType = ""
                if(dict?["type"] != nil){
                     messageType = dict?["type"] as! String
                }else{
                    continue
                }
                let user : String = dict?["from"] as! String
                let timeStamp = dict?["timestamp"] as! NSDictionary
                let messageDate = NSDate(timeIntervalSince1970: timeStamp["seconds"] as! TimeInterval)
                
                var chatId = ""
                if(dict?["message_id"] != nil){
                    chatId = dict?["message_id"] as! String
                }
                
                var replyToId = ""
                if(dict?["reply_to_id"] != nil){
                    replyToId = dict?["reply_to_id"] as! String
                }
                
                var message: String = ""
                let meta = dict?["meta"] as! NSDictionary
                var messageDuration = 0
                var messageHeight : CGFloat = 150
                switch messageType{
                case self.MESSAGE_TYPE_TEXT:
                    message = meta["content"] as! String
                    messageHeight = self.getTextMessageHeight(message: message)
                case self.MESSAGE_TYPE_IMAGE:
                    if(meta["url"] != nil){
                        message  = meta["url"] as! String
                        messageHeight = 170
                    }
                case self.MESSAGE_TYPE_AUDIO:
                    message  = meta["url"] as! String
                    messageDuration = meta["duration"] as! Int
                    messageHeight = 130
                case self.MESSAGE_TYPE_OTHER:
                    if (meta["originalFileName"] != nil && (meta["originalFileName"] as! String).contains(".MP4")){
                        message = meta["url"] as! String
                        messageType = self.MESSAGE_TYPE_VIDEO
                    }
                    continue
                default:print("default")
                    continue
                }
                
                var reaction = Reaction()
                var smileys = [String]()
                if(dict?["reactions"] != nil){
                    let reactions = dict?["reactions"] as! NSDictionary
                    if(reactions["ANGRY"] != nil){
                        if let angry = reactions["ANGRY"] as? [String]{
                            reaction.angry = angry
                            smileys.append("ANGRY")
                        }
                    }
                    
                    if(reactions["LAUGH"] != nil){
                        if let laugh = reactions["LAUGH"] as? [String]{
                            reaction.laugh = laugh
                            smileys.append("LAUGH")
                        }
                    }
                    
                    if(reactions["SAD"] != nil){
                        if let sad = reactions["SAD"] as? [String]{
                            reaction.sad = sad
                            smileys.append("SAD")
                        }
                    }
                    
                    if(reactions["LOVE"] != nil){
                        if let love = reactions["LOVE"] as? [String]{
                            reaction.love = love
                            smileys.append("LOVE")
                        }
                    }
                    
                    if(reactions["SURPRISE"] != nil){
                        if let surprise = reactions["SURPRISE"] as? [String]{
                            reaction.surprise = surprise
                            smileys.append("SURPRISE")
                        }
                    }
                    
                    if(reactions["THUMB_UP"] != nil){
                        if let thumbs = reactions["THUMB_UP"] as? [String]{
                            reaction.thumbsUp = thumbs
                            smileys.append("THUMB_UP")
                        }
                    }
                }
                
                var userType: String = ""
                if (user == userId){
                    userType = self.TYPE_OWNER
                }else{
                    userType = self.TYPE_USER
                }
                
                jurniGroup.enter()
                let docRef = defaultStore?.collection("users").document(user)
                docRef!.getDocument { (document, error) in
                    if let document = document, document.exists {
                        
                        var userName: String = ""
                        if(document.get("firstName") as? String != nil){
                            userName = document.get("firstName") as? String ?? ""
                        }
                        
                        if(document.get("lastName") as? String != nil){
                            userName += " " + (document.get("lastName") as? String ?? "")
                        }
                        
                        self.chats.append(ChatMessage(chatId: chatId,userType: userType, user: userName, message: message, messageType: messageType, messageDate: messageDate, reaction: reaction, messageDuration: messageDuration, messageHeight: messageHeight, showSmileys: false,
                            smileys: smileys, audioPlaying: false, replyToId: replyToId))
                        jurniGroup.leave()
                    }
                }
            }
            
            jurniGroup.notify(queue: .main) {
                self.hideActivityIndicator()
                self.chats = self.chats.sorted(by: { $0.messageDate.compare($1.messageDate as Date) == .orderedAscending })
                self.searchChats = self.chats
                self.chatDetailsTableView.reloadData()
                if(self.searchChats.count > 0 && self.shouldScrollToBottom == true){
                    let index = IndexPath(row: self.searchChats.count-1, section: 0)
                    self.chatDetailsTableView.scrollToRow(at: index, at: .bottom, animated: true)
                }
            }
        });
    }
    
    func getTextMessageHeight(message: String) -> CGFloat{
        let newLines = message.components(separatedBy: "\n\n").filter { !$0.isEmpty }
        let words = message.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let rows = words.count/5 + newLines.count
        let height = CGFloat(75 + rows*15)
      //  print("Message: \(message)")
      //  print("Words: \(words.count) New Lines: \(newLines.count) Rows: \(rows) Height: \(height)")
      //  print("----------------")
        return height
    }
    
    //send text to firebase
    @IBAction func sendMessage(_ sender: Any) {
        if(messageTextField.text?.trimmingCharacters(in: .whitespaces).isEmpty == false){
            self.showActivityIndicator()
            if(replyToId == ""){
                self.postDataToFirebase(dataType: MESSAGE_TYPE_TEXT, content: ["content": messageTextField.text!])
            }else{
                self.postDataToFirebase(dataType: MESSAGE_TYPE_TEXT, content: ["content": messageTextField.text!],
                replyToId: replyToId)
            }
        }
    }
    
    //send image to firebase
    @IBAction func selectMediaAction(_ sender: Any) {
        takePhotoFromGallery()
    }
    
    func takePhotoFromGallery() {
        imagePicker.delegate = self
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.allowsEditing = false
        
        present(imagePicker, animated: true)
    }
        
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            uploadImage(image: pickedImage)
        }
        
        self.dismiss(animated: true)
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func uploadImage(image: UIImage) {
          self.showActivityIndicator()
          let imageName:String = String("\(randomString(length: 5)).png")
          let storageRef = Storage.storage().reference().child("profilePic").child(imageName)
          if let uploadData = image.pngData(){
                storageRef.putData(uploadData, metadata: nil
                    , completion: { (metadata, error) in
                    if error == nil, metadata != nil {
                                storageRef.downloadURL { url, error in
                                    let profilePicUrl = url?.absoluteString
                                    let content : [String: Any] = ["url": profilePicUrl!,"originalFileName":imageName]
                                    self.postDataToFirebase(dataType: self.MESSAGE_TYPE_IMAGE, content: content)
                                 }
                                } else {
                                    print("Failed")
                                }
                            })
                }
    }
   
    func showAlert(message: String){
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    //send audio to firebase
    @objc func micButtonLongPressed(_ sender: UILongPressGestureRecognizer) {
        
        if(checkMicPermission() == false){
            showAlert(message: "Please allow access to microphone to record and send audio message.")
            return
        }
        
        if audioRecorder == nil {
              print("Recording started")
               let filename = getAudioFileURL()
               let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                               AVSampleRateKey: 12000,
                               AVNumberOfChannelsKey: 2,
                               AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]

               do {
                   audioRecorder = try AVAudioRecorder(url: filename, settings: settings)
                   audioRecorder?.delegate = self
                   audioRecorder?.record()

                   self.micButton.setBackgroundImage(UIImage(named: "micpink.png"), for: .normal)
                   hideViewsForAudioRecording()
                   audioTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
               } catch {
                 print("Exception 1")
               }
        } else {
            print("Reording stopped")
            audioRecorder?.stop()
            audioRecorder = nil
            
            self.micButton.setBackgroundImage(UIImage(named: "mic.png"), for: .normal)
            showViewsAfterAudioRecording()
            audioTimer.invalidate()
            audioTimerLabel.text = "00:00"
            self.timeCount = 0
            
            let fileUrl = getAudioFileURL()
            var duration = 0
            do{
                let audioPlayer = try AVAudioPlayer(contentsOf: fileUrl)
                let fileDuration = CGFloat(audioPlayer.duration*1000)
                duration = Int(fileDuration)
                print("Duration: \(duration)")
            }catch{
                print("Exception 2")
            }
           
            if(duration > 1000){
                self.showActivityIndicator()
                let audioName:String = String("\(randomString(length: 5)).mp3")
                let storageRef = Storage.storage().reference().child("userAudio").child(audioName)
                storageRef.putFile(from: fileUrl,completion: {
                    (metadata, error) in
                    if error == nil, metadata != nil {
                        storageRef.downloadURL { url, error in
                            let audioUrl = url?.absoluteString
                            let content : [String: Any] = ["url": audioUrl!,"originalFileName":audioName, "duration": duration]
                              self.postDataToFirebase(dataType: self.MESSAGE_TYPE_AUDIO, content: content)
                        }
                    } else {
                        self.hideActivityIndicator()
                        print("Failed")
                    }
                })
            }
           }
    }
    
    @objc func timerCounter() -> Void{
            timeCount = timeCount+1
            let time = secondsToMinutesSeconds(seconds: timeCount)
            let timeString = makeTimeString(minutes: time.0, seconds: time.1)
            audioTimerLabel.text = timeString
    }

    @IBAction func cancelRecordingAction(_ sender: Any) {
        self.micButton.setBackgroundImage(UIImage(named: "mic.png"), for: .normal)
        audioRecorder?.stop()
        audioRecorder = nil
        audioTimer.invalidate()
        audioTimerLabel.text = "00:00"
        self.timeCount = 0
        showViewsAfterAudioRecording()
    }
    
    
    func hideViewsForAudioRecording(){
        textMessageImageView.isHidden = true
        messageTextField.isHidden = true
        sendMessageButton.isHidden = true
        galleryButton.isHidden = true
        cancelImageView.isHidden = false
        audioImageView.isHidden = false
        audioTimerLabel.isHidden = false
    }
    
    func showViewsAfterAudioRecording(){
        textMessageImageView.isHidden = false
        messageTextField.isHidden = false
        sendMessageButton.isHidden = false
        galleryButton.isHidden = false
        cancelImageView.isHidden = true
        audioImageView.isHidden = true
        audioTimerLabel.isHidden = true
        
    }
    
    func getDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }

    func getAudioFileURL() -> URL {
        return getDirectory().appendingPathComponent(".mp3")
    }
    
    func checkMicPermission() -> Bool {
        var permissionCheck: Bool = false
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            permissionCheck = true
        case AVAudioSession.RecordPermission.denied:
            permissionCheck = false
        case AVAudioSession.RecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                if granted {
                    permissionCheck = true
                } else {
                    permissionCheck = false
                }
            })
            default:
                break
            }

            return permissionCheck
        }
    
    //post text,image,audio types of data to firebase
    func postDataToFirebase(dataType: String, content: [String: Any], replyToId: String = ""){
        let seconds = Int(Date().timeIntervalSince1970)
        let timestamp : [String: Any] = ["nanoseconds": 797000000, "seconds": seconds]
        guard let key = Database.database().reference().child("chats").child(self.chatDetail!.threadId).child("messages").childByAutoId().key else { return }
        var post : [String : Any]
        if(replyToId != ""){
            post = ["from": Auth.auth().currentUser!.uid, "thread_id":self.chatDetail!.threadId, "type": dataType, "meta": content, "timestamp": timestamp, "message_id": key, "reply_to_id": replyToId] as [String : Any]
            self.replyToId = ""
            replyToView.isHidden = true
        }else{
            post = ["from": Auth.auth().currentUser!.uid, "thread_id":self.chatDetail!.threadId, "type": dataType, "meta": content, "timestamp": timestamp, "message_id": key] as [String : Any]
        }
        let childUpdates = ["/chats/\(self.chatDetail!.threadId)/messages/\(key)": post]
        Database.database().reference().updateChildValues(childUpdates)
        self.hideActivityIndicator()
       // self.viewDidLoad()
       // self.viewWillAppear(true)
        fetchChats()
        if(dataType == self.MESSAGE_TYPE_TEXT){
            messageTextField.text = ""
            galleryButton.isHidden = false
        }
        shouldScrollToBottom = true
    }
    
    func showActivityIndicator() {
      //  self.view.isUserInteractionEnabled = false
        activityView = UIActivityIndicatorView(style: .large)
        activityView?.center = self.view.center
        activityView?.color = .black
        self.view.addSubview(activityView!)
        activityView?.startAnimating()
    }
    
    func hideActivityIndicator(){
      //  self.view.isUserInteractionEnabled = true
        if (activityView != nil){
            activityView?.stopAnimating()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return smileys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if (collectionView.tag == 1001){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatOwnerCollectionViewCell", for: indexPath) as! ChatOwnerCollectionViewCell
            let item = smileys[indexPath.row]
            switch item{
            case "LAUGH": cell.ownerSmiley.text = "😀"
            case "SAD": cell.ownerSmiley.text = "☹️"
            case "LOVE": cell.ownerSmiley.text = "❤️"
            case "THUMB_UP": cell.ownerSmiley.text = "👍"
            case "ANGRY": cell.ownerSmiley.text = "😠"
            case "SURPRISE": cell.ownerSmiley.text = "😯"
            default: print("")
            }
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChatUserCollectionViewCell", for: indexPath) as! ChatUserCollectionViewCell
            let item = smileys[indexPath.row]
            switch item{
            case "LAUGH": cell.smileyLabel.text = "😀"
            case "SAD": cell.smileyLabel.text = "☹️"
            case "LOVE": cell.smileyLabel.text = "❤️"
            case "THUMB_UP": cell.smileyLabel.text = "👍"
            case "ANGRY": cell.smileyLabel.text = "😠"
            case "SURPRISE": cell.smileyLabel.text = "😯"
            default: print("")
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = (collectionView.frame.size.width - 40)/9
        return CGSize(width: size, height: size)
    }
    
    @IBAction func closeReplyToAction(_ sender: Any) {
        replyToView.isHidden = true
        replyToId = ""
    }
    
    func secondsToMinutesSeconds(seconds: Int) -> ( Int, Int)
    {
        return (((seconds % 3600) / 60),((seconds % 3600) % 60))
    }
        
    func makeTimeString(minutes: Int, seconds : Int) -> String
    {
        var timeString = ""
        timeString += String(format: "%02d", minutes)
        timeString += " : "
        timeString += String(format: "%02d", seconds)
        return timeString
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        tableViewHeightConstraint.constant = CGFloat(tableViewHeight)
        textField.resignFirstResponder()
        return true
    }
    
    @objc func keyboardWillHide() {
      //  self.view.frame.origin.y = 0
        tableViewHeightConstraint.constant = CGFloat(tableViewHeight)
    }

    @objc func keyboardWillChange(notification: NSNotification) {
//            if messageTextField.isFirstResponder {
//                self.view.frame.origin.y = -350
//            }
        
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
              let keyboardHeight = value.cgRectValue.height
            tableViewHeightConstraint.constant = CGFloat(tableViewHeight) - keyboardHeight
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func showGroupList(_ sender: Any) {
        let popUpVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "groupListId") as! GroupMembersViewController
        popUpVC.modalPresentationStyle = .overCurrentContext
        popUpVC.modalTransitionStyle = .crossDissolve
        popUpVC.chatDetail = chatDetail
        present(popUpVC, animated: true, completion: nil)
    }
    
}

extension TimeInterval {
    var hourMinuteSecond: String {
        String(format:"%d:%02d:%02d", hour, minute, second)
    }
    var minuteSecond: String {
        String(format:"%d:%02d", minute, second)
    }
    var hour: Int {
        Int((self/3600).truncatingRemainder(dividingBy: 3600))
    }
    var minute: Int {
        Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    var second: Int {
        Int(truncatingRemainder(dividingBy: 60))
    }
}

typealias ImageCacheLoaderCompletionHandler = ((UIImage) -> ())

class ImageCacheLoader {
    
    var task: URLSessionDownloadTask!
    var session: URLSession!
    var cache: NSCache<NSString, UIImage>!
    
    init() {
        session = URLSession.shared
        task = URLSessionDownloadTask()
        self.cache = NSCache()
    }
    
    func obtainImageWithPath(imagePath: String, completionHandler: @escaping ImageCacheLoaderCompletionHandler) {
        if let image = self.cache.object(forKey: imagePath as NSString) {
            DispatchQueue.main.async {
                completionHandler(image)
            }
        } else {
            let url: URL! = URL(string: imagePath)
            task = session.downloadTask(with: url, completionHandler: { (location, response, error) in
                if let data = try? Data(contentsOf: url) {
                    let img: UIImage! = UIImage(data: data)
                    if(img != nil){
                        self.cache.setObject(img, forKey: imagePath as NSString)
                        DispatchQueue.main.async {
                            completionHandler(img)
                        }
                    }
                }
            })
            task.resume()
        }
    }
}

protocol ChatDetailsProtocol{
    func reloadChatList()
}
