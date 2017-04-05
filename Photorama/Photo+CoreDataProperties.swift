//
//  Photo+CoreDataProperties.swift
//  Photorama
//
//  Created by Andy Steinmann on 4/4/17.
//  Copyright © 2017 DLS. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var dateTaken: NSDate?
    @NSManaged public var height: Int64
    @NSManaged public var photoID: String?
    @NSManaged public var remoteURL: NSURL?
    @NSManaged public var title: String?
    @NSManaged public var width: Int64
    @NSManaged public var feedType: Int32
    @NSManaged public var dateUploaded: NSDate?
    @NSManaged public var tags: NSSet?

}

// MARK: Generated accessors for tags
extension Photo {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: Tag)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: Tag)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}
