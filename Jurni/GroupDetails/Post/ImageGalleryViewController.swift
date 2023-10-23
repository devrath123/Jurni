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
        
        imageTableView.backgroundColor = UIColor.white
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
        
        if let imageUrl = URL(string: imageURL) {
                    // Use Kingfisher to download the image
            cell.photoImgView.kf.setImage(with: imageUrl, completionHandler: { result in
                        switch result {
                        case .success(let value):
                            let targetWidth: CGFloat = self.view.frame.width - 80
                            let scaleFactor = targetWidth / value.image.size.width
                            let targetHeight = (value.image.size.height - 80) * scaleFactor
                            
                            let resizedImage = value.image.resize(targetSize: CGSize(width: targetWidth, height: targetHeight))
                            
                            cell.photoImgView.image = resizedImage
                        case .failure(let error):
                            print("Error downloading image: \(error)")
                        }
                    })
                }
        
            cell.photoImgView.contentMode = .scaleAspectFill

         
           
            return cell
        
    }

}
