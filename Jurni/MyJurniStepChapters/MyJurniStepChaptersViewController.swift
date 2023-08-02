//
//  MyJurniStepChaptersViewController.swift
//  Jurni
//
//  Created by Devrath Rathee on 19/01/23.
//

import UIKit
import FirebaseFirestore
import AVKit
import AVFoundation
import WebKit
import FirebaseAuth

class MyJurniStepChaptersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var jurniNameLabel: UILabel!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var courseContentLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var chaptersTableView: UITableView!
    @IBOutlet weak var webView: WKWebView!
    var player: AVPlayer!
    var avpPlayerController = AVPlayerViewController()
    var jurniDocument: QueryDocumentSnapshot!
    var stepId:String!
    var chapterArray = [JurniChapter]()
    
    @IBAction func backAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let chapterNib = UINib(nibName: "JurniChapterTableViewCell", bundle: nil)
        chaptersTableView.register(chapterNib, forCellReuseIdentifier: "JurniChapterTableViewCell")
        
        chaptersTableView.dataSource = self
        chaptersTableView.delegate = self
        chaptersTableView.backgroundColor = UIColor.white
        
        getStepChaptersDetails()
        
        jurniNameLabel.text = jurniDocument?.get("name") as? String
        
        let courseContentTapped = UITapGestureRecognizer(target: self, action: #selector(courseContentLabelTapped))
        courseContentLabel.isUserInteractionEnabled = true
        courseContentLabel.addGestureRecognizer(courseContentTapped)
        
        let overviewTapped = UITapGestureRecognizer(target: self, action: #selector(overviewLabelTapped))
        overviewLabel.isUserInteractionEnabled = true
        overviewLabel.addGestureRecognizer(overviewTapped)
    }
    
    @objc func courseContentLabelTapped(tapGestureRecognizer: UITapGestureRecognizer){
        self.courseContentLabel.textColor = UIColor(red: 0.79, green: 0.026, blue: 0.47, alpha: 1.0)
        self.overviewLabel.textColor = UIColor(red: 0.68, green: 0.69, blue: 0.69, alpha: 1.0)
        webView.isHidden = true
        chaptersTableView.isHidden = false
        chaptersTableView.reloadData()
    }
    
    @objc func overviewLabelTapped(tapGestureRecognizer: UITapGestureRecognizer){
        self.overviewLabel.textColor = UIColor(red: 0.79, green: 0.026, blue: 0.47, alpha: 1.0)
        self.courseContentLabel.textColor = UIColor(red: 0.68, green: 0.69, blue: 0.69, alpha: 1.0)
        webView.isHidden = false
        chaptersTableView.isHidden = true
    }
    
    func getStepChaptersDetails(){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        defaultStore?.collection("jurnis").document(self.jurniDocument!.documentID).collection("steps").document(self.stepId!).collection("chapters").getDocuments(){ (querySnapshot, err) in
            for chapterDocument in querySnapshot!.documents {
               // print("\(chapterDocument.documentID) ==> \(chapterDocument.data())")
                    let chapterId = chapterDocument.documentID
                    let chapterImage = chapterDocument.get("poster") as? String ?? ""
                    let chapterName = chapterDocument.get("title") as? String ?? ""
                    let chapterUrl = chapterDocument.get("url") as? String ?? ""
                    let chapterDescription = chapterDocument.get("html") as? String ?? ""
                
                    self.chapterArray.append(JurniChapter(chapterId: chapterId, chapterName: chapterName, chapterImage: chapterImage, chapterUrl: chapterUrl, chapterDescription: chapterDescription,  chapterVideoPlaying: false))
             }
            self.selectVideoRow(row: 0)
           // self.chaptersTableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chapterArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JurniChapterTableViewCell", for: indexPath) as! JurniChapterTableViewCell
        
        cell.chapterNameLabel.text = chapterArray[indexPath.row].chapterName
        if(chapterArray[indexPath.row].chapterVideoPlaying == true){
            cell.chapterImageView.image = UIImage(named: "play")
        }else{
            cell.chapterImageView.image = UIImage(named: "playgrey")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectVideoRow(row: indexPath.row)
    }
    
    func selectVideoRow(row: Int){
        for chapter in chapterArray{
            if(chapter.chapterId == chapterArray[row].chapterId){
                chapter.chapterVideoPlaying = true
            }else{
                chapter.chapterVideoPlaying = false
            }
        }
        self.chaptersTableView.reloadData()
        if(player != nil){
            player.replaceCurrentItem(with: nil)
        }
        playVideo(videoUrl: chapterArray[row].chapterUrl, chapterId: chapterArray[row].chapterId)
        let fontSize = 50
        let fontSetting = "<span style=\"font-size: \(fontSize)\"</span>"
        webView.loadHTMLString(fontSetting + chapterArray[row].chapterDescription, baseURL: nil)
    }
    
    func playVideo(videoUrl: String, chapterId:String){
        let videoUrl = URL(string: videoUrl)
        if(videoUrl != nil){
            player = AVPlayer(url: videoUrl!)
            avpPlayerController.player = player
            avpPlayerController.view.frame.size.height = videoView.frame.size.height
            avpPlayerController.view.frame.size.width = videoView.frame.size.width
            self.videoView.addSubview(avpPlayerController.view)
            player.play()
        }
        getJurniProgress(chapterId: chapterId)
    }
    
    func getJurniProgress(chapterId: String){
        let defaultStore: Firestore?
        defaultStore = Firestore.firestore()
        let userId : String = Auth.auth().currentUser!.uid
        defaultStore?.collection("users").document(userId).collection("jurniProgress").getDocuments(){
            (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for jurniDocument in querySnapshot!.documents {
                        if(self.jurniDocument?.documentID == jurniDocument.documentID){
                            let chaptersData = jurniDocument.data() as [String:Any]
                            for chapter in chaptersData{
                                if(self.stepId == chapter.key){
                                    print("\(chapter.key) ==> \(chapter.value)")
                                    let chapterValue = chapter.value as? [String:Any]
                                    let completed = chapterValue?["completed"] as? Int
                                    let total = chapterValue?["total"] as? Int
                                    var isChapterEmpty = false
                                    if let emptyChapter = chapterValue?["chapters"]  as? [Any] {
                                        isChapterEmpty = true
                                    }
                                    if(chapterValue?["chapters"] != nil && isChapterEmpty == false){
                                        let allChapters = chapterValue?["chapters"] as! [String : Bool]
                                        for singleChapter in allChapters{
                                        if(singleChapter.key == chapterId){
                                            print("value \(singleChapter.value)")
                                            if(singleChapter.value == false){
                                                let updateCompleted : Int = completed!+1
                                                let updatePercent = updateCompleted*100/total!
                                                
                                                let docRef = defaultStore?.collection("users").document(userId).collection("jurniProgress").document(self.jurniDocument!.documentID)
                                                var chapterData = [String:Bool]()
                                                for chapter in allChapters{
                                                    if(chapter.key == singleChapter.key){
                                                        chapterData[chapter.key] = true
                                                    }else{
                                                        chapterData[chapter.key] = chapter.value
                                                    }
                                                }
                                                
                                                let chaptersData: [String:Any] = [
                                                    "chapters": chapterData,
                                                    "completed":updateCompleted,
                                                    "percent":updatePercent,
                                                    "total":total!
                                                ]
                                                let userData: [String:Any] = [self.stepId:chaptersData]
                                                
                                                docRef?.updateData(userData){ err in
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
                        }
                    }
                }
        }
    }
}
