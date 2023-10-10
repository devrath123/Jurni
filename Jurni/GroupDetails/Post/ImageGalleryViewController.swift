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
            setImage(url: imageURL, imageView: cell.photoImgView)
            cell.photoImgView.contentMode = .scaleToFill
         
           
            return cell
        
    }
   
}
