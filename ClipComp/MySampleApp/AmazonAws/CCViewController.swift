//
//  CCViewController.swift
//  ClipComp
//
//  Created by Developer on 4/1/16.
//  Copyright © 2016 JwitApps. All rights reserved.
//

import CloudKit
import UIKit

class CCViewController: UIViewController {

    var publicCloudDatabase: CKDatabase {
        return CKContainer.defaultContainer().publicCloudDatabase
    }
    
}
