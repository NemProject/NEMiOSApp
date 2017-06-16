//
//  AddressBookViewController.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import Contacts

/**
    The view controller that shows all available contacts with their corresponding 
    NEM account address. This view controller lets the user add new contacts or 
    send a transaction directly to a specific contact.
 */
final class AddressBookViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - View Controller Properties
    
    fileprivate var contacts = [CNContact]()
    fileprivate var filteredContacts = [CNContact]()
    
    // MARK: - View Controller Outlets

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchContainer: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var addContactButton: UIButton!
    
    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchTextField.delegate = self
        
        updateViewControllerAppearanceOnViewDidLoad()
        fetchContacts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateViewControllerAppearanceOnViewWillAppear()
        createEditButtonItemIfNeeded()
        
        if (tableView.indexPathForSelectedRow != nil) {
            let indexPath = tableView.indexPathForSelectedRow!
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    /// Needed for a smooth appearance of the alert view controller.
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    /// Needed for a smooth appearance of the alert view controller.
    override var canResignFirstResponder: Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        view.endEditing(true)
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier! {
        case "showTransactionSendViewController":
            
            let destinationViewController = segue.destination as! TransactionSendViewController
            destinationViewController.recipientAddress = sender as! String
            
        default:
            return
        }
    }
    
    // MARK: - View Controller Helper Methods
    
    /// Updates the appearance (coloring, titles) of the view controller on view did load.
    fileprivate func updateViewControllerAppearanceOnViewDidLoad() {
        
        tabBarController?.title = "ADDRESS_BOOK".localized()
        searchTextField.placeholder = "SEARCH_CONTACTS".localized()
        addContactButton.setTitle("ADD_CONTACT".localized(), for: UIControlState())
        addContactButton.setImage(#imageLiteral(resourceName: "Add").imageWithColor(UIColor(red: 90.0/255.0, green: 179.0/255.0, blue: 232.0/255.0, alpha: 1)), for: UIControlState())
        addContactButton.imageView!.contentMode = UIViewContentMode.scaleAspectFit
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    /// Updates the appearance (coloring, titles) of the view controller on view will appear.
    fileprivate func updateViewControllerAppearanceOnViewWillAppear() {
        
        tabBarController?.title = "ADDRESS_BOOK".localized()
    }
    
    /**
        Checks if there are any contacts to show and creates an edit button
        item on the right of the navigation bar if that's the case.
     */
    fileprivate func createEditButtonItemIfNeeded() {
        
        if (contacts.count > 0) {
            tabBarController?.navigationItem.rightBarButtonItem = editButtonItem
        } else {
            tabBarController?.navigationItem.rightBarButtonItem = nil
        }
    }
    
    /**
        Shows an alert view controller with the provided alert message.
     
        - Parameter message: The message that should get shown.
        - Parameter completion: An optional action that should get performed on completion.
     */
    fileprivate func showAlert(withMessage message: String, andTitle title: String? = "INFO".localized(), completion: ((Void) -> Void)? = nil) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.default, handler: { (action) -> Void in
            alert.dismiss(animated: true, completion: nil)
            completion?()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    /// Fetches all contacts and reloads the table view with the fetched content.
    fileprivate func fetchContacts() {
        
        AddressBookManager.sharedInstance.contacts { [weak self] (contacts) in
            self?.contacts = contacts
            
            if self?.searchTextField.text != "" && self != nil {
                self!.search(self!.searchTextField!)
            }
            
            self?.tableView.reloadData()
            self?.createEditButtonItemIfNeeded()
        }
    }
    
    /**
        Asks the user for confirmation of the deletion of a contact and deletes
        the contact accordingly from both the table view and the database.
     
        - Parameter indexPath: The index path of the contact that should get removed and deleted.
     */
    fileprivate func deleteContact(atIndexPath indexPath: IndexPath) {
        
        var contact = CNContact()
        if searchTextField.text != "" {
            contact = filteredContacts[indexPath.row]
        } else {
            contact = contacts[indexPath.row]
        }
        
        let contactDeletionAlert = UIAlertController(title: "INFO".localized(), message: String(format: "DELETE_CONFIRMATION_MASSAGE_ADDRESSBOOK".localized(), "\(contact.givenName) \(contact.familyName)"), preferredStyle: .alert)
        
        contactDeletionAlert.addAction(UIAlertAction(title: "CANCEL".localized(), style: .cancel, handler: nil))
        
        contactDeletionAlert.addAction(UIAlertAction(title: "OK".localized(), style: .destructive, handler: { [unowned self] (action) in
            
            if self.searchTextField.text != "" {
                self.filteredContacts.remove(at: indexPath.row)
            } else {
                self.contacts.remove(at: indexPath.row)
            }
            self.tableView.deleteRows(at: [indexPath], with: .bottom)
            
            AddressBookManager.sharedInstance.deleteContact(contact: contact, completion: { (result) in
                
                switch result {
                case .failure:
                    
                    self.showAlert(withMessage: "Couldn't delete contact")
                    
                default:
                    break
                }
                
                self.fetchContacts()
            })
        }))
        
        present(contactDeletionAlert, animated: true, completion: nil)
    }
    
    /**
        Asks the user to update the contact properties for an existing contact and makes
        the change accordingly.
     
        - Parameter indexPath: The index path of the contact that should get updated.
     */
    fileprivate func updateContactProperties(forContactAtIndexPath indexPath: IndexPath) {
        
        var contact = CNContact()
        if searchTextField.text != "" {
            contact = filteredContacts[indexPath.row]
        } else {
            contact = contacts[indexPath.row]
        }
        
        let contactPropertiesUpdaterAlert = UIAlertController(title: "CHANGE".localized(), message: "CHANGE_CONTACT".localized(), preferredStyle: .alert)
        
        contactPropertiesUpdaterAlert.addAction(UIAlertAction(title: "CANCEL".localized(), style: .cancel, handler: nil))
        
        contactPropertiesUpdaterAlert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: { [unowned self] (action) in
            
            let firstNameTextField = contactPropertiesUpdaterAlert.textFields![0] as UITextField
            let lastNameTextField = contactPropertiesUpdaterAlert.textFields![1] as UITextField
            let accountAddressTextField = contactPropertiesUpdaterAlert.textFields![2] as UITextField
            
            guard let firstName = firstNameTextField.text else { return }
            guard let lastName = lastNameTextField.text else { return }
            guard let accountAddress = accountAddressTextField.text else { return }
            
            AddressBookManager.sharedInstance.updateProperties(ofContact: contact, withNewFirstName: firstName, andNewLastName: lastName, andNewAccountAddress: accountAddress, completion: { [weak self] (result) in
                
                self?.fetchContacts()
            })
        }))
        
        contactPropertiesUpdaterAlert.addTextField { (textField) in
            textField.text = contact.givenName
            textField.placeholder = "FIRST_NAME".localized()
        }
        
        contactPropertiesUpdaterAlert.addTextField { (textField) in
            textField.text = contact.familyName
            textField.placeholder = "LAST_NAME".localized()
        }
        
        contactPropertiesUpdaterAlert.addTextField { (textField) in
            textField.text = AddressBookManager.sharedInstance.fetchAccountAddress(fromContact: contact)
            textField.placeholder = "ADDRESS".localized()
        }
        
        present(contactPropertiesUpdaterAlert, animated: true, completion: nil)
    }
    
    // MARK: - View Controller Outlet Actions
    
    @IBAction func search(_ sender: UITextField) {
        
        guard searchTextField.text != nil else { return }
        
        let searchText = searchTextField.text!.lowercased()
        
        filteredContacts = contacts.filter { contact in
            let fullName = "\(contact.givenName) \(contact.familyName)".lowercased()
            return fullName.contains(searchText)
        }
        
        tableView.reloadData()
    }
    
    /**
        Unwinds to the address book view controller and reloads all
        contacts to show.
     */
    @IBAction func unwindToAddressBookViewController(_ segue: UIStoryboardSegue) {
        
        fetchContacts()
    }
}

// MARK: - Table View Delegate

extension AddressBookViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchTextField.text != "" {
            return filteredContacts.count
        } else {
            return contacts.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressBookContactTableViewCell") as! AddressBookContactTableViewCell
        
        if searchTextField.text != "" {
            cell.contact = filteredContacts[indexPath.row]
        } else {
            cell.contact = contacts[indexPath.row]
        }
        
        return cell
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        switch editingStyle {
        case .delete:
            
            deleteContact(atIndexPath: indexPath)
            
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.isEditing || (tableView.cellForRow(at: indexPath) as! AddressBookContactTableViewCell).accessoryImageView.isHidden {
            
            updateContactProperties(forContactAtIndexPath: indexPath)
            
        } else {
            
            var contact = CNContact()
            if searchTextField.text != "" {
                contact = filteredContacts[indexPath.row]
            } else {
                contact = contacts[indexPath.row]
            }
            
            var accountAddress = String()
            for emailAddress in contact.emailAddresses where emailAddress.label == "NEM" {
                accountAddress = emailAddress.value as String
            }
            
            let alert = UIAlertController(title: "\(contact.givenName) \(contact.familyName)", message: accountAddress.nemAddressNormalised(), preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "SEND_MESSAGE".localized(), style: UIAlertActionStyle.default, handler: { [unowned self] (action) in
                
                self.performSegue(withIdentifier: "showTransactionSendViewController", sender: accountAddress)
            }))
            
            alert.addAction(UIAlertAction(title: "OK".localized(), style: UIAlertActionStyle.cancel, handler: { [unowned self] (action) -> Void in
                
                alert.dismiss(animated: true, completion: nil)
                self.tableView.deselectRow(at: indexPath, animated: true)
            }))
            
            present(alert, animated: true, completion: nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
