//
//  ManagedFeedImage+CoreDataClass.swift
//  EssentialFeed
//
//  Created by Antonio on 02/03/24.
//
//

import Foundation
import CoreData

@objc(ManagedFeedImage)
public class ManagedFeedImage: NSManagedObject, Identifiable {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ManagedFeedImage> {
        return NSFetchRequest<ManagedFeedImage>(entityName: "ManagedFeedImage")
    }
    
    @NSManaged public var id: UUID
    @NSManaged public var imageDescription: String?
    @NSManaged public var location: String?
    @NSManaged public var url: URL
    @NSManaged public var cache: ManagedCache
}
