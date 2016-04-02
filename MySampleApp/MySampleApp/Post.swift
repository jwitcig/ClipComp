//
//  Post.swift
//  VidComp
//
//  Created by Developer on 3/28/16.
//  Copyright © 2016 Harb Daddy. All rights reserved.
//

import CloudKit
import UIKit

protocol RecordType {
    var cloudRecord: CKRecord { get set }
}

class Post: RecordType {
    
    var asset: CKAsset? {
        get { return cloudRecord["asset"] as? CKAsset }
        set { cloudRecord["asset"] = newValue }
    }
    
    var group: CKReference {
        get { return cloudRecord["group"] as! CKReference }
        set { cloudRecord["group"] = newValue }
    }
    
    var matchup: CKReference {
        get { return cloudRecord["matchup"] as! CKReference }
        set { cloudRecord["matchup"] = newValue }
    }
    
    var creatorReference: CKReference {
        get { return cloudRecord["creator"] as! CKReference }
        set { cloudRecord["creator"] = newValue }
    }
    
    var cloudRecord = CKRecord(recordType: "Post")
    
    init(record: CKRecord) {
        self.cloudRecord = record
    }
    
    init(creator: CKReference) {
        self.creatorReference = creator
    }
    
}