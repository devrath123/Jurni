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
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
                scrollView.delegate = self
                scrollView.minimumZoomScale = 1.0
                scrollView.maximumZoomScale = 10.0//maximum zoom scale you want
                scrollView.zoomScale = 1.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return photoImgView
    }
    
}
