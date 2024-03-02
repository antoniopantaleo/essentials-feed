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
}
