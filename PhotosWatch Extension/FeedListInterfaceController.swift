//
//  FeedListInterfaceController.swift
//  Photorama
//
//  Created by Andy Steinmann on 4/6/17.
//  Copyright © 2017 DLS. All rights reserved.
//

import WatchKit
import Foundation

class FeedListInterfaceController : WKInterfaceController {
    
    @IBAction func showRecentFeed() {
        pushController(withName: "ListInterfaceController", context: ["feedType":"recent"])
        
    }
    @IBAction func showInterestingFeed() {
        pushController(withName: "ListInterfaceController", context: ["feedType":"interesting"])
    }
}
