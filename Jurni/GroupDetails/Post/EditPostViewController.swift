//
//  EditPostViewController.swift
//  Jurni
//
//  Created by Yatharth Singh on 11/10/23.
//

import UIKit
import Kingfisher
import FirebaseFirestore
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage
import PhotosUI

class EditPostViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate,UIImagePickerControllerDelegate, PHPickerViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
   
    var groupDetails: Group?
    var postDetails: Post?
    var postImages: [Any] = []
    var videoURL: URL?
    var activityView: UIActivityIndicatorView?
    let MESSAGE_TYPE_TEXT = "text"
    let MESSAGE_TYPE_IMAGE = "image"
    let MESSAGE_TYPE_VIDEO = "video"
    weak var backDelegate: BackDelegate?

    @IBOutlet weak var photoTableView: UITableView!
    @IBOutlet weak var tableViewHeightConatraint: NSLayoutConstraint!
//    @IBOutlet weak var postTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        photoTableView.rowHeight = UITableView.automaticDimension
        self.photoTableView.estimatedRowHeight = 100
        self.photoTableView.backgroundColor = UIColor.white
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        photoTableView.addGestureRecognizer(tapGesture)
        
        let headerNib = UINib(nibName: "EditPostCell", bundle: nil)
        photoTableView.register(headerNib, forCellReuseIdentifier: "EditPostCell")
        
        let imageNib = UINib(nibName: "EditImageCell", bundle: nil)
        photoTableView.register(imageNib, forCellReuseIdentifier: "EditImageCell")
        
        self.postImages = self.postDetails!.postContent.postImageUrls
        self.setDataInViewController()
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true) // This will close the keyboard and resign first responder status from any text view
    }
    
    override func viewWillLayoutSubviews() {
        DispatchQueue.main.async {
            super.updateViewConstraints()
            self.tableViewHeightConatraint?.constant = self.photoTableView.contentSize.height
            self.view.layoutIfNeeded()
        }
    }
    
    func setDataInViewController(){
//        self.postTextView.text = self.postDetails!.postContent.postText
        
        
//        let height = photoTableView.collectionViewLayout.collectionViewContentSize.height
//        collectionViewHeightConatraint.constant = height
//        self.photoTableView.reloadData()
    }
    
    func postDataToFirebase(dataType: String, content: [String: Any]){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, yyyy 'at' h:mm:ss a 'UTC'ZZZZZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 5 * 3600 + 30 * 60) // UTC+5:30
        let date = Date() // Replace this with your specific Date object
        let da = dateFormatter.string(from: date)
        let timestamp = dateFormatter.date(from: da)
        
        let randomId = String("\(randomString(length: 20))")
        let groupId = self.groupDetails?.groupId ?? ""
        let from = Auth.auth().currentUser!.uid
        let ownerString = Firestore.firestore().collection("users").document(from)
        let ownerReference = Firestore.firestore().document(ownerString.path)
        
        let reactions = [
            "THUMB_UP": postDetails!.postReaction.thumbsUp,
            "LOVE": postDetails!.postReaction.love,
            "SAD": postDetails!.postReaction.sad,
            "ANGRY": postDetails!.postReaction.angry,
            "SURPRISE": postDetails!.postReaction.surprise,
            "LAUGH": postDetails!.postReaction.laugh ]
        let docRef = Firestore.firestore().collection("groups").document(self.groupDetails?.groupId ?? "").collection("posts").document((self.postDetails?.id)!)
        docRef.updateData([
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
                DispatchQueue.main.async {
                    self.hideActivityIndicator()
                    self.backDelegate?.didComeBack()
                    self.dismiss(animated: true, completion: nil)

                }
            }
        }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if results.count == 0 {
            // User canceled out of picker
            print("User canceled")
//            postImages = []
            //  delegate?.resetCells()
        }
        else{
            for result in results {
                if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                        if let image = object as? UIImage {
                            self.postImages.append(image)
                            DispatchQueue.main.async {
                                self.photoTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                            }
                        }
                    }
                }
                
            }
            
            DispatchQueue.main.async {
                self.photoTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
//                self.groupPostTableView.reloadSections(IndexSet(integer: 1), with: .automatic)
                self.photoTableView.reloadData()
            }
            
            
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            self.videoURL = videoURL
            DispatchQueue.main.async {
                let cell: ComposeMessageTableViewCell = self.photoTableView.cellForRow(at: IndexPath(row: 0, section: 0))! as! ComposeMessageTableViewCell
                cell.imgView.isHidden = true
                //            self.groupPostTableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                self.photoTableView.reloadData()
            }
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    @IBAction func bckBtnTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func setImage(url: String, imageView: UIImageView){
        if(url != ""){
            let imageUrl = URL(string:  url)
            imageView.kf.setImage(with: imageUrl)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.postImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as? PhotoCollectionViewCell else { return UICollectionViewCell() }
        
        
        cell.deleteImageBtn.addTarget(self, action: #selector(deleteSeletedImage(sender:)), for: .touchUpInside)
        cell.deleteImageBtn.tag = indexPath.item
        cell.layer.backgroundColor = UIColor.white.cgColor
        
        let imageURL = self.postImages[indexPath.item]
        
        if let urlString = imageURL as? String {
            if let imageUrl = URL(string: urlString) {
                // Use Kingfisher to download the image
                cell.avtarImageView.kf.setImage(with: imageUrl, completionHandler: { result in
                    switch result {
                    case .success(let value):
                        // Resize the image to a specific width while maintaining aspect ratio
                        let targetWidth: CGFloat = self.view.frame.width - 40
                        let scaleFactor = targetWidth / value.image.size.width
                        let targetHeight = (value.image.size.height - 40) * scaleFactor
                        
                        let resizedImage = value.image.resize(targetSize: CGSize(width: targetWidth, height: targetHeight))
                        
                        // Set the resized image to your image view
                        cell.avtarImageView.image = resizedImage
                    case .failure(let error):
                        print("Error downloading image: \(error)")
                    }
                })
            }
        }
        else{
            print("no image")
            cell.avtarImageView.image =  self.postImages[indexPath.item] as! UIImage
        }
        
//        cell.avtarImageView.image =  self.postImages[indexPath.item]
        cell.avtarImageView.layer.cornerRadius = 10
        cell.avtarImageView.layer.masksToBounds = true
        cell.avtarImageView.contentMode = .scaleToFill
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.viewWillLayoutSubviews()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func textViewDidChange(_ textView: UITextView) {
       
        photoTableView?.beginUpdates()
        photoTableView?.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "EditPostCell") as? EditPostCell else { return UITableViewCell() }
            
            cell.containerView.backgroundColor = UIColor.white
            cell.backgroundColor = UIColor.white
            cell.layer.backgroundColor = UIColor.white.cgColor
            
            print("Compose: \(indexPath.row)")
            
            cell.photoCollectionView.delegate = self
            cell.photoCollectionView.dataSource = self
            cell.photoCollectionView.backgroundColor = UIColor.white
            
            if let url = self.videoURL {
                cell.videoViewHeightConstraint.constant = CGFloat(140)
                cell.videoView.isHidden = false
                cell.deleteVideoBtnView.isHidden = false
                cell.imgView.isHidden = true
                cell.playVideoImg.isHidden = false
//                playVideo(videoUrl: url , videoView: cell.videoView)
            }
            else{
                cell.videoViewHeightConstraint.constant = CGFloat(40)
                cell.deleteVideoBtnView.isHidden = true
                cell.imgView.isHidden = false
                cell.videoView.isHidden = true
                cell.playVideoImg.isHidden = true
            }
            
            if (self.postImages.count > 0)
            {
                cell.videoBtnView.isHidden = true
            }
            else{
                cell.videoBtnView.isHidden = false
            }
            
            
            
            
            let photoNib = UINib(nibName: "PhotoCollectionViewCell", bundle: nil)
            cell.photoCollectionView.register(photoNib, forCellWithReuseIdentifier: "PhotoCollectionViewCell")
            
            
//            let tapGesture = UITapGestureRecognizer (target: self, action: #selector(imgTap(tapGesture:)))
//            cell.playVideoImg.addGestureRecognizer(tapGesture)
//            cell.playVideoImg.isUserInteractionEnabled = true
            cell.uploadPhotoBtn.addTarget(self, action: #selector(uploadImages(_:)), for: .touchUpInside)
//            cell.uploadVideoBtn.addTarget(self, action: #selector(uploadVideo(_:)), for: .touchUpInside)
//            cell.deleteVideoBtn.addTarget(self, action: #selector(deleteVideo(_:)), for: .touchUpInside)
            cell.publishBtn.addTarget(self, action: #selector(publishPost(_:)), for: .touchUpInside)
            cell.writeSomthingTextView.delegate = self
            cell.writeSomthingTextView.backgroundColor = UIColor.white
            cell.writeSomthingTextView.tintColor = .black
            cell.writeSomthingTextView.text = self.postDetails!.postContent.postText
            cell.containerView.layer.borderColor = UIColor.lightGray.cgColor
            
            
            let height = cell.photoCollectionView.collectionViewLayout.collectionViewContentSize.height
            cell.collectionHeightConstraint.constant = height
            cell.collectionHeightConstraint.constant = CGFloat(self.postImages.count * 140)
            
            cell.photoCollectionView.reloadData()
            photoTableView.reloadSections(IndexSet(integer: 0), with: .automatic)
            
            
            return cell

        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Return a specific height for a certain row if needed
        return UITableView.automaticDimension
    }
    
    @objc func uploadImages(_ sender: UIButton?){
        
        var position: CGPoint = sender!.convert(.zero, to: self.photoTableView)
        let indexPath = self.photoTableView.indexPathForRow(at: position)
        let cell: EditPostCell = photoTableView.cellForRow(at: indexPath!)! as! EditPostCell
        
        cell.videoBtnView.isHidden = true
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0  // 0 means no limit
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
        
    }
    
    @objc func deleteSeletedImage( sender: UIButton){
        
        var position: CGPoint = sender.convert(.zero, to: self.photoTableView)
        let indexPath = self.photoTableView.indexPathForRow(at: position)
        postImages.remove(at: indexPath!.row)
        photoTableView.reloadData()
    
    }
    
    @objc func publishPost(_ sender: UIButton){
        
        var position: CGPoint = sender.convert(.zero, to: self.photoTableView)
        let indexPath = self.photoTableView.indexPathForRow(at: position)
        let cell: EditPostCell = photoTableView.cellForRow(at: indexPath!)! as! EditPostCell
        
        let unwrappedValue = cell.writeSomthingTextView.text
        
        if (self.postImages.count > 0)
            
        {
            
            self.showActivityIndicator()
//            var urls = [String]()
            let imageArray = postImages.compactMap { $0 as? UIImage }
            if imageArray.count > 0 {
                self.uploadImagesToFirebaseStorage(images: imageArray) { result in
                    switch result {
                    case .success(let downloadURLs):
                        print("Images uploaded successfully. Download URLs: \(downloadURLs)")
                        self.postImages = self.postImages.filter { element in
                            return !(element is UIImage)
                        }
                        self.postImages += downloadURLs
                        self.postDataToFirebase(dataType: self.MESSAGE_TYPE_IMAGE, content: ["content" : unwrappedValue ?? "", "url": self.postImages])
                    case .failure(let error):
                        print("Error uploading images: \(error.localizedDescription)")
                    }
                }}
            else{
                
                self.postDataToFirebase(dataType: self.MESSAGE_TYPE_IMAGE, content: ["content" : unwrappedValue ?? "", "url": self.postImages])
            }
            
        }
        else if (self.videoURL != nil)
        {
            
            self.showActivityIndicator()
            var urls = [String]()
            
            self.uploadVideoToFirebaseStorage(videoURL: self.videoURL!) { result in
                switch result {
                case .success(let downloadURLs):
                    print("Images uploaded successfully. Download URLs: \(downloadURLs)")
                    urls.append(downloadURLs.absoluteString)
                    self.postDataToFirebase(dataType: self.MESSAGE_TYPE_VIDEO, content: ["content" : unwrappedValue, "url": urls])
                case .failure(let error):
                    print("Error uploading video: \(error.localizedDescription)")
                    self.hideActivityIndicator()
                }
            }
            
            
        }
        else{
            self.showActivityIndicator()
            self.postDataToFirebase(dataType: self.MESSAGE_TYPE_TEXT, content: ["content" : unwrappedValue])
        }
        cell.writeSomthingTextView.text = ""
//        cell.writeSomthingTextView.placeholder = "Write something here..."
        
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
        }
        
        dispatchGroup.notify(queue: .main) {
            if !uploadErrors.isEmpty {
                completion(.failure(uploadErrors.first!))
            } else {
                completion(.success(uploadURLs))
            }
        }
    }
    
    
    
    func uploadVideoToFirebaseStorage(videoURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        
        
        let videoName = String("\(randomString(length: 5)).mp4")
        do {
            let data = try Data(contentsOf: videoURL)
            
            let storageRef = Storage.storage().reference().child("videos").child(videoName)
            if let uploadData = data as Data? {
                let metaData = StorageMetadata()
                metaData.contentType = "video/mp4"
                storageRef.putData(data, metadata: metaData) { metadata, error in
                    if let error = error {
                        // Handle error
                        completion(.failure(error))
                    } else {
                        // Once the upload is complete, get the download URL
                        storageRef.downloadURL { (url, error) in
                            if let error = error {
                                // Handle error
                                completion(.failure(error))
                            } else if let downloadURL = url {
                                // Video uploaded successfully, return the download URL
                                completion(.success(downloadURL))
                            }
                        }
                    }
                }
            }
        }catch let error {
            print(error.localizedDescription)
        }
        
    }
    
    func showActivityIndicator() {
        activityView = UIActivityIndicatorView(style: .large)
        activityView?.center = self.view.center
        activityView?.color = .black
        self.view.addSubview(activityView!)
        activityView?.startAnimating()
    }
    
    func hideActivityIndicator(){
        if (activityView != nil){
            activityView?.stopAnimating()
        }
    }
    
   

}

extension UIImage {
    func resize(targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { (context) in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
extension EditPostCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write something here..."
            textView.textColor = UIColor.lightGray
        }
    }
}
