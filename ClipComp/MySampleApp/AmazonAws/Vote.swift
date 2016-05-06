//
//  Vote.swift
//  VidComp
//
//  Created by Developer on 3/28/16.
//  Copyright © 2016 Harb Daddy. All rights reserved.
//

import CloudKit
import UIKit

class Vote: RecordType {
  
    var creator: CKReference {
        get { return cloudRecord["creator"] as! CKReference }
        set { cloudRecord["creator"] = newValue }
    }
    
    var matchup: CKReference {
        get { return cloudRecord["matchup"] as! CKReference }
        set { cloudRecord["matchup"] = newValue }
    }
    
    func setMatchup(matchup: Matchup) {
        self.matchup = CKReference(record: matchup.cloudRecord, action: .DeleteSelf)
    }
    
    var groupVotedFor: CKReference {
        get { return cloudRecord["groupVotedFor"] as! CKReference }
        set { cloudRecord["groupVotedFor"] = newValue }
    }
    
    var cloudRecord = CKRecord(recordType: "Vote")
    
    init(record: CKRecord) {
        self.cloudRecord = record
    }
    
    init(creator: CKReference, matchup: Matchup, group: Group) {
        self.creator = creator
        self.matchup = CKReference(record: matchup.cloudRecord, action: .None)
        self.groupVotedFor = CKReference(record: group.cloudRecord, action: .None)
        
        forceUpdateValues()
    }
    
    func forceUpdateValues() {
        let creator = self.creator
        let matchup = self.matchup
        let groupVotedFor = self.groupVotedFor
        
        self.creator = creator
        self.matchup = matchup
        self.groupVotedFor = groupVotedFor
    }
    
}