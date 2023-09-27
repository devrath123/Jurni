//
//  LoadedImagesTableViewController.swift
//  Jurni
//
//  Created by Milo Kvarfordt on 9/25/23.
//

import UIKit

class LoadedImagesTableViewController: UITableViewController {
    
    // MARK: - Properties
    var selectedImages: [UIImage]?
        
    override func viewDidLoad() {
        super.viewDidLoad()

        print(selectedImages!.count)
        tableView.register(UINib(nibName: "ImagePreviewTableViewCell", bundle: nil), forCellReuseIdentifier: "previewImage")
    }
    
    

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        200
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return selectedImages?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "previewImage", for: indexPath) as! ImagePreviewTableViewCell
        
        if let image = self.selectedImages?[indexPath.row] {
            cell.previewImageImageView.image = image
            cell.previewImageImageView.contentMode = .scaleAspectFill
            cell.previewImageImageView.clipsToBounds = true
        }
        cell.removeImageHandler = { 
        // code for removing image and then reloading tableview
            self.selectedImages?.remove(at: indexPath.row)
            self.tableView.reloadData()
        }
        return cell
    }
 

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
