//
//  TeamData.swift
//  Newsboard
//
//

import Foundation
import CoreData
import CoreLocation

class TeamData: NSManagedObject {
    class func fetchTeamData(teamName: String, inManagedObjectContext context: NSManagedObjectContext) ->TeamData? {
        let request = NSFetchRequest(entityName: "TeamData")
        request.predicate = NSPredicate(format: "teamName = %@", teamName)
        if let team = (try? context.executeFetchRequest(request))?.first as? TeamData {
            return team
        }
        return nil
    }
    
    class func getTeamData(teamName: String, teamID: String, teamLocation: CLLocation, inManagedObjectContext context: NSManagedObjectContext) ->TeamData? {
        let request = NSFetchRequest(entityName: "TeamData")
        request.predicate = NSPredicate(format: "teamName = %@", teamName)
        if let teamData = (try? context.executeFetchRequest(request))?.first as? TeamData {
            return teamData
        }
        else if let teamData = NSEntityDescription.insertNewObjectForEntityForName("TeamData", inManagedObjectContext: context) as? TeamData {
            teamData.teamName = teamName
            teamData.teamID = teamID
            teamData.latitude = teamLocation.coordinate.latitude
            teamData.longitude = teamLocation.coordinate.longitude
            return teamData
        }
        return nil
    }
    

}
