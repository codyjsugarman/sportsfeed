//
//  ProfileViewController.swift
//  Newsboard
//
//

import UIKit
import MapKit

class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var teamData = [scheduleObject]()
    
    struct scheduleObject {
        var teamName: String
        var weekNumber: String
        var score: String
        var logoName: String
        var date: NSDate
        
    }

    @IBAction func addPicture(sender: AnyObject) {
        performSegueWithIdentifier("takePicture", sender: self)
        
    }
    

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        textField.delegate = self
        sportsTeam.text = sportsTeamName
        teamImage.image = UIImage(named: sportsID!.lowercaseString)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.startUpdatingLocation()
        let defaults = NSUserDefaults.standardUserDefaults()
        if let obj = defaults.objectForKey("favorites"){
            let favorites = obj as! [NSObject]
            if favorites.contains(sportsTeamName!){
                self.navigationItem.rightBarButtonItem?.title = "Added"
                self.navigationItem.rightBarButtonItem?.enabled = false
                self.navigationItem.rightBarButtonItem?.tintColor = UIColor.grayColor()
            }
        }
    }
    
    @IBOutlet weak var teamImage: UIImageView!
 
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
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
        mapView.addOverlay(polyline)
        
        let region = polyline.boundingMapRect
        mapView.setRegion(MKCoordinateRegionForMapRect(region), animated: true)
        
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.redColor()
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
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let mView = mapView.dequeueReusableAnnotationViewWithIdentifier("location") {
            mView.annotation = annotation
            return mView
        } else {
            let mView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "location")
            mView.canShowCallout = false
            return mView
        }
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        if let date = formatter.dateFromString(textField.text!) {
             let index = findClosestDate(date)
             let path = NSIndexPath(forItem: index, inSection: 0)
             teamSchedule.scrollToItemAtIndexPath(path, atScrollPosition: .CenteredHorizontally, animated: true)
        } else {
            let alert = UIAlertController(
                title: "Date Format Issue",
                message: "Enter date in MM/DD/YY format",
                preferredStyle: UIAlertControllerStyle.Alert
            )
            alert.addAction(UIAlertAction(title: "Enter again", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        return true
    }
    
    @IBOutlet weak var textField: UITextField!
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let index = findClosestDate(NSDate())
        let path = NSIndexPath(forItem: index, inSection: 0)
        if self.teamData.count > 0 {
            teamSchedule.scrollToItemAtIndexPath(path, atScrollPosition: .CenteredHorizontally, animated: animated)
        }
    }


    @IBOutlet weak var sportsTeam: UILabel!
    var sportsTeamName: String? {
        didSet{
            assembleView()
        }
    }
    
    var sportsID: String?
    
    var teamLocation: CLLocation?

    @IBOutlet weak var teamSchedule: UICollectionView!
    
    private func getDate(stringDate: String) -> NSDate? {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "e, MMM, d"
        let date = formatter.dateFromString(stringDate)
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components([NSCalendarUnit.Month, NSCalendarUnit.Day], fromDate: date!)
        let currentYear = calendar.components([NSCalendarUnit.Year], fromDate: NSDate()).year
        dateComponents.setValue(currentYear, forComponent: NSCalendarUnit.Year)
        dateComponents.calendar = calendar
        return dateComponents.date
    }
    
    private func findClosestDate(selectedDate: NSDate) -> Int {
        var closestIndex = 0
        var minInterval = Double(Int.max)
        for i in 0..<teamData.count {
            let date = teamData[i].date
            let interval = abs(date.timeIntervalSinceDate(selectedDate))
            if interval < minInterval {
                minInterval = interval
                closestIndex = i
            }
        }
        return closestIndex
    }
    
    
    private func assembleView() {
        
        if sportsID!.lowercaseString == "was"{
            sportsID! = "wsh"
        } else if sportsID!.lowercaseString == "jac" {
            sportsID! = "jax"
        }
    
        let sample = NSURL(string: "http://espn.go.com/nfl/team/schedule/_/name/" + sportsID!)
        let task = NSURLSession.sharedSession().dataTaskWithURL(sample!) {
            (data, response, error) in
            if error == nil {
                let htmlParser = TFHpple(HTMLData: data!)
                let query = "//table[@class='tablehead']/tr"
                if let results = htmlParser.searchWithXPathQuery(query) as? [TFHppleElement] {
                    for result in results {
                        let className = result.attributes["class"] as! String
                        if className.rangeOfString("oddrow") != nil || className.rangeOfString("evenrow") != nil {
                            if self.teamData.count < 16 {
                                let len = result.children.count
                                let gameNum = result.children[0].content
                                if len > 2 {
                                    let regex = try! NSRegularExpression(pattern: "team\\/_\\/name\\/(\\w*)", options: [])
                                    let raw = String(result.children[2].raw)
                                    let match = regex.firstMatchInString(raw, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, raw.characters.count))
                                    var logoName = String()
                                    if let id = match?.rangeAtIndex(1) {
                                        let startIndex = raw.startIndex.advancedBy((id.location))
                                        let endIndex = startIndex.advancedBy(id.length)
                                        logoName = raw.substringWithRange(Range<String.Index>(start: startIndex, end: endIndex))
                                    } else {
                                        logoName = "NFL"
                                    }
                                    
                                    let date = self.getDate(result.children[1].content)
                                    var team = String(result.children[2].content)
                                    if team.rangeOfString("vs") != nil {
                                        team = team.substringFromIndex(team.startIndex.advancedBy(2))
                                    }
                                    let score = result.children[3].content
                                    let schedule = scheduleObject(teamName: team, weekNumber: gameNum, score: score, logoName: logoName, date: date!)
                                    self.teamData.append(schedule)
                                }
                            }
                        }
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), {
                self.teamSchedule.reloadData()
            })
        }
        task.resume()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return teamData.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("cell", forIndexPath: indexPath)
        if let teamCell = cell as? TeamCollectionViewCell {
            teamCell.team.text = self.teamData[indexPath.row].teamName
            teamCell.logo.image = UIImage(named: self.teamData[indexPath.row].logoName)
            teamCell.weekNumber.text = self.teamData[indexPath.row].weekNumber
            teamCell.score.text = self.teamData[indexPath.row].score
        }
        return cell
    }
    
    @IBAction func addAsFavorite(sender: UIBarButtonItem) {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let obj = defaults.objectForKey("favorites"){
            var favorites = obj as! [NSObject]
            favorites.append(sportsTeamName!)
            defaults.setObject(favorites, forKey: "favorites")
        } else{
            defaults.setObject([sportsTeamName!], forKey: "favorites")
        }
        sender.title = "Added"
        sender.tintColor = UIColor.grayColor()
        sender.enabled = false
    }
    
    @IBAction func goBack(segue: UIStoryboardSegue) {
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        if let collectionCell = cell as? TeamCollectionViewCell {
            UIView.animateWithDuration(1.0, animations: {collectionCell.logo.alpha = 1.0 })
            UIView.animateWithDuration(3.0, animations: {collectionCell.logo.alpha = 0.15 })
        }
    }
}
