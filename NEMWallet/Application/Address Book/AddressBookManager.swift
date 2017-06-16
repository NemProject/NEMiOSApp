//
//  AddressBookManager.swift
//
//  This file is covered by the LICENSE file in the root of this project.
//  Copyright (c) 2016 NEM
//

import UIKit
import Contacts

/**
    The address book manager singleton used to perform all kinds of actions in 
    relationship with the address book or a contact. Use this managers available 
    methods instead of writing your own logic.
 */
final class AddressBookManager {
    
    // MARK: - Manager Properties

    /// The singleton for the address book manager.
    open static let sharedInstance = AddressBookManager()
    
    /// The contact store used to work with the address book.
    fileprivate var contactStore = CNContactStore()
    
    // MARK: - Public Manager Methods
    
    /**
        Fetches all contacts of the address book.
     
        - Returns: All contacts of the address book.
     */
    open func contacts(_ completion: @escaping (_ contacts: [CNContact]) -> Void) {
        
        var contacts = [CNContact]()
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            self.requestAccess { [unowned self] (accessGranted) -> Void in
                if accessGranted {
                    
                    let containerIdentifier = self.contactStore.defaultContainerIdentifier()
                    let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactEmailAddressesKey]
                    let predicate = CNContact.predicateForContactsInContainer(withIdentifier: containerIdentifier)
                    
                    do {
                        contacts = try self.contactStore.unifiedContacts(matching: predicate, keysToFetch: keysToFetch as [CNKeyDescriptor])
                        contacts = self.sortContacts(contacts: contacts)
                        
                    } catch let error as NSError {
                        
                        DispatchQueue.main.async {
                            print(error)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    return completion(contacts)
                }
            }
        }
    }
    
    /**
        Creates a new contact and saves that contact in the local address book 
        of the device.
     
        - Parameter firstName: The first name of the new contact.
        - Parameter lastName: The last name of the contact.
        - Parameter accountAddress: The account address of the new contact.
     
        - Returns: The operation result.
     */
    open func createContact(withFirstName firstName: String, andLastName lastName: String, andAccountAddress accountAddress: String, completion: @escaping (_ result: Result) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            self.requestAccess { (accessGranted) -> Void in
                if accessGranted {
                    
                    let contactAccountAddress = CNLabeledValue(label: "NEM", value: accountAddress as NSString)
                    
                    let contact = CNMutableContact()
                    contact.givenName = firstName
                    contact.familyName = lastName
                    contact.emailAddresses = [contactAccountAddress]
                    
                    let saveRequest = CNSaveRequest()
                    saveRequest.add(contact, toContainerWithIdentifier: nil)
                    
                    do {
                        try self.contactStore.execute(saveRequest)
                        
                        DispatchQueue.main.async {
                            return completion(.success)
                        }
                        
                    } catch let error as NSError {
                        
                        DispatchQueue.main.async {
                            print(error)
                            return completion(.failure)
                        }
                    }
                    
                } else {
                    
                    DispatchQueue.main.async {
                        return completion(.failure)
                    }
                }
            }
        }
    }
    
    /**
        Updates the properties of a contact.
     
        - Parameter contact: The existing contact that should get updated.
        - Parameter firstName: The new first name of the contact that should get updated.
        - Parameter lastName: The new last name of the contact that should get updated.
        - Parameter accountAddress: The new account address of the contact that should get updated.
     */
    open func updateProperties(ofContact contact: CNContact, withNewFirstName firstName: String, andNewLastName lastName: String, andNewAccountAddress accountAddress: String, completion: @escaping (_ result: Result) -> Void) {
                
        DispatchQueue.global(qos: .userInitiated).async {
            
            self.requestAccess { (accessGranted) -> Void in
                if accessGranted {
                    
                    let accountAddressSanitized = accountAddress.replacingOccurrences(of: "-", with: "")
                    
                    let mutableContact = contact.mutableCopy() as! CNMutableContact
                    mutableContact.givenName = firstName
                    mutableContact.familyName = lastName
                    
                    var contactEmailAddresses = [CNLabeledValue<NSString>]()
                    var isAccountAddress = false
                    for emailAddress in mutableContact.emailAddresses {
                        let newEmailAddress = CNLabeledValue<NSString>(label: emailAddress.label, value: (emailAddress.label == "NEM") ? accountAddressSanitized as NSString : emailAddress.value)
                        
                        if (emailAddress.label == "NEM" && accountAddressSanitized == "") {
                            break
                        }
                        
                        contactEmailAddresses.append(newEmailAddress)
                        
                        if (newEmailAddress.label == "NEM") {
                            isAccountAddress = true
                        }
                    }
                    
                    if isAccountAddress == false && accountAddressSanitized != "" {
                        let newEmailAddress = CNLabeledValue(label: "NEM", value: accountAddressSanitized as NSString)
                        contactEmailAddresses.append(newEmailAddress)
                    }
                    
                    mutableContact.emailAddresses = contactEmailAddresses
                    
                    let saveRequest = CNSaveRequest()
                    saveRequest.update(mutableContact)
                    
                    do {
                        try self.contactStore.execute(saveRequest)
                        
                        DispatchQueue.main.async {
                            return completion(.success)
                        }
                        
                    } catch let error as NSError {
                        
                        DispatchQueue.main.async {
                            print(error)
                            return completion(.failure)
                        }
                    }
                    
                } else {
                    
                    DispatchQueue.main.async {
                        return completion(.failure)
                    }
                }
            }
        }
    }
    
    /**
        Deletes the provided contact from the address book.
     
        - Parameter contact: The contact that should get deleted form the address book.
     */
    open func deleteContact(contact: CNContact, completion: @escaping (_ result: Result) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            self.requestAccess { (accessGranted) -> Void in
                if accessGranted {
                    
                    let saveRequest = CNSaveRequest()
                    saveRequest.delete(contact.mutableCopy() as! CNMutableContact)
                    
                    do {
                        try self.contactStore.execute(saveRequest)
                        
                        DispatchQueue.main.async {
                            return completion(.success)
                        }
                        
                    } catch let error as NSError {
                        
                        DispatchQueue.main.async {
                            print(error)
                            return completion(.failure)
                        }
                    }
                    
                } else {
                    
                    DispatchQueue.main.async {
                        return completion(.failure)
                    }
                }
            }
        }
    }
    
    /**
        Fetches the account address from the contacts email addresses if
        possible.
     
        - Parameter contact: The contact for which the account address should get fetched.
     
        - Returns: The account address as a string.
     */
    open func fetchAccountAddress(fromContact contact: CNContact) -> String {
        
        var contactAccountAddress = String()
        
        for emailAddress in contact.emailAddresses where emailAddress.label == "NEM" {
            contactAccountAddress = emailAddress.value as String
        }
        
        return contactAccountAddress
    }
    
    // MARK: - Private Manager Methods
    
    /**
        Checks if the application has access to the address book of the user.
     
        - Returns: Bool indicating whether the application has access or not.
     */
    fileprivate func requestAccess(_ completion: @escaping (_ accessGranted: Bool) -> Void) {
        let authorizationStatus = CNContactStore.authorizationStatus(for: CNEntityType.contacts)
        
        switch authorizationStatus {
        case .authorized:
            return completion(true)
            
        case .denied, .notDetermined:
            contactStore.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    return completion(access)
                } else {
                    return completion(false)
                }
            })
            
        default:
            completion(false)
        }
    }
    
    /**
        Sorts provided contacts. Contacts with an account address are
        at the top.
     
        - Parameter contacts: The contacts that should get sorted.
     
        - Returns: The sorted contacts array.
     */
    fileprivate func sortContacts(contacts: [CNContact]) -> [CNContact] {
        
        var sortedContacts = [CNContact]()
        var nemContacts = [CNContact]()
        var otherContacts = [CNContact]()
        
        for contact in contacts {
            var hasAccountAddress = false
            
            for email in contact.emailAddresses where email.label == "NEM" {
                hasAccountAddress = true
            }
            
            if hasAccountAddress {
                nemContacts.append(contact)
            } else {
                otherContacts.append(contact)
            }
        }
        
        sortedContacts += nemContacts
        sortedContacts += otherContacts
        
        return sortedContacts
    }
}
