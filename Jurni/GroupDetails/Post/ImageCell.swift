//
//  ImageCell.swift
//  Jurni
//
//  Created by Yatharth Singh on 10/10/23.
//

import UIKit

class ImageCell: UITableViewCell, UIScrollViewDelegate {

    @IBOutlet weak var scrollView:UIScrollView!
    @IBOutlet weak var photoImgView: UIImageView!
    var pinchGesture: UIPinchGestureRecognizer!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
               self.scrollView.minimumZoomScale = 0.5
               self.scrollView.maximumZoomScale = 3.5
               self.scrollView.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
             return self.photoImgView
         }
    
}
