//
//  ImageGalleryViewController.swift
//  Jurni
//
//  Created by Esther on 10/5/23.
//

import UIKit
import Kingfisher

class ImageGalleryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var imageTableView: UITableView!
    var postImageUrls: [String] = []
    var zoomedIndexPath: IndexPath?
    
    @IBAction func bckBtnTap(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        imageTableView.rowHeight = UITableView.automaticDimension
//        self.imageTableView.estimatedRowHeight = 200
        
        let headerNib = UINib(nibName: "ImageCell", bundle: nil)
        imageTableView.register(headerNib, forCellReuseIdentifier: "ImageCell")
        
    }
    
    func setImage(url: String, imageView: UIImageView){
        if(url != ""){
            let imageUrl = URL(string:  url)
            imageView.kf.setImage(with: imageUrl)
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
            return postImageUrls.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
    
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ImageCell") as? ImageCell else { return UITableViewCell() }
            
            cell.backgroundColor = UIColor.white
            let imageURL = postImageUrls[indexPath.item]
        
//        let imageURL = self.postImages[indexPath.item]
        
        if let imageUrl = URL(string: imageURL) {
                    // Use Kingfisher to download the image
            cell.photoImgView.kf.setImage(with: imageUrl, completionHandler: { result in
                        switch result {
                        case .success(let value):
                            // Resize the image to a specific width while maintaining aspect ratio
                            let targetWidth: CGFloat = self.view.frame.width - 80
                            let scaleFactor = targetWidth / value.image.size.width
                            let targetHeight = (value.image.size.height - 80) * scaleFactor
                            
                            let resizedImage = value.image.resize(targetSize: CGSize(width: targetWidth, height: targetHeight))
                            
                            // Set the resized image to your image view
                            cell.photoImgView.image = resizedImage
                        case .failure(let error):
                            print("Error downloading image: \(error)")
                        }
                    })
                }
        
//            setImage(url: imageURL, imageView: cell.photoImgView)
            cell.photoImgView.contentMode = .scaleAspectFill
//            cell.photoImgView.clipsToBounds = true
         
           
            return cell
        
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        
//        self.zoomImage(at: indexPath)
//        }
//    
//    
//    
//    func zoomImage(at indexPath: IndexPath) {
//        guard let cell = imageTableView.cellForRow(at: indexPath) as? ImageCell else {
//            return
//        }
//        
//        zoomedImageView.image = cell.photoImgView.image
//        view.addSubview(zoomedImageView)
//        zoomedImageView.frame = cell.photoImgView.convert(cell.photoImgView.bounds, to: zoomedImageView.superview)
//        cell.photoImgView.isHidden = true
//        
//        UIView.animate(withDuration: 0.3) {
//            self.zoomedImageView.frame = self.imageTableView.bounds
//        }
//        
//        imageTableView.panGestureRecognizer.isEnabled = false
//        zoomedIndexPath = indexPath
//    }
//
//    private var zoomedImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFit
//        imageView.clipsToBounds = true
//        imageView.isUserInteractionEnabled = true
//        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageViewWasTapped))
//        imageView.addGestureRecognizer(tapRecognizer)
//        return imageView
//    }()
//
//    @objc func imageViewWasTapped() {
//        guard let cell = imageTableView.cellForRow(at: zoomedIndexPath!) as? ImageCell else {
//            return
//        }
//        
//        UIView.animate(withDuration: 0.3, animations: {
//            self.zoomedImageView.frame = cell.photoImgView.convert(cell.photoImgView.bounds, to: self.zoomedImageView.superview)
//        }) { finished in
//            self.zoomedImageView.removeFromSuperview()
//            cell.photoImgView.isHidden = false
//            self.zoomedIndexPath = nil
//            self.zoomedImageView.image = nil
//            self.imageTableView.panGestureRecognizer.isEnabled = true
//        }
//    }
   
   
}
