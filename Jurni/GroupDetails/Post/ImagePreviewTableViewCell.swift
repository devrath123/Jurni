//
//  ImagePreviewTableViewCell.swift
//  Jurni
//
//  Created by Milo Kvarfordt on 9/25/23.
//

import UIKit

class ImagePreviewTableViewCell: UITableViewCell {
    // MARK: - Outlets
    
    @IBOutlet weak var previewImageImageView: UIImageView!
    @IBOutlet weak var dismissPictureButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    // MARK: - Properties
    var removeImageHandler: (() -> Void)?
    
    // MARK: - Actions
    @IBAction func dismissPictureButtonTapped(_ sender: Any) {
        removeImageHandler?()
    }
}
