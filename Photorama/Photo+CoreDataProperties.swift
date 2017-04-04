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
    @NSManaged public var photoId: String?
    @NSManaged public var remoteURL: NSURL?
    @NSManaged public var title: String?
    @NSManaged public var width: Int64

}
