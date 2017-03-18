//
//  MessagesViewController.swift
//  FireChat-Swift
//
//  Created with help of tutorial by Katherine Fang on 8/13/14.
//

import UIKit
import JSQMessagesViewController
import Foundation
import FirebaseDatabase
import FirebaseAuth

class MessagesViewController: JSQMessagesViewController {
    
    var channelRef: FIRDatabaseReference?
    var messages = [JSQMessage]()
    
    private lazy var messageRef: FIRDatabaseReference = self.channelRef!.child("messages")
    private var newMessageRefHandle: FIRDatabaseHandle?
    
    
    var channel: Channel? {
        didSet {
            title = channel?.name
        }
    }
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    override func viewDidLoad() {
        //Signin anonymously
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in}) // 2
        self.senderId = "1234"
        self.senderDisplayName = "Test"
//        observeMessages()
        super.viewDidLoad()
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
    
    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
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
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = messageRef.childByAutoId() // 1
        let messageItem = [ // 2
            "senderId": senderId!,
            "senderName": senderDisplayName!,
            "text": text!,
            ]
        
        itemRef.setValue(messageItem) // 3
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound() // 4
        
        finishSendingMessage() // 5
    }
    
    private func observeMessages() {
        messageRef = channelRef!.child("messages")
        // 1.
        let messageQuery = messageRef.queryLimited(toLast:25)
        
        // 2. We can use the observe method to listen for new
        // messages being written to the Firebase DB
        newMessageRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
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
    
    
    /**
    let eventTitle = "Title Placeholder"
    let imagePicker = UIImagePickerController()
    var imageToSend = UIImage()
    var messages = [JSQMessage]()
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor(red: 10/255, green: 180/255, blue: 230/255, alpha: 1.0))
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.lightGray)
    
    var avatars = Dictionary<String, JSQMessagesAvatarImage>()
    var isSendingImage = false
    var outgoingBubbleImageView = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    var incomingBubbleImageView = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
    
    var senderImageUrl: String!
    var batchMessages = true
    var ref = FIRDatabase.database().reference()
    
    
    // *** STEP 1: STORE FIREBASE REFERENCES
    var messagesRef = FIRDatabase.database().reference()
    var sender = "Anonymous"
    
    func setupFirebase() {
        // *** STEP 4: RECEIVE MESSAGES FROM FIREBASE
        messagesRef.observe(FIRDataEventType.value, with: { (snapshot) in
            self.sender = snapshot.value["sender"] as! String
            print("SENDER: " + self.sender)
            let text = snapshot.value["text"] as? String
            let imageUrl = snapshot.value["imageUrl"] as? String
            if (imageUrl == nil || imageUrl == "") {
                let message = JSQMessage(senderId: self.sender, displayName: self.sender, text: text)
                self.messages.append(message)
            } else {
                //Use imageUrl to retrieve image from firebase
                let decodedData = NSData(base64EncodedString: imageUrl!, options: NSDataBase64DecodingOptions.IgnoreUnknownCharacters)
                let imgToSend = UIImage(data: decodedData!)
                let photoMediaItem = JSQPhotoMediaItem(image: imgToSend)
                let message = JSQMessage(senderId: self.sender, displayName: self.sender, media: photoMediaItem)
                self.messages.append(message)
            }
            self.finishReceivingMessage()
        })

    }
    
    func sendMessage(text: String!, sender: String!) {
        // *** STEP 3: ADD A MESSAGE TO FIREBASE
        var data: NSData = NSData()
        
        let image: UIImage? = imageToSend
        if (isSendingImage == true) {
            data = UIImageJPEGRepresentation(image!,0.1)! as NSData
            let base64String = data.base64EncodedStringWithOptions(NSData.Base64EncodingOptions.Encoding64CharacterLineLength)
            messagesRef.childByAutoId().setValue([
                "text":text,
                "sender":sender,
                "imageUrl":base64String
                ])
        } else {
            messagesRef.childByAutoId().setValue([
                "text":text,
                "sender":sender,
                ])
        }
        self.isSendingImage = false
    }
    
    
    func setupAvatarImage(name: String, imageUrl: String?, incoming: Bool) {
        if let stringUrl = imageUrl {
            if let url = NSURL(string: stringUrl) {
                if let data = NSData(contentsOf: url as URL) {
                    let image = UIImage(data: data as Data)
                    let diameter = incoming ? UInt(collectionView!.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView!.collectionViewLayout.outgoingAvatarViewSize.width)
                    let avatarImage = JSQMessagesAvatarImageFactory.avatarImage(with: image, diameter: diameter)
                    avatars[name] = avatarImage
                    return
                }
            }
        }
        
        // At some point, we failed at getting the image (probably broken URL), so default to avatarColor
        setupAvatarColor(name: name, incoming: incoming)
    }
    
    func setupAvatarColor(name: String, incoming: Bool) {
        let diameter = incoming ? UInt(collectionView!.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView!.collectionViewLayout.outgoingAvatarViewSize.width)
        
        let rgbValue = name.hash
        let r = CGFloat(Float((rgbValue & 0xFF0000) >> 16)/255.0)
        let g = CGFloat(Float((rgbValue & 0xFF00) >> 8)/255.0)
        let b = CGFloat(Float(rgbValue & 0xFF)/255.0)
        let color = UIColor(red: r, green: g, blue: b, alpha: 0.5)
        
        let nameLength = name.characters.count
        let initials = "placeholder initials"
//        let initials : String? = name.substringToIndex(sender.startIndex.advancedBy(min(3, nameLength)))
        
        let userImage = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: initials, backgroundColor: color, textColor: UIColor.black, font: UIFont.systemFont(ofSize: CGFloat(13)), diameter: diameter)
        print("IMAGE: " + String(describing: userImage?.avatarImage))
        avatars[name] = userImage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyScrollsToMostRecentMessage = true
        imagePicker.delegate = self
        messagesRef = ref.child(byAppendingPath: eventTitle)
        self.sender = "Anonymous"
        
        
        //        if let urlString = profileImageUrl {
        //            setupAvatarImage(sender, imageUrl: urlString as String, incoming: false)
        //            senderImageUrl = urlString as String
        //        } else {
        //            setupAvatarColor(sender, incoming: false)
        //            senderImageUrl = ""
        //        }
        
        setupFirebase()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let username = "name placeholder"
        self.senderId = username
        self.senderDisplayName = "Anonymous"
        self.senderImageUrl = ""
    }
    

    // ACTIONS
    func receivedMessagePressed(sender: UIBarButtonItem) {
        // Simulate reciving message
        showTypingIndicator = !showTypingIndicator
        scrollToBottom(animated: true)
    }
    
    
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let optionMenu = UIAlertController(title: nil, message: "Select Option", preferredStyle: .actionSheet)
        
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
                //                let imagePicker = UIImagePickerController()
                self.imagePicker.sourceType = .camera;
                self.imagePicker.allowsEditing = false
                self.present(self.imagePicker, animated: true, completion: nil)
            }
            print("Camera pressed!")
        })
        
        let selectPhotoAction = UIAlertAction(title: "Select Photo", style: .default, handler: {
            (alert: UIAlertAction!) -> Void in
            //            let imagePicker = UIImagePickerController()
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
            print("Photo Selected")
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        
        optionMenu.addAction(takePhotoAction)
        optionMenu.addAction(selectPhotoAction)
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
        
        
    }

    **/
}
