//
//  LoginViewController.swift
//  ClipComp
//
//  Created by Developer on 4/5/16.
//  Copyright © 2016 Amazon. All rights reserved.
//

import UIKit

import AWSDynamoDB
import AWSMobileHubHelper
import FBSDKLoginKit

import SwiftTools

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate, FBSDKGraphRequestConnectionDelegate {
    
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginButton.addTarget(self, action: #selector(LoginViewController.handleFacebookLogin), forControlEvents: .TouchUpInside)

//        loginButton.readPermissions = ["public_profile", "email"];
        loginButton.setTitle("", forState: .Normal)
        
        let facebookButtonImage: UIImage? = UIImage(named: "FacebookButton")
        if let facebookButtonImage = facebookButtonImage{
            loginButton.setImage(facebookButtonImage, forState: .Normal)
        }
        
        loginButton.center = self.view.center
        self.view.addSubview(loginButton)
    }
    
    override func viewDidAppear(animated: Bool) {
        if loggedIn {
            performSegueWithIdentifier("LoginSuccess", sender: self)
        }
    }
    
    func handleFacebookLogin() {
        
        let credentialsProvider = AWSServiceManager.defaultServiceManager().defaultServiceConfiguration.credentialsProvider as! AWSCognitoCredentialsProvider
        
//        credentialsProvider.clearKeychain()
        
        let facebookSignInProvider = AWSFacebookSignInProvider.sharedInstance()
        
        let identityManager = AWSIdentityManager.defaultIdentityManager()
//        identityManager.resumeSessionWithCompletionHandler { (result, error) in
        
        if identityManager.loggedIn {
            for _ in 1...100 {
                print("resuming session")
            }
            
            var logins = credentialsProvider.logins ?? [NSObject: AnyObject]()
            logins[AWSIdentityProviderFacebook] = FBSDKAccessToken.currentAccessToken().tokenString
            
            credentialsProvider.logins = logins
            

            
            identityManager.resumeSessionWithCompletionHandler({ (result, error) in
                self.createData()
            })
            
            return
        }
        for _ in 1...100 {
            print("logging in")
        }
        identityManager.loginWithSignInProvider(facebookSignInProvider) { (result, error) in
            self.createData()
        }
        
    }
    
    func createData() {
        guard let identityID = AWSIdentityManager.defaultIdentityManager().identityId else {
            return
        }
        
        let dbMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        dbMapper.load(User.self, hashKey: identityID, rangeKey: nil).continueWithBlock({ (task) -> AnyObject? in
            
            let user = task.result as? User
            
            for _ in 1...100 {
                print(user?.identityID)
            }
            
            if user?.identityID == nil {
                
                // returns userID and name by default
                let facebookRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id"])
                
                let facebookConnection = FBSDKGraphRequestConnection()
                facebookConnection.addRequest(facebookRequest, completionHandler: { (connection, result, error) in
                    
                    let resultDict = result as? NSDictionary
                    
                    for _ in 1...100 {
                        print("facebook replied")
                    }
                    
                    guard let id = resultDict?["id"] as? String else {
                        return
                    }
                    print(identityID)
                    print(id)
                    let newUser = User()
                    newUser.identityID = identityID
                    newUser.facebookID = id
                    dbMapper.save(newUser).continueWithBlock({ (task) -> AnyObject? in
                        return nil
                    })
                    
                })
                runOnMainThread {
                    facebookConnection.start()
                }
            }
            
            return nil
        })
    }
    
    var loggedIn = false
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {

        loggedIn = true
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {

    }
    
}
