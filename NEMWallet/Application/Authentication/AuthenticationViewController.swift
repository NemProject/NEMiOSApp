//
//  AuthenticationViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2017 NEM
//

import UIKit
import LocalAuthentication

/**
    The authentication view controller that gets presented on application launch
    and when entering foreground in order to keep intruders out. The user has to enter
    the valid application password or sign in by Touch ID to continue using the app.
 */
final class AuthenticationViewController: UIViewController {
    
    // MARK: - View Controller Outlets
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var passwordHeadingLabel: UILabel!
    @IBOutlet weak var passwordContainerView: UIView!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmationButton: UIButton!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViewControllerAppearance()
        passwordTextField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        checkTouchIDIfActivated()
    }
    
    /// Needed for a smooth appearance of the alert view controller.
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    /// Needed for a smooth appearance of the alert view controller.
    override var canResignFirstResponder: Bool {
        return true
    }
    
    // MARK: - View Controller Outlet Actions
    
    /// Gets called when the user presses the confirmation button.
    @IBAction func confirm(_ sender: UIButton) {
        checkApplicationPassword()
    }
    
    /// Gets called when the user taps on the return button on the keyboard after entering the password.
    @IBAction func didEndOnExit(_ sender: UITextField) {
        checkApplicationPassword()
    }
    
    @IBAction func editingDidBegin(_ sender: UITextField) {
        passwordTextField.textColor = UIColor.black
    }
    
    // MARK: - View Controller Helper Methods
    
    /**
        Handles the whole authentication process via password.
        Checks if the user entered application password is correct and responds accordingly by either
        redirecting the user to the application or by showing an error message.
     */
    private func checkApplicationPassword() {
        
        guard passwordTextField.text != nil else { return }
        
        let salt = SettingsManager.sharedInstance.authenticationSalt()
        let saltData = NSData.fromHexString(salt!)
        let encryptedPassword = SettingsManager.sharedInstance.applicationPassword()
        
        let passwordData: NSData? = try! HashManager.generateAesKeyForString(passwordTextField.text!, salt: saltData, roundCount: 2000)!
        
        if passwordData?.toHexString() == encryptedPassword {
            authenticationSuccessful()
        } else {
            passwordTextField.textColor = UIColor.red
        }
    }
    
    /**
        Handles the whole authentication process via Touch ID if the user has activated Touch ID authentication.
        Checks if the user provided fingerprint is valid and responds accordingly by either redirecting the user 
        to the application or by showing an error message.
     */
    private func checkTouchIDIfActivated() {
        
        if SettingsManager.sharedInstance.touchIDAuthenticationIsActivated() {
        
            let localAuthenticationContext = LAContext()
            var error: NSError?
            
            if (localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)) {
                localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: NSLocalizedString("Authorize by fingerprint", comment: "")) {
                    [weak self] (success: Bool, _) -> Void in
                    
                    DispatchQueue.main.async {
                        
                        if success {
                            
                            self?.authenticationSuccessful()
                            
                        } else {
                            
                            if let error = error {
                                if error.code == LAError.touchIDNotEnrolled.rawValue {
                                    
                                    let alertController = UIAlertController(title: "Touch ID isn't configured", message: "You first have to configure Touch ID in the device settings", preferredStyle: .alert)
                                    
                                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                    
                                    self?.present(alertController, animated: true, completion: nil)
                                    
                                } else {
                                    
                                    print("user provided touch id wasn't correct: \(error), \(error.userInfo), \(error.code)")
                                }
                                
                            } else {
                                
                                print("no authentication error code provided by local authentication despite failure")
                            }
                        }
                    }
                }
                
            } else {
                
                print("touch id isn't available: \(String(describing: error)), \(error!.userInfo)")
            }
        }
    }
    
    /// Makes the transition to the application after successful authentication.
    private func authenticationSuccessful() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if let rootViewController = appDelegate.window?.rootViewController {
            if (rootViewController == self) {
                
                self.performSegue(withIdentifier: "showRootNavigationController", sender: nil)
                
            } else {
                
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    /// Updates the appearance (coloring, titles) of the view controller.
    private func updateViewControllerAppearance() {
        
        view.layoutIfNeeded()
        
        passwordHeadingLabel.text = "ENTET_PASSWORD".localized()
        passwordTextField.placeholder = "PASSWORD_PLACEHOLDER".localized()
        confirmationButton.setTitle("CONFIRM".localized(), for: UIControlState())
        
        containerView.layer.cornerRadius = 5
        containerView.clipsToBounds = true
    }
}
