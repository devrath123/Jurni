//
//  DummyTableViewController.swift
//  Jurni
//
//  Created by Milo Kvarfordt on 9/12/23.
//

import UIKit
import AVKit
import MobileCoreServices
import PhotosUI

protocol ResetCellDelegate: AnyObject {
    func resetCells()
}
class DummyTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var loadedPhotoImageView: UIImageView!
    
    // MARK: - Properties
    let imagePicker = UIImagePickerController()
    var selectedImages: [UIImage] = []
    var videoURL: URL?
    weak var delegate: ResetCellDelegate?
    // MARK: - Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ComposeMessageTableViewCell", bundle: nil), forCellReuseIdentifier: "composeMessageTableViewCell")
    }
    // MARK: - UIImagePickerControllerDelegate Methods
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        if results.count == 0 {
            // User canceled out of picker
            print("User canceled")
            selectedImages = []
            delegate?.resetCells()
        }
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let image = object as? UIImage {
                    self.selectedImages.append(image)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            self.videoURL = videoURL
            tableView.reloadData()
        }
        
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.resetCells()
        dismiss(animated: true, completion: nil)
    }
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if selectedImages.count > 0 || videoURL != nil {
            return 500
        } else {
            return 300
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "composeMessageTableViewCell", for: indexPath) as! ComposeMessageTableViewCell
        delegate = cell
        if selectedImages.count == 0 {
            cell.selectedPhotoImageView.isHidden = true
            cell.imageCountLabel.isHidden = true
        } else {
            cell.selectedPhotoImageView.isHidden = false
            cell.imageCountLabel.isHidden = false
        }
        if videoURL != nil {
            cell.selectedVideoView.isHidden = false
        } else {
            cell.selectedVideoView.isHidden = true
        }
        if let image = selectedImages.first {
            cell.selectedPhotoImageView.image = image
            cell.imageCountLabel.text = "\(selectedImages.count)"
        }
        cell.removeMedia = {
            self.selectedImages = []
            self.videoURL = nil
            tableView.reloadData()
        }
        cell.selectImageHandler = {
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = 0  // 0 means no limit
            configuration.filter = .images
            
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
        cell.selectVideoHandler = {
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            self.imagePicker.mediaTypes = [kUTTypeMovie as String]
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        if let videoURL = videoURL {
            cell.playVideo(videoUrl: videoURL)
        }
        cell.previewImagesHandler = {
//            DispatchQueue.main.async {
                let destination = LoadedImagesTableViewController()
                destination.selectedImages = self.selectedImages
                self.present(destination, animated: true)
//            }
        }
        return cell
    }
}

