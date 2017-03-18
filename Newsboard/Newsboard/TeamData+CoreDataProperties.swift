//
//  TeamData+CoreDataProperties.swift
//  Newsboard
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension TeamData {

    @NSManaged var teamName: String?
    @NSManaged var teamID: String?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double

}
