//
//  Matchup.swift
//  VidComp
//
//  Created by Developer on 3/30/16.
//  Copyright © 2016 Harb Daddy. All rights reserved.
//

import CloudKit
import UIKit

class Matchup: RecordType {
    
    var cloudRecord = CKRecord(recordType: "Matchup")
    
    var groups: [CKReference] {
        get { return cloudRecord["groups"] as? [CKReference] ?? [] }
        set { cloudRecord["groups"] = newValue }
    }
    
    init(record: CKRecord) {
        self.cloudRecord = record
    }
    
    init(creator: CKReference) {

    }
    
}