//
//  InterfaceController.swift
//  PhotosWatch Extension
//
//  Created by Andy Steinmann on 4/5/17.
//  Copyright © 2017 DLS. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController {


    @IBOutlet var table: WKInterfaceTable!

    var currentPhotos: [[String: Any]] = []
    var currentFeedType: String!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        guard let context = context as? [String: Any] else {
            print("missing context")
            return
        }

        guard let feedType = context["feedType"] as? String else {
            print("context does not contain feedType: \(context)")
            return
        }

        currentFeedType = feedType
        setTitle(currentFeedType)


        loadFeed(feedType: currentFeedType)

        NotificationCenter.default.addObserver(self, selector: #selector(InterfaceController.processNotification(withNotification:)), name: .incomingFile, object: nil)

    }

    public func processNotification(withNotification notification: Notification) {
        guard let payload = notification.object as? [String: AnyObject] else {
            return
        }
        guard let path = payload["url"] as? URL else {
            return
        }
        guard let feed = payload["feedType"] as? String else {
            return
        }
        if feed == currentFeedType {
            readFile(path: path)
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func loadFeed(feedType: String) {
        let folder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.dls.photorama")!
        let path = folder.appendingPathComponent("feed_\(feedType).json")

        readFile(path: path)
    }

    func readFile(path: URL) {

        do {
            let data = try Data(contentsOf: path)

            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

            guard
                let jsonDictionary = jsonObject as? [AnyHashable: Any],
                let photos = jsonDictionary["photos"] as? [String: Any],
                let photosArray = photos["photo"] as? [[String: Any]] else {
                    print ("error loading json")
                    return
            }

            loadTable(photos: photosArray)
        }
        catch {
            print("error reading file: \(error)")
        }

    }
    func loadTable(photos: [[String: Any]]) {
        currentPhotos = photos.sorted(by: { (a, b) in
            let aEpochDate = Int(a["dateupload"] as! String)
            let bEpochDate = Int(b["dateupload"] as! String)
            return aEpochDate! > bEpochDate!
        })

        table.setNumberOfRows(currentPhotos.count, withRowType: "mainRowType")
        for index in 0 ..< currentPhotos.count {
            let row = table.rowController(at: index) as? MainRowType
            let data = currentPhotos[index]
            row?.rowDescription.setText(data["title"] as? String)
        }
    }

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        print("\(rowIndex)")
        let photo = currentPhotos[rowIndex]
        pushController(withName: "DetailInterfaceController", context: photo)
    }

    func contextsForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> [AnyObject]? {

        let photo = currentPhotos[rowIndex]
        return [photo as AnyObject]
    }

}


class MainRowType: NSObject {
    @IBOutlet weak var rowDescription: WKInterfaceLabel!
}
