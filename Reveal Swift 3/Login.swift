//
//  ViewController.swift
//  Reveal Swift 3
//
//  Created by jad on 2016-09-22.
//  Copyright © 2016 Reveal. All rights reserved.
//

import UIKit
import Firebase
import CoreData

class LoginController: UIViewController  {
    //label to visually verify if authentication finished
    @IBOutlet weak var finishedlogin: UILabel!
    //initializing Core Data Context
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    //Initializing dispatch group: this is to make sure that all functions complete before presenting the chat controller
    let dispatch_group = DispatchGroup()
    
    @IBOutlet weak var loginButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //clears data in core data to start with a clean slate
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Mesages")
        do {
            //fetch messages
            if let messages = try context.fetch(fetchRequest) as? [Mesages] {
                //loops thru each message
                for message in messages {
                    //delete messages on by one
                    context.delete(message)
                    
                }
                
            }
        } catch { }
        //change the login background color to white
        view.backgroundColor = UIColor.white
    }
    
    //login button action
    @IBAction func loginButton(sender: AnyObject) {
        // a function that contains a set of function that enables authentication
        loginButton.isEnabled = false // this is done to solve the bug of creating multiple instances at the same time
        AuthandGotoHome()
        
    }
    
    
    func AuthandGotoHome() {
        
        UserDefaults.standard.set(true, forKey: "first_time")
        self.observeMessages()
        //is notified when all functions are completed then it presents the chat controller
        dispatch_group.notify(queue: DispatchQueue.main, execute: {
            self.finishedlogin.text = "finished"
            let controller = ChatLogController()
            //shows chat controller
            self.show(controller, sender: nil)
            self.loginButton.isEnabled = true
        })
    }
    

        func observeMessages() {
            //enters dispatch group
            dispatch_group.enter()
            //gets a snapshot of all the messages from firebase
            FIRDatabase.database().reference().child("messages").observeSingleEvent(of: .value, with: {(_snapshot) in
                //checks if Messages are nil otherwise it continues
                guard let Messages = _snapshot.value as? [String: AnyObject] else {
                    //leaves dispatch group if Messages is nil
                    self.dispatch_group.leave()
                    return
                }
                //Higher order function that sorts messages by timestamp
                let SortedMessages = Messages.values.sorted { message1, message2 in
                    let date1 = message1["timestamp"] as! NSNumber
                    let date2 = message2["timestamp"] as! NSNumber
                    return date1.compare(date2) == ComparisonResult.orderedAscending
                }
                
                //checks if there is a duplicate of messages, otherwise it creates messages.
                for message in SortedMessages {
                    let timestamp = message["timestamp"] as! NSNumber
                    let date = NSDate(timeIntervalSinceReferenceDate: (Double(timestamp)))
                    let countRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Mesages")
                    //efficient count request to check if messages exist by count
                    countRequest.predicate = NSPredicate(format: "timestamp = %@", date)
                    do {
                        let count = try self.context.count(for: countRequest)
                        if count == 0 {
                            //create messages by assigning text and timestamp to the coredata objects
                           self.createMessageWithText(text: message["text"] as! String, context: self.context, date: date)
                        }
                        //saves messages
                        try self.context.save()
                        
                    }
                    catch {}
                    
                }
                
                //leaves dispatch group
                self.dispatch_group.leave()
            })
            
            
        }
    
    





    func createMessageWithText(text: String, context: NSManagedObjectContext, date: NSDate) {
        let message = NSEntityDescription.insertNewObject(forEntityName: "Mesages", into: context) as! Mesages
        //assigns text to message.text coredata object; same for timestamp
        message.text = text
        message.timestamp = date
    }

}
