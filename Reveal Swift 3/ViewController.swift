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
    
    @IBOutlet weak var finishedlogin: UILabel!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let dispatch_group = DispatchGroup()
    
    @IBOutlet var signinbutton: UIButton!
    @IBOutlet weak var activityindic: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Mesages")
        do {
            if let messages = try context.fetch(fetchRequest) as? [Mesages] {
                for message in messages {
                    
                    context.delete(message)
                    
                }
                
            }
        } catch { }
        view.backgroundColor = UIColor.white
    }
    
    
    @IBAction func loginButton(sender: AnyObject) {
        
        AuthandGotoHome()
        
    }
    func AuthandGotoHome() {
        dispatch_group.notify(queue: DispatchQueue.main, execute: {
            self.activityindic.stopAnimating()
            self.finishedlogin.text = "finished"
            //let controller = ChatLogController()
              self.observeRealTimeMessages()
             self.observeMessages()
            //self.showViewController(controller, sender: nil)
        })
        
        
        func observeMessages() {
            dispatch_group.enter()
            
            FIRDatabase.database().reference().child("messages").observeSingleEvent(of: .value, with: {(_snapshot) in
                
                guard let Messages = _snapshot.value as? [String: AnyObject] else {
                    
                    self.dispatch_group.leave()
                    return}
                
                let SortedMessages = Messages.values.sorted { message1, message2 in
                    let date1 = message1["timestamp"] as! NSNumber
                    let date2 = message2["timestamp"] as! NSNumber
                    return date1.compare(date2) == ComparisonResult.orderedAscending
                }
                
                for message in SortedMessages {
                    let timestamp = message["timestamp"] as! NSNumber
                    let date = NSDate(timeIntervalSinceReferenceDate: (Double(timestamp)))
                    let countRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Mesages")
                    countRequest.predicate = NSPredicate(format: "timestamp = %@", date)
                    do {
                        let count = try self.context.count(for: countRequest)
                        if count == 0 {
                           self.createMessageWithText(text: message["text"] as! String, context: self.context, date: date)
                        }
                        try self.context.save()
                        
                    }
                    catch {}
                    
                }
                
                
                self.dispatch_group.leave()
            })
            
            
        }
    }
    
    func observeRealTimeMessages() {
        
        FIRDatabase.database().reference().child("messages").queryLimited(toLast: 10).observe(.childAdded, with: {(snapshot) in
            guard let messageInfo = snapshot.value as? [String: AnyObject] else {return}
            let message = MessageModel(dictionary: messageInfo)
            
            guard let timestamp = message.timestamp else {return}
            guard let text = message.text else {return}
            
            let date = NSDate(timeIntervalSinceReferenceDate: (Double(timestamp)))
            
            let countRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Mesages")
            countRequest.predicate = NSPredicate(format: "timestamp = %@", date)
            
            do
            {
                
                let count = try self.context.count(for: countRequest)
                if count == NSNotFound {}
                if  count == 0 {
                    self.createMessageWithText(text: text, context: self.context, date: date)
                }
                try self.context.save()
            } catch {}
            
        })
        
        
    }
    func createMessageWithText(text: String, context: NSManagedObjectContext, date: NSDate) {
        
        let message = NSEntityDescription.insertNewObject(forEntityName: "Mesages", into: context) as! Mesages
        
        
        message.text = text
        message.timestamp = date
        
    }
    
    
    
    func createMessageRealTime(text: String, context: NSManagedObjectContext, date: NSDate) {
        let message = NSEntityDescription.insertNewObject(forEntityName: "Mesages", into: context) as! Mesages
        
        message.text = text
        message.timestamp = date
        
    }
}
