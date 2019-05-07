//
//  TabData.swift
//  cacheBookingBrowser
//
//  Created by Kohei Masumi on 2019/03/22.
//  Copyright © 2019年 Kohei Masumi. All rights reserved.
//

import UIKit
import WebKit

struct TabData
{
    var dataListTitle: String!
    var dataListUrl: String!
    var dataListImage:UIImage!
    //var dataListFolderPath: String!
    
    init(dataListTitle: String!, dataListUrl: String!, dataListImage: UIImage!){
        
        self.dataListTitle = dataListTitle
        self.dataListUrl = dataListUrl
        self.dataListImage = dataListImage
    }
}

