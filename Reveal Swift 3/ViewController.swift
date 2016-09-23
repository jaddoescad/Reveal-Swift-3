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
    
    // var messagesController: MessagesController?
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
        
      //  AuthandGotoHome()
        
    }
}
