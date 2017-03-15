//
//  FilterSelectionViewController.swift
//  Snapcat
//
//  Created by Luke Brody on 3/13/17.
//

import Foundation
import UIKit

/**
 This class's job is to maintain a UITableView of face selections that mirrors CatFace.faces
 
 It's part of the 'Controller' layer of our app.
 */

class FilterSelectionViewController : UITableViewController {
    
    /**
     Sections are different categories of rows. There's only one section in our table.
    */
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return CatFace.faces.count //There are going to be the same number of cells as faces.
        default:
            fatalError() //There's only one section, so we shouldn't ever have to handle anything except index 0.
        }
    }
    
    /**
     The table view calls this method when it needs a new cell for some IndexPath.
     
     An IndexPath has a two components,
        - section
        - row
     that correspond to the cell's location in the table view.
    */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            
            let result = UITableViewCell(style: .default, reuseIdentifier: nil)
            result.textLabel!.text = CatFace.faces[indexPath.row].name
            
            return result
            
            
        default:
            fatalError()
        }
    }
    
    /**
     We only need to keep one FaceViewController around, since it's expensive (lots of work for the phone) to load and there's only one on screen at any time.
     We can lazily load it from the storyboard.
    */
    lazy var faceViewController : FaceViewController = self.storyboard!.instantiateViewController(withIdentifier: "FaceViewController") as! FaceViewController
    
    /**
     The table view calls this method when the user selects a row.
     We give the faceViewController that selected face, then push it to the front of the navigation controller.
     A nagivation controller is simply an object that manages a stack of views. Every iOS interface where you go forward and back uses one of these.
     */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        faceViewController.catFace = CatFace.faces[indexPath.row]
        
        navigationController!.pushViewController(faceViewController, animated: true)
    }
    
}
