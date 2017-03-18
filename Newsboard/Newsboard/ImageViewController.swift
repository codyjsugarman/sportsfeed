//
//  ImageViewController.swift
//  Newsboard
//
//

import UIKit

class ImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    fileprivate var firstLaunched :Bool?
    
    @IBOutlet weak var imageView: UIImageView! {
        didSet{
            imageView.isUserInteractionEnabled = true
        }
    }
    
    fileprivate var aspectRatioConstraint: NSLayoutConstraint?
    fileprivate var firstLaunch = true
    
  

    @IBOutlet weak var titleView: TitleView! {
        didSet{
            titleView.addGestureRecognizer(UIPanGestureRecognizer(target: titleView, action: "drawPath:"))
            titleView.addGestureRecognizer(UITapGestureRecognizer(target: titleView, action: "blurImage:"))
            titleView.addGestureRecognizer(UITapGestureRecognizer(target: titleView, action: "unblurImage:"))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if firstLaunch {
            firstLaunch = false
            choosePicture()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // UIGraphicsBeginImageContext(image?.size)
    }
    
    fileprivate func choosePicture() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(
                title: "No Camera Detected",
                message: ":(",
                preferredStyle: UIAlertControllerStyle.alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
                alert in
                self.performSegue(withIdentifier: "cancel", sender: self)
            }))
            self.present(alert, animated: true, completion: nil)
            image = UIImage(named: "den")
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let mediaImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            image = mediaImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        firstLaunch = true
        dismiss(animated: true, completion: {
            self.performSegue(withIdentifier: "cancel", sender: self)
        })
    }
    
    
    fileprivate var image: UIImage? {
        get {
            return imageView?.image
        }
        set {
            imageView?.image = newValue
            
            if aspectRatioConstraint != nil {
                imageView.removeConstraint(aspectRatioConstraint!)
            }
            
            if let image = newValue, let imageView = imageView {
                let aspectRatio = image.size.width / image.size.height
                aspectRatioConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: aspectRatio, constant: 0)
            }
        }
    }
    
    @IBAction func goBack(_ sender: AnyObject) {
        /**
        let path = titleView.currentPath
        UIGraphicsBeginImageContext(image!.size)
        image?.drawInRect(CGRect(origin: CGPointZero, size: image!.size))
        path.stroke()
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
**/
        presentingViewController?.dismiss(animated: true, completion: nil)

    }
}
