//
//  ViewGroupsViewController.swift
//  VidComp
//
//  Created by Developer on 3/30/16.
//  Copyright © 2016 Harb Daddy. All rights reserved.
//

import CloudKit
import UIKit

import AWSDynamoDB
import AWSMobileHubHelper
import GoogleMobileAds

import SwiftTools

import FBSDKLoginKit

class User: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    static func dynamoDBTableName() -> String! { return "User" }
    
    static func hashKeyAttribute() -> String! { return "identityID" }
    
    var facebookID: String?
    
    var identityID: String!

}
class Vote: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    static func dynamoDBTableName() -> String! {
        return "Vote"
    }
    
    static func hashKeyAttribute() -> String! {
        return "id"
    }
    
    var id: String = NSUUID().UUIDString
    
}
class Group: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    static func dynamoDBTableName() -> String! {
        return "Group"
    }
    
    static func hashKeyAttribute() -> String! {
        return "name"
    }
    
    var name: String = NSUUID().UUIDString
    
    var stuff = ""
}


class ViewGroupsViewController: CCViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableview: UITableView!
        
    var groups = [Group]()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
//        let credentialsProvider = AWSServiceManager.defaultServiceManager().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
    
//        credentialsProvider.logins = [AWSIdentityProviderFacebook: FBSDKAccessToken.currentAccessToken().tokenString]
        
       
//            
//            let cred = AWSServiceManager.defaultServiceManager().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
//            
//            print("nito id: \(AWSIdentityManager.defaultIdentityManager().identityId)")
//
//            
//            let dbMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
//            
//            let expression = AWSDynamoDBScanExpression()
            
            //                dbMapper.scan(Group.self, expression: expression).continueWithBlock({ (
            //                    task) -> AnyObject? in
            //
            //
            //                    for _ in 1...100 {
            //                        print("adsf")
            //                    }
            //
            //
            //
            //
            //                    let output = task.result! as! AWSDynamoDBPaginatedOutput
            //
            //                    for group in output.items as! [Group] {
            //                        print("\(group.name) \(group.stuff)")
            //                    }
            //                
            //                    return nil
            //                })

            
        
        
        
//        credentialsProvider.getIdentityId().continueWithBlock { (task: AWSTask!) -> AnyObject! in
//            
//            if (task.error != nil) {
//                print("Error: \(task.error?.localizedDescription)")
//            } else {
//                // the task result will contain the identity id
//                let cognitoID = task.result as! String
//               
//                print("nito id: \(cognitoID)")
//                let dbMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
//                
//                let expression = AWSDynamoDBScanExpression()
        
//                dbMapper.scan(Group.self, expression: expression).continueWithBlock({ (
//                    task) -> AnyObject? in
//                    
//                    
//                    for _ in 1...100 {
//                        print("adsf")
//                    }
//                    
//                    
//                    
//                    
//                    let output = task.result! as! AWSDynamoDBPaginatedOutput
//                    
//                    for group in output.items as! [Group] {
//                        print("\(group.name) \(group.stuff)")
//                    }
//                
//                    return nil
//                })
                
                
//            }
        
            let dbMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
            
            let newGroup = Group()
            newGroup.stuff = "schlong guys"
            
//            dbMapper.save(newGroup).continueWithBlock { (task) -> AnyObject? in
//                guard task.error == nil else {
//                    print(task.error!)
//                    return task
//                }
//                
//                guard let _ = task.result else {
//                    return task
//                }
//                print("")
//                print("WINNER")
//                
//                return nil
//            }
//
//            return nil
//        }
        
        
        let bannerView: GADBannerView = GADBannerView.init(adSize: kGADAdSizeSmartBannerPortrait)
        
        bannerView.adUnitID = "ca-app-pub-0507224597790106/8574500128"
        bannerView.rootViewController = self
        bannerView.loadRequest(GADRequest())
        self.view.addSubview(bannerView)
        
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activateConstraints([
            bannerView.bottomAnchor.constraintEqualToAnchor(self.view.bottomAnchor),
            
            bannerView.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor),
            
            bannerView.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor)
        ])
        
//        let groupQuery = CKQuery(recordType: "Group")
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
        cell.textLabel?.text = group.name
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("ViewMatchupsViewController", sender: nil)
    }
    
    var selectedGroup: Group? {
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
