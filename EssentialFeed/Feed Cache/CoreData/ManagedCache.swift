//
//  ManagedCache+CoreDataClass.swift
//  EssentialFeed
//
//  Created by Antonio on 02/03/24.
//
//

import Foundation
import CoreData

@objc(ManagedCache)
public class ManagedCache: NSManagedObject, Identifiable {
    
    @NSManaged public var timestamp: Date
    @NSManaged public var feed: NSOrderedSet
    
    public static func find(in context: NSManagedObjectContext) throws -> ManagedCache? {
        let request = NSFetchRequest<ManagedCache>(entityName: entity().name!)
        request.returnsObjectsAsFaults = false
        return try context.fetch(request).first
    }
    
    public var localFeed: [LocalFeedImage] {
        return feed.compactMap { ($0 as? ManagedFeedImage)?.local }
    }
}
