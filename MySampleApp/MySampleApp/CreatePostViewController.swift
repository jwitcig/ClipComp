//
//  CreatePostViewController.swift
//  VidComp
//
//  Created by Developer on 3/30/16.
//  Copyright © 2016 Harb Daddy. All rights reserved.
//

import Photos
import CloudKit
import MobileCoreServices
import UIKit

class CreatePostViewController: CCViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var postButton: UIBarButtonItem!
    
    @IBOutlet weak var groupControl: UISegmentedControl!
    @IBOutlet weak var mediaContainerView: UIView!
    
    var matchup: Matchup!
    
    var groups: (Group, Group)!
    
    var fileToUploadURL: NSURL?
    
    var selectedGroup: Group {
        if groupControl.selectedSegmentIndex == 0 {
            return groups.0
        }
        return groups.1
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        populateGroupControl()
        
        togglePostButton(enabled: false)
    }
    
    func togglePostButton(enabled enabled: Bool) {
        postButton.enabled = enabled
    }
    
    func populateGroupControl() {
        if let groups = groups, let groupControl = groupControl {
            groupControl.removeAllSegments()
            
            groupControl.insertSegmentWithTitle(groups.0.name, atIndex: 0, animated: true)
            groupControl.insertSegmentWithTitle(groups.1.name, atIndex: 1, animated: true)
            
            groupControl.selectedSegmentIndex = 0
        }
    }
    
    func presentImportMediaController() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        
        picker.sourceType = .SavedPhotosAlbum
        picker.mediaTypes.append(kUTTypeMovie as String)
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func presentCaptureMediaController() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        
        picker.sourceType = .Camera
        picker.mediaTypes.append(kUTTypeMovie as String)
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        print("media selected")

        mediaContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        var newImage: UIImage?
        
        if let possibleImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            newImage = possibleImage
        } else if let possibleImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            newImage = possibleImage
        }
        
        let nsDocumentDirectory = NSSearchPathDirectory.DocumentDirectory
        let nsUserDomainMask = NSSearchPathDomainMask.UserDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        
        guard let dirPath = paths[safe: 0] else {
            print("no directories found for save")
            return
        }
        
        // selected media: IMAGE
        if let image = newImage {
            
            let writeURL = NSURL(fileURLWithPath: dirPath).URLByAppendingPathComponent("\(NSUUID().UUIDString).png")
            
            UIImagePNGRepresentation(image)?.writeToURL(writeURL, atomically: true)
            
            fileToUploadURL = writeURL
            
            // display preview
            let imageView = UIImageView(image: image)
            imageView.frame = mediaContainerView.bounds
            imageView.contentMode = .ScaleAspectFill
            mediaContainerView.addSubview(imageView)
            
            togglePostButton(enabled: true)
        }
        
        let mediaType = info[UIImagePickerControllerMediaType] as? String
        
        // selected media: VIDEO
        if mediaType == kUTTypeMovie as String,
            let videoURL = info[UIImagePickerControllerMediaURL] as? NSURL {
            
            let directoryURL = NSURL(fileURLWithPath: dirPath)
            
            let writeURL = directoryURL.URLByAppendingPathComponent("\(NSUUID().UUIDString).mp4")
            
            let videoData = NSData(contentsOfURL: videoURL)
            
            videoData?.writeToURL(writeURL, atomically: true)
            
            fileToUploadURL = writeURL

            // display preview
            let videoView = VideoView(videoURL: videoURL, target: nil, selector: nil)
            videoView.frame = mediaContainerView.bounds
            
            videoView.play()
            mediaContainerView.addSubview(videoView)
            
            togglePostButton(enabled: true)
        }
        
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func postPressed(sender: AnyObject) {
        if let assetURL = fileToUploadURL {
            uploadAsset(fileURL: assetURL)
        } else {
            print("no url for saved file")
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func uploadAsset(fileURL fileURL: NSURL) {
        
        func deleteLocalFileCopy(fileURL fileURL: NSURL) {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(fileURL)
            } catch let error as NSError {
                print("error deleting file: \(error)")
            }
        }
        
        let currentUserReference = CKReference(recordID: currentUserRecordID!, action: .None)
        
        let post = Post(creator: currentUserReference)
        post.group = CKReference(record: selectedGroup.cloudRecord, action: .DeleteSelf)
        post.matchup = CKReference(record: matchup.cloudRecord, action: .DeleteSelf)
        post.asset = CKAsset(fileURL: fileURL)
        
        publicCloudDatabase.saveRecord(post.cloudRecord) { record, error in
            guard error == nil else {
                print("unsuccessful: \(error!)")
                return
            }
            print("successful")
            
            deleteLocalFileCopy(fileURL: fileURL)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func importPressed(sender: AnyObject) {
        presentImportMediaController()
    }
    
    @IBAction func capturePressed(sender: AnyObject) {
        presentCaptureMediaController()
    }
    
    @IBAction func cancelPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}
