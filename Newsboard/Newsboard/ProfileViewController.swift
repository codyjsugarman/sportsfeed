//
//  ProfileViewController.swift
//  Newsboard
//
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseDatabase

class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var teamData = [scheduleObject]()
    
    var rootRef = FIRDatabase.database().reference()
    private lazy var usersRef: FIRDatabaseReference = self.rootRef.child("users")
    private lazy var teamsRef: FIRDatabaseReference = self.rootRef.child("teams")
    
    // MARK: Properties
    var senderDisplayName: String? // 1
    var newChannelTextField: UITextField? // 2
//    private var channels: [Channel] = [] // 3

    
    struct scheduleObject {
        var teamName: String
        var weekNumber: String
        var score: String
        var logoName: String
        var date: Date
        
    }

    @IBAction func addPicture(_ sender: AnyObject) {
        performSegue(withIdentifier: "takePicture", sender: self)
        
    }
    

    fileprivate let locationManager = CLLocationManager()
    fileprivate var currentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //observeChannels()
        self.automaticallyAdjustsScrollViewInsets = false
        textField.delegate = self
        sportsTeam.text = sportsTeamName
        teamImage.image = UIImage(named: sportsID!.lowercased())
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.startUpdatingLocation()
        let defaults = UserDefaults.standard
        if let obj = defaults.object(forKey: "favorites"){
            let favorites = obj as! [NSObject]
            if favorites.contains(sportsTeamName! as NSObject){
                self.navigationItem.rightBarButtonItem?.title = "Remove"
                //self.navigationItem.rightBarButtonItem?.isEnabled = false
                //self.navigationItem.rightBarButtonItem?.tintColor = UIColor.gray
            }
        }
        // Code taken from stack overflow tutorial- http://stackoverflow.com/questions/37875973/how-to-write-keyboard-notifications-in-swift-3
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:.UIKeyboardWillHide, object: nil)
    }
    
    deinit {
         NotificationCenter.default.removeObserver(self)
    }
    
    @IBOutlet weak var teamImage: UIImageView!
 
    func keyboardWillShow(notification: NSNotification) {
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location
        
        
        var coordinateArray = [(currentLocation?.coordinate)!]
        let annotation = TeamPin(coordinate: (currentLocation?.coordinate)!)
        mapView.addAnnotation(annotation)
        if let location = teamLocation {
            let teamAnnotation = TeamPin(coordinate: location.coordinate)
            mapView.addAnnotation(teamAnnotation)
            coordinateArray.append(location.coordinate)
        }
        locationManager.stopUpdatingLocation()
        
        let polyline = MKPolyline(coordinates: &coordinateArray, count: coordinateArray.count)
        mapView.add(polyline)
        
        let region = polyline.boundingMapRect
        mapView.setRegion(MKCoordinateRegionForMapRect(region), animated: true)
        
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.red
            polylineRenderer.lineWidth = 3
            return polylineRenderer
        }
        return MKPolylineRenderer()
    }

    
    @IBOutlet weak var mapView: MKMapView! {
        didSet{
            mapView.delegate = self
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let mView = mapView.dequeueReusableAnnotationView(withIdentifier: "location") {
            mView.annotation = annotation
            return mView
        } else {
            let mView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "location")
            mView.canShowCallout = false
            return mView
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        if let date = formatter.date(from: textField.text!) {
             let index = findClosestDate(date)
             let path = IndexPath(item: index, section: 0)
             teamSchedule.scrollToItem(at: path, at: .centeredHorizontally, animated: true)
        } else {
            let alert = UIAlertController(
                title: "Date Format Issue",
                message: "Enter date in MM/DD/YY format",
                preferredStyle: UIAlertControllerStyle.alert
            )
            alert.addAction(UIAlertAction(title: "Enter again", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        return true
    }
    
    @IBOutlet weak var textField: UITextField!
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let index = findClosestDate(Date())
        let path = IndexPath(item: index, section: 0)
        if self.teamData.count > 0 {
            teamSchedule.scrollToItem(at: path, at: .centeredHorizontally, animated: animated)
        }
    }


    @IBOutlet weak var sportsTeam: UILabel!
    var sportsTeamName: String? {
        didSet{
            assembleView()
        }
    }
    
    var sportsID: String?
    
    var opposingTeam: String?
    
    var teamLocation: CLLocation?

    @IBOutlet weak var teamSchedule: UICollectionView!
    
    fileprivate func getDate(_ stringDate: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "e, MMM, d"
        let date = formatter.date(from: stringDate)
        let calendar = Calendar.current
        
        let currentYear = calendar.dateComponents([.year] ,from: Date()).year! - 1
        var dateComponents = calendar.dateComponents([.month, .day], from: date!)
        dateComponents.setValue(currentYear, for: .year)
        dateComponents.calendar = calendar;
        return calendar.date(from: dateComponents)
        
        /**
        let dateComponents = (calendar as NSCalendar).components([NSCalendar.Unit.month, NSCalendar.Unit.day], from: date!)
        let currentYear = (calendar as NSCalendar).components([NSCalendar.Unit.year], from: Date()).year
        (dateComponents as NSDateComponents).setValue(currentYear!, forComponent: NSCalendar.Unit.year)
        (dateComponents as NSDateComponents).calendar = calendar
         **/
    }
    
    fileprivate func findClosestDate(_ selectedDate: Date) -> Int {
        var closestIndex = 0
        var minInterval = Double(Int.max)
        for i in 0..<teamData.count {
            let date = teamData[i].date
            let interval = abs(date.timeIntervalSince(selectedDate))
            if interval < minInterval {
                minInterval = interval
                closestIndex = i
            }
        }
        return closestIndex
    }
    
    
    fileprivate func assembleView() {
        
        if sportsID!.lowercased() == "was"{
            sportsID! = "wsh"
        } else if sportsID!.lowercased() == "jac" {
            sportsID! = "jax"
        }
    
        let sample = URL(string: "http://espn.go.com/nfl/team/schedule/_/name/" + sportsID!)
        let task = URLSession.shared.dataTask(with: sample!, completionHandler: {
            (data, response, error) in
            if error == nil {
                let htmlParser = TFHpple(htmlData: data!)
                let query = "//table[@class='tablehead']/tr"
                if let results = htmlParser?.search(withXPathQuery: query) as? [TFHppleElement] {
                    for result in results {
                        let className = result.attributes["class"] as! String
                        if className.range(of: "oddrow") != nil || className.range(of: "evenrow") != nil {
                            if self.teamData.count < 16 {
                                let len = result.children.count
                                let gameNum = (result.children[0] as AnyObject).content
                                if len > 2 {
                                    let regex = try! NSRegularExpression(pattern: "team\\/_\\/name\\/(\\w*)", options: [])
                                    let raw = String((result.children[2] as AnyObject).raw)
                                    let match = regex.firstMatch(in: raw!, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, (raw?.characters.count)!))
                                    var logoName = String()
                                    if let id = match?.rangeAt(1) {
                                        let startIndex = raw?.characters.index((raw?.startIndex)!, offsetBy: (id.location))
                                        let endIndex = raw?.characters.index((raw?.startIndex)!, offsetBy: (id.location + id.length))
                                        //let endIndex = //.index(startIndex!, offsetBy: id.length)
                                        logoName = (raw?.substring(with: (startIndex! ..< endIndex!)))!
                                    } else {
                                        logoName = "NFL"
                                    }
                                    
                                    let date = self.getDate((result.children[1] as AnyObject).content)
                                    var team = String((result.children[2] as AnyObject).content)
                                    if team?.range(of: "vs") != nil {
                                        team = team?.substring(from: (team?.characters.index((team?.startIndex)!, offsetBy: 2))!)
                                    }
                                    let score = (result.children[3] as AnyObject).content
                                    let schedule = scheduleObject(teamName: team!, weekNumber: gameNum!, score: score!, logoName: logoName, date: date!)
                                    self.teamData.append(schedule)
                                }
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async(execute: {
                self.teamSchedule.reloadData()
            })
        }) 
        task.resume()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return teamData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let teamCell = cell as? TeamCollectionViewCell {
            teamCell.team.text = self.teamData[indexPath.row].teamName
            teamCell.logo.image = UIImage(named: self.teamData[indexPath.row].logoName)
            teamCell.weekNumber.text = self.teamData[indexPath.row].weekNumber
            teamCell.score.text = self.teamData[indexPath.row].score
        }
        return cell
    }
    
    @IBAction func addAsFavorite(_ sender: UIBarButtonItem) {
        let defaults = UserDefaults.standard
        if (sender.title == "Add") {
            let defaults = UserDefaults.standard
            if let obj = defaults.object(forKey: "favorites"){
                var favorites = obj as! [NSObject]
                favorites.append(sportsTeamName! as NSObject)
                defaults.set(favorites, forKey: "favorites")
            } else{
                defaults.set([sportsTeamName!], forKey: "favorites")
            }
            if let obj = defaults.object(forKey: "favoriteID"){
                var favoriteID = obj as! [NSObject]
                favoriteID.append(sportsID! as NSObject)
                defaults.set(favoriteID, forKey: "favoriteID")
            } else{
                defaults.set([sportsID!], forKey: "favoriteID")
            }
            let teamRef = self.teamsRef.childByAutoId() // 1
            let teamItem = [ // 2
                "userId": FIRAuth.auth()?.currentUser?.uid,
                "teamID": sportsID!,
                "teamName": sportsTeamName!
            ]
            teamRef.setValue(teamItem)
            sender.title = "Remove"
        } else {
            if let obj = defaults.object(forKey: "favorites"){
                var searchArray = obj as? [String]
                let index = searchArray?.index(of: sportsTeamName!)
                searchArray?.remove(at: index!)
                defaults.set(searchArray, forKey: "favorites")
            }
            if let obj = defaults.object(forKey: "favoriteID"){
                var searchIDArray = obj as? [String]
                let index = searchIDArray?.index(of: sportsID!)
                searchIDArray?.remove(at: index!)
                defaults.set(searchIDArray, forKey: "favoriteID")
            }
            sender.title = "Add"
        }
       
        /**
        sender.title = "Added"
        let teamRef = self.teamsRef.childByAutoId() // 1
        let teamItem = [ // 2
            "userId": FIRAuth.auth()?.currentUser?.uid,
            "teamID": sportsID!,
            "teamName": sportsTeamName!
        ]
        teamRef.setValue(teamItem)
        sender.tintColor = UIColor.gray
        sender.isEnabled = false
         **/
    }
    
    @IBAction func goBack(_ segue: UIStoryboardSegue) {
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        if let collectionCell = cell as? TeamCollectionViewCell {
            opposingTeam = collectionCell.team.text!
            performSegue(withIdentifier: "goToThread", sender: self)
            //UIView.animate(withDuration: 1.0, animations: {collectionCell.logo.alpha = 1.0 })
            //UIView.animate(withDuration: 3.0, animations: {collectionCell.logo.alpha = 0.15 })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.identifier == "goToThread" {
            if let nvc = segue.destination as? UINavigationController {
                nvc.title = sportsTeamName! + opposingTeam!
                let mvc = nvc.topViewController as! GameThreadViewController
                mvc.teamOne = sportsTeamName
                mvc.teamTwo = opposingTeam
                
                
                let userQuery = usersRef.queryOrdered(byChild: "userID")
                let userRefHandle = userQuery.observe(.childAdded, with: { (snapshot) -> Void in
                    print(snapshot.value)
                    let userData = snapshot.value as! Dictionary<String, String>
                    if let id = userData["userId"] as String! {
                        if id == FIRAuth.auth()?.currentUser?.uid {
                            mvc.senderDisplayName = userData["username"]
                            return
                        }
                    }
                })
                mvc.senderDisplayName = "Test"
            }
        }
    }

    
}
