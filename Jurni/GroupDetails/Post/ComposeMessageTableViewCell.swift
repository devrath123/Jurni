//
//  ComposeMessageTableViewCell.swift
//  Jurni
//
//  Created by Milo Kvarfordt on 9/8/23.
//

import FirebaseFirestore
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import UIKit
import AVKit

class ComposeMessageTableViewCell: UITableViewCell, UITextViewDelegate {
    // MARK: - Outlets
    @IBOutlet weak var userIconImageView: UIImageView!
    @IBOutlet weak var addPhotoButton: UIButton!
    @IBOutlet weak var addVideoButton: UIButton!
    @IBOutlet weak var publishMessageButton: UIButton!
    @IBOutlet weak var selectedPhotoImageView: UIImageView!
    @IBOutlet weak var selectedVideoView: UIView!
    @IBOutlet weak var cancelPhotoButton: UIButton!
    @IBOutlet weak var backgroundBorderView: UIView!
    @IBOutlet weak var imageCountLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    
    // MARK: - Properties
    var selectImageHandler: (() -> Void)?
    var selectedImage: UIImage?
    var selectVideoHandler: (() -> Void)?
    var player: AVPlayer!
    var avpPlayerController = AVPlayerViewController()
    var removeMedia: (() -> Void)?
    var previewImagesHandler: (() -> Void)?
    var activityView: UIActivityIndicatorView?
    var selectedImages: [UIImage] = []
    var groupDetails: Group?
    var videoURL: URL?
    
    let MESSAGE_TYPE_TEXT = "text"
    let MESSAGE_TYPE_IMAGE = "image"
    let MESSAGE_TYPE_VIDEO = "video"
    
    @objc func imageCountLabelTapped() {
        previewImagesHandler?()
    }
    // MARK: - Lifecycles
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundBorderView.layer.cornerRadius = 50
        backgroundBorderView.layer.borderWidth = 1.0
        backgroundBorderView.layer.borderColor = UIColor.opaqueSeparator.cgColor
        
        selectedPhotoImageView.isHidden = true
        selectedVideoView.isHidden = true
        cancelPhotoButton.isHidden = true
        messageTextView.delegate = self
        let previewImages = UITapGestureRecognizer(target: self, action: #selector(imageCountLabelTapped))
        imageCountLabel.isUserInteractionEnabled = true
        imageCountLabel.addGestureRecognizer(previewImages)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    // MARK: - Functions
    func uploadVideoToFirebaseStorage(videoURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
            let storageRef = Storage.storage().reference()
            
            // Create a unique name for the video (e.g., using a timestamp)
            let videoName = String("\(randomString(length: 5)).mp4")
            
            // Reference to the Firebase Storage bucket with the video's name
            let videoRef = storageRef.child("video/\(videoName)")
            
            // Upload the video file
            DispatchQueue.main.async {
                let uploadTask = videoRef.putFile(from: videoURL, metadata: nil) { (metadata, error) in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        // Once the upload is complete, get the download URL
                        videoRef.downloadURL { (url, error) in
                            if let error = error {
                                completion(.failure(error))
                            } else if let downloadURL = url {
                                completion(.success(downloadURL))
                            }
                        }
                    }
                }
            }
        }
    
    func randomString(length: Int) -> String {
            let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
            return String((0..<length).map{ _ in letters.randomElement()! })
        }
    
    func uploadImagesToFirebaseStorage(images: [UIImage], completion: @escaping (Result<[String], Error>) -> Void) {
                var uploadURLs: [String] = []
                var uploadErrors: [Error] = []
                
                let dispatchGroup = DispatchGroup()
                
                for image in images {
                        dispatchGroup.enter()
                        
                        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
                                uploadErrors.append(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"]))
                                dispatchGroup.leave()
                                continue
                            }
                        
                        // Create a unique name for the image (e.g., using a timestamp)
                        let imageName = String("\(randomString(length: 5)).png")
                        
                        // Reference to the Firebase Storage bucket
                        let storageRef = Storage.storage().reference().child("grouppost/\(imageName)")
                        
                        // Upload the image data to Firebase Storage
                        let uploadTask = storageRef.putData(imageData, metadata: nil) { (metadata, error) in
                                if let error = error {
                                        uploadErrors.append(error)
                                        dispatchGroup.leave()
                                    } else {
                                            // Once the upload is complete, get the download URL
                                            storageRef.downloadURL { (url, error) in
                                                    if let error = error {
                                                            uploadErrors.append(error)
                                                        } else if let downloadURL = url {
                                                                uploadURLs.append(downloadURL.absoluteString)
                                                            }
                                                    dispatchGroup.leave()
                                                }
                                        }
                            }
                        
                        // You can also observe the upload progress if needed
            //            uploadTask.observe(.progress) { snapshot in
            //                let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            //                print("Upload progress: \(percentComplete)%")
            //            }
                    }
                
                
               
                
                dispatchGroup.notify(queue: .main) {
                        if !uploadErrors.isEmpty {
                                completion(.failure(uploadErrors.first!))
                            } else {
                                    completion(.success(uploadURLs))
                                }
                    }
            }
    func postDataToFirebase(dataType: String, content: [String: Any]){
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM d, yyyy 'at' h:mm:ss a 'UTC'ZZZZZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 5 * 3600 + 30 * 60) // UTC+5:30
            let date = Date() // Replace this with your specific Date object
            let timestamp = dateFormatter.string(from: date)
            let randomId = String("\(randomString(length: 20))")
            let groupId = self.groupDetails?.groupId ?? ""
            let from = Auth.auth().currentUser!.uid
            let ownerString = Firestore.firestore().collection("users").document(from)
            let ownerReference = Firestore.firestore().document(ownerString.path)
            
            let reactions = [
                        "THUMB_UP": 0,
                        "LOVE": 0,
                        "SAD": 0,
                        "ANGRY": 0,
                        "SURPRISE": 0,
                        "LAUGH": 0
                    ]
            
            
            let docRef = Firestore.firestore().collection("groups").document(groupId).collection("posts").document(randomId)
            docRef.setData([
                "from": ownerReference,
                "type": dataType,
                "meta": content,
                "reactions": reactions,
                "timestamp": timestamp
            ]){ err in
                if let err = err {
                    print("Error updating document: \(err)")

                } else {
                    print("successfully uploded ")

                }

            }


            
            
           
        }
    
    func playVideo(videoUrl: URL){
        player = AVPlayer(url: videoUrl)
        avpPlayerController.player = player
        avpPlayerController.view.frame.size.height = selectedVideoView.frame.size.height
        avpPlayerController.view.frame.size.width = selectedVideoView.frame.size.width
        selectedVideoView.insertSubview(avpPlayerController.view, at: 0)
        //     player.play()
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if messageTextView.textColor == UIColor.placeholderText {
            messageTextView.text = nil
            messageTextView.textColor = UIColor.black// Set the text color to the desired color when editing starts.
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if messageTextView.text.isEmpty {
            messageTextView.text = "Write something here..."
            messageTextView.textColor = UIColor.placeholderText
        }
    }
    // MARK: - Actions
    
    @IBAction func addPhotoButtonTapped(_ sender: Any) {
        selectImageHandler?()
        
        addVideoButton.isHidden = true
        cancelPhotoButton.isHidden = false
    }
    @IBAction func addVideoButtonTapped(_ sender: Any) {
        selectVideoHandler?()
        
        addPhotoButton.isHidden = true
        cancelPhotoButton.isHidden = false
    }
    @IBAction func cancelPhotoButtonTapped(_ sender: Any) {
        selectedImage = nil
        removeMedia?()
        addVideoButton.isHidden = false
        cancelPhotoButton.isHidden = true
        addPhotoButton.isHidden = false
    }
    @IBAction func publishMessageButtonTapped(_ sender: Any) {
        if (self.selectedImages.count > 0)
                    {
        //
                        var urls = [String]()
                        self.uploadImagesToFirebaseStorage(images: self.selectedImages) { result in
                            switch result {
                            case .success(let downloadURLs):
                                print("Images uploaded successfully. Download URLs: \(downloadURLs)")
                               urls = downloadURLs
                                self.postDataToFirebase(dataType: self.MESSAGE_TYPE_IMAGE, content: ["content" : "test uploading 15 images", "url": urls])
                            case .failure(let error):
                                print("Error uploading images: \(error.localizedDescription)")
                            }
                        }
                    }
                    else if (self.videoURL != nil){
               
                        self.uploadVideoToFirebaseStorage(videoURL: self.videoURL!) { result in
                        switch result {
                        case .success(let downloadURL):
                            print("Video uploaded successfully. Download URL: \(downloadURL)")

                            self.postDataToFirebase(dataType: self.MESSAGE_TYPE_VIDEO, content: ["content" : "test uploading video", "url": downloadURL])
                            // Do something with the downloadURL, like storing it in your database or playing the video.
                        case .failure(let error):
                            print("Error uploading video: \(error.localizedDescription)")
                        }
                    }
                    }
                    else{
                        self.postDataToFirebase(dataType: self.MESSAGE_TYPE_TEXT, content: ["content" : "this post only conatins text"])
                    }
    }
}// End of Class
extension ComposeMessageTableViewCell: ResetCellDelegate {
    func resetCells() {
        imageCountLabel.isHidden = true
        addPhotoButton.isHidden = false
        addVideoButton.isHidden = false
    }
}
