//
//  ViewGroupsViewController.swift
//  VidComp
//
//  Created by Developer on 3/30/16.
//  Copyright © 2016 Harb Daddy. All rights reserved.
//

import UIKit

import SwiftTools

class ViewGroupsViewController: CCViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableview: UITableView!
    
    var groups = [String]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
//        publicCloudDatabase.performQuery(groupQuery, inZoneWithID: nil) { records, error in
//            
//            guard let cloudRecords = records where error == nil else {
//                print("error: \(error)")
//                return
//            }
//            
//            self.groups = cloudRecords.map { Group(record: $0) }
//            
//            runOnMainThread {
//                self.tableview.reloadData()
//            }
//        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let group = groups[safe: indexPath.row] else {
            fatalError("group array out of bounds")
        }
        
        let cell = UITableViewCell()
        cell.textLabel?.text = group
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("ViewMatchupsViewController", sender: nil)
    }
    
    var selectedGroup: String? {
        if let index = tableview.indexPathForSelectedRow?.row {
            return groups[index]
        }
        return nil
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
//        if let matchupsViewController = segue.destinationViewController as? ViewMatchupsViewController {
//            
//            if let group = selectedGroup {
//                matchupsViewController.group = group
//            }
//            
//        }
    }
    
}
