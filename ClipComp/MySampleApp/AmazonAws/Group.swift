//
//  Group.swift
//  VidComp
//
//  Created by Developer on 3/30/16.
//  Copyright © 2016 Harb Daddy. All rights reserved.
//

import CloudKit
import UIKit

class Group: RecordType {
  
    var name: String {
        get { return cloudRecord["name"] as? String ?? "" }
        set { cloudRecord["name"] = newValue }
    }
    
    var creatorReference: CKReference {
        get { return cloudRecord["creator"] as! CKReference }
        set { cloudRecord["creator"] = newValue }
    }
    
    var cloudRecord = CKRecord(recordType: "Group")
    
    init(record: CKRecord) {
        self.cloudRecord = record
    }
    
    init(name: String, creator: CKReference) {
        self.name = name
        self.creatorReference = creator
    }
        
}