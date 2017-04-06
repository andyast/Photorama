//
//  DetailInterfaceController.swift
//  Photorama
//
//  Created by Andy Steinmann on 4/6/17.
//  Copyright © 2017 DLS. All rights reserved.
//

import WatchKit
import Foundation

class DetailInterfaceController: WKInterfaceController {

    @IBOutlet var image: WKInterfaceImage!

    var photo: [String: Any]!

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()


    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        if let photo = context as? [String: Any] {
            self.photo = photo

            guard let urlString = photo["url_q"] as? String else {
                return
            }

            guard let url = URL(string: urlString) else {
                return
            }

            let request = URLRequest(url: url)
            let task = session.dataTask(with: request) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse {
                    self.printHttpResponseInfo(response: httpResponse)
                }
                guard let data = data else {
                    return
                }
                guard let image = UIImage(data: data) else {
                    return
                }
                OperationQueue.main.addOperation {
                    self.image.setImage(image)
                }
            }
            task.resume()

        }
    }

    private func printHttpResponseInfo(response: HTTPURLResponse) {
        print("Status Code: \(response.statusCode)")
        print("Headers:")
        for (key, value) in response.allHeaderFields {
            print("\t\(key): \(value)")
        }
    }
}
