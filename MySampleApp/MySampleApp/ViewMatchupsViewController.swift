//
//  ViewMatchupsViewController.swift
//  VidComp
//
//  Created by Developer on 3/30/16.
//  Copyright © 2016 Harb Daddy. All rights reserved.
//

import CloudKit
import UIKit

import SwiftTools

class ViewMatchupsViewController: CCViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableview: UITableView!
    
    var group: Group!
    
    var matchups = [Matchup]()
    
    var selectedMatchup: Matchup? {
        if let index = tableview.indexPathForSelectedRow?.row {
            return matchups[safe: index]
        }
        return nil
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let publicCloudDatabase = CKContainer.defaultContainer().publicCloudDatabase
        
        let groupReference = CKReference(record: group.cloudRecord, action: .None)
        let matchupQuery = CKQuery(recordType: "Matchup", predicate: NSPredicate(key: "groups", comparator: .Contains, value: groupReference))
        
        publicCloudDatabase.performQuery(matchupQuery, inZoneWithID: nil) { records, error in
            
            guard let cloudRecords = records where error == nil else {
                print("error: \(error)")
                return
            }
            
            self.matchups = cloudRecords.map { Matchup(record: $0) }
            
            runOnMainThread {
                self.tableview.reloadData()
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchups.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let _ = matchups[safe: indexPath.row] else {
            fatalError("group array out of bounds")
        }
        
        let cell = UITableViewCell()
        cell.textLabel?.text = "matchup"
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("MatchupViewController", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let matchupViewController = segue.destinationViewController as? VoteViewController {
            
            if let matchup = selectedMatchup {
                matchupViewController.matchup = matchup
            }
            
        }
    }
    
}
