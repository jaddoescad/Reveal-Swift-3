
import UIKit
import Firebase
import JSQMessagesViewController
import CoreData


class ChatLogController: JSQMessagesViewController, NSFetchedResultsControllerDelegate {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var myJSQmessageLabelstatus: String?
        var firstLayout = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        if self.firstLayout && self.automaticallyScrollsToMostRecentMessage {
            self.scrollToBottom(animated: false)
        }
        
    }
    
    
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    lazy var fetchedResultsControler: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Mesages")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    
    
    
    var blockOperations = [BlockOperation]()
    private func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeObject anObject: AnyObject, atIndexPath indexPath: IndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if type == .insert {

            blockOperations.append(BlockOperation(block: { [weak self] in 
               
                if let this = self {
                
                this.collectionView.collectionViewLayout.invalidateLayout()
                this.collectionView?.insertItems(at: [newIndexPath!])
                this.inputToolbar.contentView.textView.text = nil
                    
                }

                
            }))
        }
        if type == .update {
            blockOperations.append(BlockOperation(block: { [weak self] in
                if let this = self {

            this.collectionView.collectionViewLayout.invalidateLayout()
            this.collectionView.reloadItems(at: [indexPath!])
                }
            }))
            
        }
    }
        private func controllerDidChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
            
            if fetchedResultsControler.fetchedObjects?.count != 0 {
        collectionView?.performBatchUpdates({() -> Void in

            
            for operation in self.blockOperations {
                operation.start()

            }
            
            }, completion: { (finished) -> Void in
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                self.scrollToBottom(animated: true)
                CATransaction.commit()
                self.blockOperations.removeAll(keepingCapacity: false)


        })
            }
    }
    

    
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
        print(fetchedResultsControler.fetchedObjects?.count)

        self.senderId = "group"
        self.senderDisplayName = "name"
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 0.1, height: 0.1)
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 0.1, height: 0.1)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)

    }


   
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
    
    private func createMessageWithText(text: String, context: NSManagedObjectContext, date: NSDate){
        let message = NSEntityDescription.insertNewObject(forEntityName: "Mesages", into: context) as! Mesages
        
        message.text = text
        message.timestamp = date
    }
    
    deinit {
        print("deinitialized chatLog")
        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }
        
        blockOperations.removeAll(keepingCapacity: false)
    
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
        let msg : Mesages = fetchedResultsControler.object(at: indexPath) as! Mesages
        
        
        let messageData = JSQMessage(senderId: "group", displayName: "group", text: msg.text)
        
        return messageData
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let bubbleFactoryOutgoing = JSQMessagesBubbleImageFactory(bubble: UIImage.jsq_bubbleCompactTailless(), capInsets: UIEdgeInsets.zero)
        
        return bubbleFactoryOutgoing!.outgoingMessagesBubbleImage(with: UIColor.black)
        
        
        
        
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource!{
        return nil
    }
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String! ,senderDisplayName: String!, date: Date){
        let timestamp: NSNumber = Double(Date().timeIntervalSinceReferenceDate) as NSNumber
        
        
        let messagesNode = FIRDatabase.database().reference().child("messages")
        let messageName = messagesNode.childByAutoId()
        let values = ["text": text, "timestamp": timestamp, "messageStatus": "Sent"] as [String : Any]
        messagesNode.child(messageName.key).updateChildValues(values)
        
        
        
        saveMessagetoCoreData(text: text, timestamp: timestamp)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.scrollToBottom(animated: true)
        CATransaction.commit()
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        
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

}
