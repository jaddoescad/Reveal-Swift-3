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

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Mesages> {
        return NSFetchRequest<Mesages>(entityName: "Mesages");
    }

    @NSManaged public var text: String?
    @NSManaged public var timestamp: NSDate?

}
