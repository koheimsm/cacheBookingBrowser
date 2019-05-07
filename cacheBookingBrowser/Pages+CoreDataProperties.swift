//
//  Pages+CoreDataProperties.swift
//  cacheBookingBrowser
//
//  Created by Kohei Masumi on 2019/03/22.
//  Copyright © 2019年 Kohei Masumi. All rights reserved.
//

import Foundation
import CoreData


extension Pages {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pages> {
        return NSFetchRequest<Pages>(entityName: "Pages")
    }
    
    @NSManaged public var pageName: String?
    @NSManaged public var snapshot: NSData?
    @NSManaged public var url: String?
}

