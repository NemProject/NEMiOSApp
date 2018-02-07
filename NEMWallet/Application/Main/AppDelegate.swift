//
//  AppDelegate.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2017 NEM
//

import UIKit
import AlamofireNetworkActivityIndicator

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Application Properties
    
    var window: UIWindow?
    
    // MARK: - Application Lifecycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        configureDependencies()
        
        if SettingsManager.sharedInstance.setupIsCompleted() {
            
            TimeManager.sharedInstance.synchronizeTime()            
            NotificationManager.sharedInstance.registerForNotifications()
            presentAuthenticationViewController(onLaunch: true)
            
        } else {
            
            presentSetupViewController()
        }
        
        return true
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
        TimeManager.sharedInstance.synchronizeTime()
        presentAuthenticationViewController()
        NotificationManager.sharedInstance.clearApplicationIconBadge()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        dismissModalViewsIfNecessary()
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationManager.sharedInstance.notifyAboutNewTransactions(withCompletionHandler: completionHandler)
    }
    
    // MARK: - Application Helper Methods
    
    /// Configures all necessary application dependencies.
    private func configureDependencies() {
        NetworkActivityIndicatorManager.shared.isEnabled = true
    }
    
    /**
        Presents the authentication view controller. The user then has to authenticate before being
        able to continue using the application. 
        The authentication view controller behaves differently depending on whether it is presented 
        on launch of the application or on entering foreground. On default it will be presented for 
        the enter foreground mode - customize the 'onLaunch' parameter accordingly.
     
        - Parameter onLaunch: Bool, telling the method if the authentication view controller is being presented on application launch or not.
     */
    private func presentAuthenticationViewController(onLaunch: Bool = false) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let authenticationViewController = mainStoryboard.instantiateViewController(withIdentifier: "AuthenticationViewController") as! AuthenticationViewController
        
        if SettingsManager.sharedInstance.setupIsCompleted() && appDelegate.window != nil {
            if onLaunch {
                
                appDelegate.window!.rootViewController = authenticationViewController
                appDelegate.window!.makeKeyAndVisible()
                
            } else {
                
                if let topViewController = UIApplication.topViewController() {
                    if !(topViewController is AuthenticationViewController) {
                        
                        topViewController.present(authenticationViewController, animated: false, completion: nil)
                    }
                }
            }
        }
    }
    
    /**
        Presents the setup view controller, which will be shown on first launch of the application 
        and lets the user setup the application, choose an application password, etc.
     */
    private func presentSetupViewController() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let authenticationPasswordCreationViewController = mainStoryboard.instantiateViewController(withIdentifier: "AuthenticationPasswordCreationViewController") as! AuthenticationPasswordCreationViewController
        
        if appDelegate.window != nil {
            appDelegate.window!.rootViewController = authenticationPasswordCreationViewController
        }
    }
    
    /**
        Dismisses all modals views where it is necessary. 
        For example, alert controllers need to get dismissed when entering the background to present 
        the authentication view controller correctly when entering the foreground.
     */
    private func dismissModalViewsIfNecessary() {
        
        if let topViewController = UIApplication.topViewController() {
            if topViewController is UIAlertController {
                
                topViewController.dismiss(animated: false, completion: nil)
            }
        }
    }
}
