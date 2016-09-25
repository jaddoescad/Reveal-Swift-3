//OS_ACTIVITY_MODE = disable
import UIKit
import Firebase
import JSQMessagesViewController
import CoreData


class ChatLogController: JSQMessagesViewController, NSFetchedResultsControllerDelegate {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
        var firstLayout = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //allows scrolling to bottom to be unnoticeable when u first login by forcing layout subviews
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.view.layoutIfNeeded()
        self.collectionView.collectionViewLayout.invalidateLayout()
        if self.automaticallyScrollsToMostRecentMessage {
            self.firstLayout = true
            DispatchQueue.main.async(execute: {() -> Void in
                self.firstLayout = false
            })
        }

    }
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //occurs after forcing layout subviews if both conditions are true it scrolls to bottom
        if self.firstLayout && self.automaticallyScrollsToMostRecentMessage {
            self.scrollToBottom(animated: false)
        }
        
    }
    
    
    //init for fetched results controller with the predicate of timestamp not being nil and sorted by timestamp
    lazy var fetchedResultsControler: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Mesages")
        fetchRequest.predicate = NSPredicate(format: "timestamp != nil")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    
    
    //block operations to make sure that everything is happening in sequence to avoid perturbed message rearrangement
    var blockOperations = [BlockOperation]()

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //make sure the fetched object does not equal zero not sure why we have it will investigate later
        if fetchedResultsControler.fetchedObjects?.count != 0 {
            //batchupdates the messages, very useful for late messages
            collectionView?.performBatchUpdates({() -> Void in
                for operation in self.blockOperations {
                    operation.start()
                }
                }, completion: { (finished) -> Void in
                    //emptys block to avoid memory leaks
                    self.blockOperations.removeAll(keepingCapacity: false)
            })
        }

    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if type == .insert {
            blockOperations.append(BlockOperation(block: { [weak self] in
                if let this = self {
                    //invalidates layout before insert, since the collection view dimensions are changing, this is to avoid crashes
                    this.collectionView.collectionViewLayout.invalidateLayout()
                    this.collectionView?.insertItems(at: [newIndexPath!])
                    //will relocate later it might cause a bug when other people send messages
                    this.inputToolbar.contentView.textView.text = nil

                }
                
                
                }))
        }
        if type == .update {
            blockOperations.append(BlockOperation(block: { [weak self] in
                if let this = self {
                    //invalidates layout before insert, since the collection view dimensions are changing, this is to avoid crashes
                    this.collectionView.collectionViewLayout.invalidateLayout()
                    this.collectionView.reloadItems(at: [indexPath!])
                }
                }))
            
        }

    }

    

    //this whole function is to count the messages to make sure that when we load earlier messages we have the right number of messages to reload so they doesnt overlap and crash
    func getMessagesCount() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Mesages")
        do{
            do {
            let count = try context.count(for: fetchRequest)
            if count <= 20 {
                try fetchedResultsControler.performFetch()

            } else {
                fetchedResultsControler.fetchRequest.fetchOffset = count - 20
                try fetchedResultsControler.performFetch()
            }
            } catch {}
        }    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getMessagesCount()
       // self.observeRealTimeMessages()
        //required inits by jsqmessagescontroller
        self.senderId = "group"
        self.senderDisplayName = "name"
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 0.1, height: 0.1)
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 0.1, height: 0.1)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        //removes observers when chat log disappears
        let messagesref =  FIRDatabase.database().reference().child("messages")
        messagesref.removeAllObservers()

    }

    
    deinit {
        print("deinitialized chatLog")
        //emptys block operations if any are left to avoid leaks

        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }
        blockOperations.removeAll(keepingCapacity: false)
        //removing observers
   
        print("deinit")
    
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) ->
        
        Int {
            guard let count = fetchedResultsControler.sections?[0].numberOfObjects   , count != 0 else {return 0 }
            if fetchedResultsControler.fetchRequest.fetchOffset + count > (fetchedResultsControler.sections?[0].numberOfObjects)! {
                self.showLoadEarlierMessagesHeader = true
                
            }
            
            return count
            
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        //message data that populates table coredata->Jsq->collectionview
        let msg : Mesages = fetchedResultsControler.object(at: indexPath) as! Mesages
        let messageData = JSQMessage(senderId: "group", displayName: "group", text: msg.text)
        return messageData
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        //configutation for bubbles
        let bubbleFactoryOutgoing = JSQMessagesBubbleImageFactory(bubble: UIImage.jsq_bubbleCompactTailless(), capInsets: UIEdgeInsets.zero)
        
        return bubbleFactoryOutgoing!.outgoingMessagesBubbleImage(with: UIColor.black)
        
        
        
        
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource!{
        return nil
    }
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String! ,senderDisplayName: String!, date: Date){
        let timestamp: NSNumber = Double(Date().timeIntervalSinceReferenceDate) as NSNumber
        //save the messages to coredata when you press send which trigger NSFetchedresultscontroller and updates the collection view
        saveMessagetoCoreData(text: text, timestamp: timestamp)
        
        //updates firebase so that other users can get the messages in realtime
        let messagesNode = FIRDatabase.database().reference().child("messages")
        let messageName = messagesNode.childByAutoId()
        let values = ["text": text, "timestamp": timestamp, "messageStatus": "Sent"] as [String : Any]
        //updates firebase node
        messagesNode.child(messageName.key).updateChildValues(values)
        //scrolls to bottom when message is saved
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.scrollToBottom(animated: true)
        CATransaction.commit()
        
        
      
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        //sorts and displays load earlier messages by calculating offset
        fetchedResultsControler.fetchRequest.sortDescriptors  = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        
        do {
            
            
            if fetchedResultsControler.fetchRequest.fetchOffset > 20 {
                fetchedResultsControler.fetchRequest.fetchOffset = fetchedResultsControler.fetchRequest.fetchOffset - 20
                
                
            } else {
                fetchedResultsControler.fetchRequest.fetchOffset = fetchedResultsControler.fetchRequest.fetchOffset - fetchedResultsControler.fetchRequest.fetchOffset
                self.showLoadEarlierMessagesHeader = false
            }
            
            try fetchedResultsControler.performFetch()
            print(fetchedResultsControler.fetchRequest.fetchOffset)
            
            
        } catch {}
        
        let oldOffset: CGFloat = self.collectionView.contentSize.height - self.collectionView.contentOffset.y
        self.collectionView.reloadData()
        self.collectionView.layoutIfNeeded()
        self.collectionView.contentOffset = CGPoint(x: 0.0, y: self.collectionView.contentSize.height - oldOffset)
    }
    //saves messages to coredata
    func saveMessagetoCoreData(text: String, timestamp: NSNumber) {
        
        let doubletimestamp = Double(timestamp)
        let date = NSDate(timeIntervalSinceReferenceDate: (doubletimestamp))
        
        createMessageWithText(text: text, context: context, date: date)
        
        
        do {
            try context.save()
            self.inputToolbar.toggleSendButtonEnabled()
        } catch let err {
            print(err)
        }
    }
    //assigns messages to each core data object
    private func createMessageWithText(text: String, context: NSManagedObjectContext, date: NSDate){
        let message = NSEntityDescription.insertNewObject(forEntityName: "Mesages", into: context) as! Mesages
        message.text = text
        message.timestamp = date
    }
    
    //observes messages when a message is sent to you
    func observeRealTimeMessages() {
        // observe if a child is added querys to last messages when we first login
        FIRDatabase.database().reference().child("messages").queryLimited(toLast: 10).observe(.childAdded, with: {(snapshot) in
            guard let messageInfo = snapshot.value as? [String: AnyObject] else {return}
            let message = MessageModel(dictionary: messageInfo)
            
            guard let timestamp = message.timestamp else {return}
            guard let text = message.text else {return}
            
            let date = NSDate(timeIntervalSinceReferenceDate: (Double(timestamp)))
            //checks if there are duplicates
            let countRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Mesages")
            countRequest.predicate = NSPredicate(format: "timestamp = %@", date)
            
            do
            {
                
                let count = try self.context.count(for: countRequest)
                if count == NSNotFound {}
                if  count == 0 {
                    self.createMessageWithText(text: text, context: self.context, date: date)
                    try self.context.save()
                    //scrolls to bottom when message is received
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    self.scrollToBottom(animated: true)
                    CATransaction.commit()

                }
            
                
            } catch {}
            
        })
        
        
    }
    //creates real time message when message is received
    func createMessageRealTime(text: String, context: NSManagedObjectContext, date: NSDate) {
        let message = NSEntityDescription.insertNewObject(forEntityName: "Mesages", into: context) as! Mesages
        message.text = text
        message.timestamp = date
        
    }
    
}
