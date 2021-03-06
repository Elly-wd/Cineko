//
//  Account+CoreDataProperties.swift
//  Cineko
//
//  Created by Jovit Royeca on 06/04/2016.
//  Copyright © 2016 Jovito Royeca. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Account {
    
    @NSManaged var accountID: NSNumber?
    @NSManaged var gravatarHash: String?
    @NSManaged var includeAdult: NSNumber?
    @NSManaged var iso6391: String?
    @NSManaged var iso31661: String?
    @NSManaged var name: String?
    @NSManaged var username: String?
    @NSManaged var favoriteMovies: NSSet?
    @NSManaged var favoriteTVShows: NSSet?
    @NSManaged var lists: NSSet?
}
