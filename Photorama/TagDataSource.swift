//
//  TagDataSource.swift
//  Photorama
//
//  Created by Andy Steinmann on 4/5/17.
//  Copyright © 2017 DLS. All rights reserved.
//

import UIKit
import CoreData
class TagDataSource: NSObject, UITableViewDataSource {
    var tags: [Tag] = []
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell",
                                                 for: indexPath)
        let tag = tags[indexPath.row]
        cell.textLabel?.text = tag.name
        return cell
    }
}
