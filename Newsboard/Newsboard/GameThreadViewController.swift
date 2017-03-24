//
//  GameThreadViewController.swift
//  FireChat-Swift
//
//  Created with help of tutorial by Katherine Fang on 8/13/14.
//

import UIKit
import JSQMessagesViewController
import Foundation
import FirebaseDatabase
import FirebaseAuth

import UIKit

class GameThreadViewController: JSQMessagesViewController {
    
    // Frontend
    
    var messages = [JSQMessage]()
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()

    override func viewDidLoad() {
        super.viewDidLoad()
        handleChannel()
        self.senderId = FIRAuth.auth()?.currentUser?.uid
        self.inputToolbar.contentView.leftBarButtonItem = nil
        observeMessages()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeTyping()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        guard let senderDisplayName = message.senderDisplayName
            else {
                assertionFailure()
                return nil
        }
        return NSAttributedString(string: senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 14
    }

    // Backend
    
    var teamOne: String?
    var teamTwo: String?
    var rootRef = FIRDatabase.database().reference()
    private lazy var messageRef: FIRDatabaseReference = self.rootRef.child("messages")
    private var newMessageRefHandle: FIRDatabaseHandle?
    private var gameThreadRef: FIRDatabaseReference?
    
    
    private func handleChannel() {
        let messageName = teamOne! + teamTwo!
        self.gameThreadRef = self.messageRef.child(messageName)
    }
    
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = self.gameThreadRef?.childByAutoId() // 1
        let messageItem = [ // 2
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!,
            ]
        
        itemRef?.setValue(messageItem) // 3
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
        
        finishSendingMessage() // 5
        isTyping = false
    }
    
    private func observeMessages() {
        //messageRef = messageRef.child("messages)
        // 1.
        let messageQuery = gameThreadRef?.queryLimited(toLast:25)
        
        // 2. We can use the observe method to listen for new
        // messages being written to the Firebase DB
        newMessageRefHandle = messageQuery?.observe(.childAdded, with: { (snapshot) -> Void in
            // 3
            let messageData = snapshot.value as! Dictionary<String, String>
            
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.characters.count > 0 {
                // 4
                self.addMessage(withId: id, name: name, text: text)
                
                // 5
                self.finishReceivingMessage()
            } else {
                print("Error! Could not decode message data")
            }
        })
    }

    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
    private lazy var userIsTypingRef: FIRDatabaseReference =
        self.rootRef.child("typingIndicator").child(self.senderId) // 1
        private var localTyping = false // 2
        var isTyping: Bool {
            get {
                return localTyping
            }
            set {
                // 3
                localTyping = newValue
                userIsTypingRef.setValue(newValue)
            }
        }
    
    private func observeTyping() {
        let typingIndicatorRef = self.rootRef.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
    }
}

