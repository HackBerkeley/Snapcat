//
//  FilterSelectionViewController.swift
//  Snapcat
//
//  Created by Luke Brody on 3/13/17.
//  Copyright © 2017 Luke Brody. All rights reserved.
//

import Foundation
import UIKit

class FilterSelectionViewController : UITableViewController {
    
    /*
     Sections are different categories of rows. There's only one section in our table.
    */
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return CatFilter.filters.count
        default:
            fatalError() //There's only one section, so we shouldn't ever have to handle anything except index 0.
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            
            let result = UITableViewCell(style: .default, reuseIdentifier: nil)
            result.textLabel!.text = CatFilter.filters[indexPath.row].name
            
            return result
            
            
        default:
            fatalError()
        }
    }
    
    lazy var faceViewController : FaceViewController = self.storyboard!.instantiateViewController(withIdentifier: "FaceViewController") as! FaceViewController
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        faceViewController.filter = CatFilter.filters[indexPath.row]
        
        navigationController!.pushViewController(faceViewController, animated: true)
    }
    
}
