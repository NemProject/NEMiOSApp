//
//  AccountAdditionMenuCreateNewAccountViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit

/**
    The account addition menu create new account view controller that lets
    the user create/generate a completely new account.
 */
class AccountAdditionMenuCreateNewAccountViewController: UIViewController {
    
    // MARK: - View Controller Outlets

    @IBOutlet weak var accountTitleTextField: UITextField!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViewControllerAppearance()
        addKeyboardObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller.
    fileprivate func updateViewControllerAppearance() {
        
        title = "CREATE_NEW_ACCCOUNT".localized()
        createAccountButton.setTitle("CREATE_NEW_ACCCOUNT".localized(), for: UIControlState())
        accountTitleTextField.placeholder = "ACCOUNT_NAME_PLACEHOLDER".localized()
        
        contentView.layer.cornerRadius = 10
        contentView.clipsToBounds = true
    }
    
    /// Adds all needed keyboard observers to the view controller.
    fileprivate func addKeyboardObserver() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(AccountAdditionMenuCreateNewAccountViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AccountAdditionMenuCreateNewAccountViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    /**
        Validates entered information by the user and creates a new
        account accordingly and stores that new account in the database.
        Unwinds to the account list view controller if the account got
        created successfully.
     
        - Parameter title: The title for the new account.
     */
    fileprivate func createAccount(withTitle title: String) {
        
        do {
            let _ = try validate(enteredInformation: title)
            
            AccountManager.sharedInstance.create(account: title, completion: { [unowned self] (result, _) in
                                
                switch result {
                case .success:
                    
                    let alert = UIAlertController(title: "Warning", message: "The account was successfully created. Don't forget to backup your private key! Select your account on the dashboard, go to 'more' -> 'export account'", preferredStyle: UIAlertControllerStyle.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default, handler: { [unowned self] (action) -> Void in
                        self.performSegue(withIdentifier: "unwindToWalletOverviewViewController", sender: nil)
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                    
                case .failure:
                    let accountCreationFailureAlert = UIAlertController(title: "Error", message: "Couldn't create account", preferredStyle: .alert)
                    
                    accountCreationFailureAlert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: nil))
                    
                    self.present(accountCreationFailureAlert, animated: true, completion: nil)
                }
            })
            
        } catch AccountImportValidation.valueMissing {
            
            let accountTitleEmptyAlert = UIAlertController(title: "VALIDATION".localized(), message: "FIELDS_EMPTY_ERROR".localized(), preferredStyle: .alert)
            
            accountTitleEmptyAlert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: nil))
            
            present(accountTitleEmptyAlert, animated: true, completion: nil)
            
        } catch {
            return
        }
    }
    
    /**
        Validates the entered information by the user.
     
        - Parameter title: The title for the new account entered by the user.
     
        - Throws: 
            - AccountImportValidation.ValueMissing if the title parameter string is empty.
     
        - Returns: A bool indicating that the validation was successful.
     */
    fileprivate func validate(enteredInformation title: String) throws -> Bool {
    
        guard title != String() else { throw AccountImportValidation.valueMissing }
        
        return true
    }
    
    /// Makes the scroll view scrollable as soon as the keyboard shows.
    func keyboardWillShow(_ notification: Notification) {
        
        let info: NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        var keyboardHeight:CGFloat = keyboardSize.height
        keyboardHeight -= self.view.frame.height - self.scrollView.frame.height
        
        scrollView.contentInset = UIEdgeInsetsMake(0, 0, keyboardHeight - 10, 0)
        scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, keyboardHeight + 15, 0)
    }
    
    /// Resets the scroll view as soon as the keyboard hides.
    func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = UIEdgeInsets.zero
        scrollView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func accountTitleTextFieldFocused(_ sender: UITextField) {
        scrollView.scrollRectToVisible(view.convert(sender.frame, from: sender), animated: true)
    }
        
    @IBAction func createAccountButtonPressed(_ sender: AnyObject) {
        
        if let accountTitle = accountTitleTextField.text {
            createAccount(withTitle: accountTitle)
        }
    }
    
    @IBAction func changeField(_ sender: UITextField) {
        sender.endEditing(true)
    }
}
