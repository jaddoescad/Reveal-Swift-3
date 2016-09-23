//
//  MessageModel.swift
//  gameofchats
//
//  Created by Rayan Slim on 2016-09-09.
//  Copyright © 2016 letsbuildthatapp. All rights reserved.
//

import Foundation


class MessageModel: NSObject
{   //variable for the model: text and timestamp.
    var text: String?
    var timestamp: NSNumber?
    //initializer for model variable
    init(dictionary: [String: AnyObject])
    {
        super.init()
        text = dictionary["text"] as? String
        timestamp = dictionary["timestamp"] as? NSNumber
    }

}

