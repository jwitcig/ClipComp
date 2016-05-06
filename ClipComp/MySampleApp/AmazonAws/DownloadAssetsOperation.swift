//
//  DownloadAssetsOperation.swift
//  ClipComp
//
//  Created by Developer on 4/4/16.
//  Copyright © 2016 Amazon. All rights reserved.
//

import UIKit

import AWSS3

class DownloadAssetsOperation: NSOperation {
    
    override var asynchronous: Bool { return false }
    
    var _executing = false
    var _finished = false
    override var executing : Bool {
        get { return _executing }
        set {
            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }
    override var finished : Bool {
        get { return _finished }
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }
    
    var posts: [Post]
        
    init(posts: [Post]) {
        self.posts = posts
        
        super.init()
    }
    
    override func start() {
        if cancelled { self.completed(); return }

        executing = true
        
        main()
    }
    
    override func main() {
        if cancelled { self.completed(); return }
        
        let fetchCompletionOperation = NSBlockOperation {
            self.completed()
        }
        
        var downloadOperations = [DownloadAssetOperation]()
        for post in posts {
            
            let downloadAssetOperation = DownloadAssetOperation(post: post)
            
            fetchCompletionOperation.addDependency(downloadAssetOperation)
            
            downloadOperations.append(downloadAssetOperation)
        }
        
        NSOperationQueue().addOperations(downloadOperations + [fetchCompletionOperation], waitUntilFinished: false)
    }
    
    func completed() {
        self.executing = false
        self.finished = true
    }
    
}

class DownloadAssetOperation: NSOperation {
    
    override var asynchronous: Bool { return false }
    
    var _executing = false
    var _finished = false
    override var executing : Bool {
        get { return _executing }
        set {
            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }
    override var finished : Bool {
        get { return _finished }
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }
    
    var post: Post
    
    init(post: Post) {
        self.post = post
        
        super.init()
    }
    
    override func start() {
        if cancelled { self.completed(); return }
        
        executing = true
        
        main()
    }
    
    override func main() {
        if cancelled { self.completed(); return }
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let destinationPath = NSURL(fileURLWithPath: documentsPath).URLByAppendingPathComponent(NSUUID().UUIDString, isDirectory: false)
        
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        
        let downloadRequest = AWSS3TransferManagerDownloadRequest()
        downloadRequest.bucket = "clipcomp-contentdelivery-mobilehub-1964794544"
        downloadRequest.key = post.cloudRecord["assetS3Name"] as? String
        downloadRequest.downloadingFileURL = destinationPath
        
        transferManager.download(downloadRequest).continueWithBlock({ (task) -> AnyObject? in
            guard task.error == nil else { return task }
            
            guard task.result != nil else { return task }
            
            self.post.assetURL = downloadRequest.downloadingFileURL
            self.post.asset = NSData(contentsOfURL: downloadRequest.downloadingFileURL)
            
            self.completed()
            
            return nil
        })
        
    }
    
    func completed() {
        self.executing = false
        self.finished = true
    }
    
}

