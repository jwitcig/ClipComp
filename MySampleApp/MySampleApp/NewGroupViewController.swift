//
//  NewGroupViewController.swift
//  VidComp
//
//  Created by Developer on 3/30/16.
//  Copyright © 2016 Harb Daddy. All rights reserved.
//

import CloudKit
import UIKit

class NewGroupViewController: CCViewController {

    @IBOutlet weak var groupNameField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func createPressed(button: UIButton) {
        guard let userRecordID = currentUserRecordID,
            let groupName = groupNameField.text else {
            print("could not determine current user")
            return
        }
        let currentUserReference = CKReference(recordID: userRecordID, action: .None)
        
        let newGroup = Group(name: groupName, creator: currentUserReference)
        CKContainer.defaultContainer().publicCloudDatabase.saveRecord(newGroup.cloudRecord) { record, error in
            
            guard error == nil else {
                print("unsuccessful")
                return
            }
            print("successful")
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func backPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
