//
//  ViewController.swift
//  VidComp
//
//  Created by Intesar Ahmad on 3/15/16.
//  Copyright © 2016 Harb Daddy. All rights reserved.
//

import AVFoundation
import CloudKit
import UIKit

import AWSS3
import GoogleMobileAds

import SwiftTools

enum Side {
    case Left, Right
}

class VoteViewController: CCViewController {

    var matchup: Matchup!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var scrollViewContainerView: UIView!
    
    @IBOutlet weak var voteLeftGroupCountLabel: UILabel!
    @IBOutlet weak var voteLeftGroupPercentageLabel: UILabel!
    
    @IBOutlet weak var voteRightGroupCountLabel: UILabel!
    @IBOutlet weak var voteRightGroupPercentageLabel: UILabel!
    
    @IBOutlet weak var voteLeftGroupButton: UIButton!
    @IBOutlet weak var voteRightGroupButton: UIButton!
    
    @IBOutlet weak var newPostButton: UIBarButtonItem!
    
    var previousVote: Side?
    var voteAlreadyCast: Bool {
        return previousVote != nil
    }
    
    var groupViews = [UIView]()
    var leftGroupView: UIView { return groupViews[0] }
    var rightGroupView: UIView { return groupViews[1] }
    
    var currentGroupSide: Side {
        get {
            let visibleRect = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)

            if visibleRect.intersects(leftGroupView.frame) {
                return .Left
            }
            
            if visibleRect.intersects(rightGroupView.frame) {
                return .Right
            }
            return .Left
        }
    }
    
    var groups: (Group, Group)?
    var leftGroup: Group? { return groups?.0 }
    var rightGroup: Group? { return groups?.1 }
    
    var leftGroupData: GroupData!
    var rightGroupData: GroupData!
    
    var leftGroupMediaGenerator: IndexingGenerator<[MediaItem]>!
    var rightGroupMediaGenerator: IndexingGenerator<[MediaItem]>!
    
    var cloudContainer: CKContainer { return CKContainer.defaultContainer() }
    
    var existingVotes = [Vote]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupInterface()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        fetchGroupsAndMatchup()
        
        fetchCurrentUserID()
    }
    
    func fetchCurrentUserID() {
        CKContainer.defaultContainer().fetchUserRecordIDWithCompletionHandler { userRecordID, error in
            
            guard error == nil else { print("error: \(error)"); return }
            
            currentUserRecordID = userRecordID
        }
    }
    
    var initialFetchStarted = false
    
    func fetchGroupsAndMatchup() {
        guard !initialFetchStarted else { return }
        initialFetchStarted = true
        
        print("starting groups fetch")
        
        // fetch groups for matchup
        let groupsQuery = CKQuery(recordType: "Group", predicate: NSPredicate(key: "recordID", comparator: .In, value: matchup.groups))
        
        let groupsQueryOperation = CKQueryOperation(query: groupsQuery)
        groupsQueryOperation.database = publicCloudDatabase
        
        var groupsList = [Group]()
        groupsQueryOperation.recordFetchedBlock = {
            groupsList.append(Group(record: $0))
        }
        
        groupsQueryOperation.queryCompletionBlock = { cursor, error in
            guard error == nil else { print(error!); return }
            
            self.groups = (groupsList[0], groupsList[1])
            
            runOnMainThread {
                self.titleLabel.text = "\(self.groups!.0.name) | \(self.groups!.1.name)"
                
                self.enableNewPostButton()
            }
        }
        
        // fetch posts for matchup
        let matchupReference = CKReference(record: matchup.cloudRecord, action: .None)
        
        let postsQuery = CKQuery(recordType: "Post", predicate: NSPredicate(key: "matchup", comparator: .Equals, value: matchupReference))
        
        let postsQueryOperation = CKQueryOperation(query: postsQuery)
        postsQueryOperation.addDependency(groupsQueryOperation)
        postsQueryOperation.database = publicCloudDatabase
        
        var posts = [Post]()
        postsQueryOperation.recordFetchedBlock = {
            posts.append(Post(record: $0))
        }
        postsQueryOperation.queryCompletionBlock = { cursor, error in
            guard error == nil else { print("error: \(error)"); return }
            
            guard let leftGroup = self.leftGroup, let rightGroup = self.rightGroup else {
                return
            }
            
            let leftGroupPosts = posts.filter {
                return $0.group.recordID == leftGroup.cloudRecord.recordID
            }.sort {
                if let leftDate = $0.0.cloudRecord.creationDate, let rightDate = $0.1.cloudRecord.creationDate {
                    return leftDate.isBefore(date: rightDate)
                }
                return true
            }
            
            let rightGroupPosts = posts.filter {
                return $0.group.recordID == rightGroup.cloudRecord.recordID
            }.sort {
                if let leftDate = $0.0.cloudRecord.creationDate, let rightDate = $0.1.cloudRecord.creationDate {
                    return leftDate.isBefore(date: rightDate)
                }
                return true
            }
            
            var downloadAssetsOperation = DownloadAssetsOperation(posts: posts)
            
            var downloadAssetCompletionOperation = NSBlockOperation {
                let leftGroupMediaViews = self.compileMediaItems(posts: leftGroupPosts)
                let rightGroupMediaViews = self.compileMediaItems(posts: rightGroupPosts)
                
                self.leftGroupData = GroupData(group: leftGroup, mediaViews: leftGroupMediaViews)
                self.rightGroupData = GroupData(group: rightGroup, mediaViews: rightGroupMediaViews)
                
                self.leftGroupMediaGenerator = self.leftGroupData.mediaViews.generate()
                self.rightGroupMediaGenerator = self.rightGroupData.mediaViews.generate()
                
                runOnMainThread {
                    self.loadMediaItem(group: .Left)?.start()
                }
            }
            
            downloadAssetCompletionOperation.addDependency(downloadAssetsOperation)
            
            NSOperationQueue().addOperations([downloadAssetsOperation, downloadAssetCompletionOperation], waitUntilFinished: false)
        }
        
        // fetch votes for matchup
        let votesQueryOperation = CKQueryOperation()
        votesQueryOperation.database = publicCloudDatabase
        
        let joiningOperation = NSBlockOperation {
            let votesPredicate = NSPredicate(key: "matchup", comparator: .Equals, value: matchupReference)
            
            votesQueryOperation.query = CKQuery(recordType: "Vote", predicate: votesPredicate)
        }
        
        joiningOperation.addDependency(postsQueryOperation)
        votesQueryOperation.addDependency(joiningOperation)
        
        votesQueryOperation.recordFetchedBlock = {
            self.existingVotes.append(Vote(record: $0))
        }
        votesQueryOperation.queryCompletionBlock = { cursor, error in
            guard error == nil else { print("error: \(error)"); return }
            
            guard let leftGroup = self.leftGroup, let rightGroup = self.rightGroup else {
                return
            }
            
            var totalVoteCount: Int { return self.existingVotes.count }
            
            var leftGroupRecordID: CKRecordID{
                return CKReference(record: leftGroup.cloudRecord, action: .None).recordID
            }
            var rightGroupRecordID: CKRecordID {
                return CKReference(record: rightGroup.cloudRecord, action: .None).recordID
            }
            
            var leftGroupVotes = self.existingVotes.filter { $0.groupVotedFor.recordID == leftGroupRecordID }
            var rightGroupVotes = self.existingVotes.filter { $0.groupVotedFor.recordID == rightGroupRecordID }

            let prevVoteForLeft = leftGroupVotes.map { $0.cloudRecord.recordID.recordName }.contains(currentUserRecordID!.recordName)
            
            let prevVoteForRight = rightGroupVotes.map { $0.cloudRecord.recordID.recordName }.contains(currentUserRecordID!.recordName)
            
            if prevVoteForLeft {
                self.previousVote = .Left
            } else if prevVoteForRight {
                self.previousVote = .Right
            }
            
            let leftGroupVoteCount = leftGroupVotes.count
            let rightGroupVoteCount = rightGroupVotes.count

            let leftGroupVotePercentage = Int((Float(leftGroupVoteCount) / Float(totalVoteCount)) * 100)
            let rightGroupVotePercentage = Int((Float(rightGroupVoteCount) / Float(totalVoteCount)) * 100)

            runOnMainThread {
                let _ = VoteResults(voteCount: leftGroupVoteCount, votePercentage: leftGroupVotePercentage, voteCountLabel: self.voteLeftGroupCountLabel, votePercentageLabel: self.voteLeftGroupPercentageLabel)

                let _ = VoteResults(voteCount: rightGroupVoteCount, votePercentage: rightGroupVotePercentage, voteCountLabel: self.voteRightGroupCountLabel, votePercentageLabel: self.voteRightGroupPercentageLabel)
            }
        }
        
        NSOperationQueue().addOperations([groupsQueryOperation, postsQueryOperation, joiningOperation, votesQueryOperation], waitUntilFinished: false)
    }
    
    func didFinishPlayingAllMediaItems() {
        toggleVoting(enabled: true)
    }
    
    func loadMediaItem(group group: Side) -> MediaItem? {
        var previousGroupView: UIView?
        
        defer {
            UIView.animateWithDuration(0.4, animations: {

                previousGroupView?.subviews.forEach { $0.alpha = 0 }
            
                }, completion: { completed in
                    previousGroupView?.subviews.forEach { $0.removeFromSuperview() }
            })
        }
        
        switch group {
        case .Left:
            if let mediaView = self.leftGroupMediaGenerator.next() {
                mediaView.view.frame = self.leftGroupView.bounds
                
                previousGroupView = self.rightGroupView
                
                self.leftGroupView.addSubview(mediaView.view)
                
                return mediaView
            }
            
        case .Right:
            if let mediaView = self.rightGroupMediaGenerator.next() {
                mediaView.view.frame = self.rightGroupView.bounds
                
                previousGroupView = self.leftGroupView
                
                self.rightGroupView.addSubview(mediaView.view)
                
                return mediaView
            }
        }
        
        return nil
    }
    
    func toggleVoting(enabled enabled: Bool) {
        [voteLeftGroupButton, voteRightGroupButton].forEach { $0.enabled = enabled }
    }
    
    func setupInterface() {
        
        func initializeAdBanner() -> GADBannerView {
            let bannerView = GADBannerView.init(adSize: kGADAdSizeSmartBannerPortrait)
            
            bannerView.adUnitID = "ca-app-pub-0507224597790106/8574500128"
            bannerView.rootViewController = self
            bannerView.loadRequest(GADRequest())
            
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            
            return bannerView
        }
        
        let adBanner = initializeAdBanner()
        self.view.addSubview(adBanner)
        
        NSLayoutConstraint.activateConstraints([
            adBanner.bottomAnchor.constraintEqualToAnchor(self.view.bottomAnchor),
            
            adBanner.leadingAnchor.constraintEqualToAnchor(self.view.leadingAnchor),
            
            adBanner.trailingAnchor.constraintEqualToAnchor(self.view.trailingAnchor)
        ])
        
        newPostButton.enabled = false
        
        toggleVoting(enabled: false)
        
        groupViews = [createGroupView(), createGroupView()]
        
        self.view.addSubview(groupViews[0])
        self.view.addSubview(groupViews[1])
        
        var constraints = [NSLayoutConstraint]()
        
        let imageViewSpacing = 40 as CGFloat
        
        groupViews.enumerate().forEach { index, imageView in
            
            if index == 0 {
                // first imageView
                constraints.append(imageView.leadingAnchor.constraintEqualToAnchor(scrollViewContainerView.leadingAnchor, constant: imageViewSpacing / 2))
            }
            
            if index == groupViews.count - 1 {
                // last imageView
                constraints.append(scrollViewContainerView.trailingAnchor.constraintEqualToAnchor(imageView.trailingAnchor, constant: imageViewSpacing / 2))
            }
            
            if let previousImageView = groupViews[safe: index - 1] {
                constraints.append(imageView.leadingAnchor.constraintEqualToAnchor(previousImageView.trailingAnchor, constant: imageViewSpacing))
            }
            
            constraints.appendContentsOf([
                imageView.topAnchor.constraintEqualToAnchor(scrollViewContainerView.topAnchor),
                imageView.bottomAnchor.constraintEqualToAnchor(scrollViewContainerView.bottomAnchor),
                imageView.heightAnchor.constraintEqualToAnchor(scrollViewContainerView.superview!.heightAnchor),
                imageView.widthAnchor.constraintEqualToAnchor(scrollViewContainerView.superview!.widthAnchor, constant: -imageViewSpacing)
            ])
            
            scrollViewContainerView.addSubview(imageView)
        }
        NSLayoutConstraint.activateConstraints(constraints)
    }
    
    func enableNewPostButton() {
        self.newPostButton.enabled = true
    }
    
    func compileMediaItems(posts posts: [Post]) -> [MediaItem] {
        return posts.map {
            let assetData = $0.asset!
            
            // if data is an image, return ImageItem
            if let image = UIImage(data: assetData) {
                return ImageItem(image: image, target: self, selector: #selector(VoteViewController.mediaItemFinishedPlaying))
            }
            
            // if data is not an image, create a VideoItem for it
            var videoURL = $0.assetURL!
            
            let videoData = NSData(contentsOfURL: videoURL)
            
            let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let destinationPath = NSURL(fileURLWithPath: documentsPath).URLByAppendingPathComponent("video.mov", isDirectory: false)
            
            NSFileManager.defaultManager().createFileAtPath(destinationPath.path!, contents: videoData, attributes: nil)
            
            videoURL = destinationPath
            
            let videoView = VideoItem(videoURL: videoURL, target: self, selector: #selector(VoteViewController.mediaItemFinishedPlaying))
            
            return videoView
        }
    }
    
    func mediaItemFinishedPlaying() {
        var scrollToPoint: CGPoint!
        
        var newMediaItem: MediaItem?
        
        if currentGroupSide == .Left {
            scrollToPoint = CGPoint(x: scrollView.frame.width, y: 0)
            
            newMediaItem = self.loadMediaItem(group: .Right)
        } else {
            scrollToPoint = CGPoint(x: 0, y: 0)
            
            newMediaItem = self.loadMediaItem(group: .Left)
        }
        
        if let newMediaItem = newMediaItem {
            UIView.animateWithDuration(0.4, animations: {
                
                self.scrollView.contentOffset = scrollToPoint
                
                }, completion: { animated in
                    
                    runOnMainThread {
                        newMediaItem.start()
                    }
            })
        } else {
            didFinishPlayingAllMediaItems()
        }
    }
    
    @IBAction func voteLeftGroupPressed(button: UIButton) {
        if !voteAlreadyCast {
            castVoteOnPost(groupSide: .Left)
        }
    }
    
    @IBAction func voteRightGroupPressed(button: UIButton) {
        if !voteAlreadyCast {
            castVoteOnPost(groupSide: .Right)
        }
    }
    
    func castVoteOnPost(groupSide groupSide: Side) {
        guard let userRecordID = currentUserRecordID else {
            print("could not determine current user")
            return
        }
        let currentUserReference = CKReference(recordID: userRecordID, action: .None)
        
        guard let leftGroup = self.leftGroup, let rightGroup = self.rightGroup else {
            return
        }
        
        let groupVotedFor = groupSide == .Left ? leftGroup : rightGroup
        
        let vote = Vote(creator: currentUserReference, matchup: matchup, group: groupVotedFor)
        
        publicCloudDatabase.saveRecord(vote.cloudRecord) { record, error in
            guard error == nil else { print("error saving post: \(error)"); return }
            
            print("save")
        }
    }
    
    func createGroupView() -> UIView {
        let imageView = UIView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let createPostViewController = segue.destinationViewController as? CreatePostViewController {
            
            createPostViewController.matchup = matchup
            createPostViewController.groups = groups
        }
    }
    
}

class GroupData {
    
    var group: Group
    
    var mediaViews = [MediaItem]()
    
    init(group: Group, mediaViews: [MediaItem]) {
        self.group = group
        self.mediaViews = mediaViews
    }
    
}

class VoteResults {
    
    var voteCount: Int {
        didSet {
            voteCountLabel.text = "\(voteCount)"
        }
    }
    var votePercentage: Int {
        didSet {
            votePercentageLabel.text = "\(votePercentage) %"
        }
    }
    
    var voteCountLabel: UILabel
    var votePercentageLabel: UILabel
    
    init(voteCount: Int, votePercentage: Int, voteCountLabel: UILabel, votePercentageLabel: UILabel) {
        self.voteCountLabel = voteCountLabel
        self.votePercentageLabel = votePercentageLabel

        self.voteCount = voteCount
        self.votePercentage = votePercentage
        
        forceValuesUpdate()
    }
    
    private func forceValuesUpdate() {
        let forcedVoteCount = voteCount
        let forcedVotePercentage = votePercentage

        self.voteCount = forcedVoteCount
        self.votePercentage = forcedVotePercentage
    }
    
}

protocol MediaItem {
    
    var view: UIView { get }
    
    var target: AnyObject? { get set }
    
    var selector: Selector? { get set }
    
    func start()
    
    func pause()

}

class ImageItem: MediaItem {
    
    var view: UIView {
        return imageView as UIView
    }
    var imageView = UIImageView()
    
    let timerDuration = 2 as Double
    
    var target: AnyObject?
    var selector: Selector?
    
    var timer: NSTimer?
    
    init(image: UIImage, target: AnyObject?, selector: Selector?) {
        self.target = target
        self.selector = selector
        
        self.imageView.image = image
        self.imageView.contentMode = .ScaleAspectFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func start() {
        if let target = target, let selector = selector {
            timer = NSTimer.scheduledTimerWithTimeInterval(timerDuration, target: target, selector: selector, userInfo: self, repeats: false)
        }
    }
    
    func pause() {
        timer?.invalidate()
    }
    
    @objc func itemDidFinishPlaying(sender: AnyObject) {
        if let selector = selector {
            target?.performSelector(selector, withObject: self)
        }
    }
    
}

class VideoItem: MediaItem {
    
    var view: UIView {
        return videoView as UIView
    }
    var videoView: VideoView
    
    var target: AnyObject?
    var selector: Selector?
    
    init(videoURL: NSURL, target: AnyObject?, selector: Selector?) {
        self.target = target
        self.selector = selector
        
        self.videoView = VideoView(videoURL: videoURL, target: target, selector: selector)
    }
    
    func start() {
        videoView.play()
    }
    
    func pause() {
        videoView.pause()
    }

}

class VideoView: UIView {
    
    var target: AnyObject?
    var selector: Selector?
    
    var player: AVPlayer
    var playerLayer: AVPlayerLayer
    
    init(videoURL: NSURL, target: AnyObject?, selector: Selector?) {
        let playerItem = AVPlayerItem(URL: videoURL)
        
        self.player = AVPlayer(playerItem: playerItem)
        self.playerLayer = AVPlayerLayer(player: player)
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        self.target = target
        self.selector = selector
        
        super.init(frame: CGRect.zero)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VideoView.itemDidFinishPlaying(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object:playerItem)
        
        self.layer.addSublayer(playerLayer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        playerLayer.frame = self.bounds
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    @objc func itemDidFinishPlaying(notification: NSNotification) {
        if let selector = selector {
            target?.performSelector(selector, withObject: self)
        }
    }
    
}


