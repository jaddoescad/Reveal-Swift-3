//
//  Mesages+CoreDataProperties.swift
//  
//
//  Created by jad on 2016-09-22.
//
//

import Foundation
import CoreData


extension Mesages {

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "Mesages") as! NSFetchRequest<NSFetchRequestResult>;
    }

    @NSManaged public var text: String?
    @NSManaged public var timestamp: Date?

}
