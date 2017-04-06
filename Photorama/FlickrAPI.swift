//
//  FlickrAPI.swift
//  Photorama
//
//  Created by Andy Steinmann on 3/30/17.
//  Copyright © 2017 DLS. All rights reserved.
//

import Foundation
import CoreData


enum CreatePhotoErrorType: Error {
    case invalidJSONData, photoAlreadyExists
}

enum FeedType: Int32 {
    case interesting, recent
}

enum Method: String {
    case interestingPhotos = "flickr.interestingness.getList"
    case recentPhotos = "flickr.photos.getRecent"
}

enum FlickrError: Error {
    case invalidJSONData
}

struct FlickrAPI {
    private static let baseURLString = "https://api.flickr.com/services/rest"
    private static let apiKey = "a6d819499131071f158fd740860a5a88"

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static func photo(fromFeed feed: FeedType, fromJSON json: [String: Any], into context: NSManagedObjectContext) throws -> Photo {
        guard
            let photoID = json["id"] as? String,
            let title = json["title"] as? String,
            let dateString = json["datetaken"] as? String,
            let photoURLString = json["url_h"] as? String,
            let url = URL(string: photoURLString),
            let widthString = json["width_h"] as? String,
            let height = json["height_h"] as? Int,
            let width = Int(widthString),
            let dateTaken = dateFormatter.date(from: dateString),
            let dateUploadString = json["dateupload"] as? String,
            let epochDate = Int(dateUploadString) else {
                // Don't have enough information to construct a Photo
                throw CreatePhotoErrorType.invalidJSONData
        }

        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "\(#keyPath(Photo.photoID)) == \(photoID)")
        fetchRequest.predicate = predicate
        var fetchedPhotos: [Photo]?
        context.performAndWait {
            fetchedPhotos = try? fetchRequest.execute()
        }
        if let _ = fetchedPhotos?.first {
            throw CreatePhotoErrorType.photoAlreadyExists
        }


        var photo: Photo!
        context.performAndWait {
            photo = Photo(context: context)
            photo.title = title
            photo.photoID = photoID
            photo.remoteURL = url as NSURL
            photo.dateTaken = dateTaken as NSDate
            photo.height = Int64(height)
            photo.width = Int64(width)
            photo.feedType = feed.rawValue
            photo.dateUploaded = Date(timeIntervalSince1970: TimeInterval(epochDate)) as NSDate
        }
        return photo
    }

    static func photos(fromFeed feed: FeedType, fromJSON data: Data, into context: NSManagedObjectContext) -> PhotosResult {
        do {


            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])

            guard
                let jsonDictionary = jsonObject as? [AnyHashable: Any],
                let photos = jsonDictionary["photos"] as? [String: Any],
                let photosArray = photos["photo"] as? [[String: Any]] else {
                    // The JSON structure doesn't match our expectations
                    return .failure(FlickrError.invalidJSONData)
            }

            var finalPhotos = [Photo]()
            for photoJSON in photosArray {
                do {
                    let photo = try self.photo(fromFeed: feed, fromJSON: photoJSON, into: context)
                    finalPhotos.append(photo)

                } catch CreatePhotoErrorType.invalidJSONData {
                    //return .failure(FlickrError.invalidJSONData)

                } catch CreatePhotoErrorType.photoAlreadyExists {
                    //Swallow this error as it basically means we don't need to do anything
                }

            }



            let documentsDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentDirectory = documentsDirectories.first!

            let path = documentDirectory.appendingPathComponent("feed_\(feed).json")
            do {
                if let jsonStr = String(data: data, encoding: .utf8) {
                    try jsonStr.write(to: path, atomically: true, encoding: .utf8)
                    DispatchQueue.main.async() {
                        let _ = WatchSessionManager.sharedManager.transferFile(file: path as NSURL, metadata: ["feed" : "\(feed)" as AnyObject])
                    }
                }

            }
            catch {
                print("Error transfering file: \(error)")
            }


            return .success(finalPhotos)
        } catch let error {
            return .failure(error)
        }
    }

    private static func flickrURL(method: Method,
                                  parameters: [String: String]?) -> URL {

        var components = URLComponents(string: baseURLString)!
        var queryItems = [URLQueryItem]()

        let baseParams = [
            "method": method.rawValue,
            "format": "json",
            "nojsoncallback": "1",
            "safe_search": "1",
            "api_key": apiKey
        ]
        for (key, value) in baseParams {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }

        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                let item = URLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
        }
        components.queryItems = queryItems
        return components.url!
    }

    static var interestingPhotosURL: URL {
        return flickrURL(method: .interestingPhotos,
                         parameters: ["extras": "url_h,date_taken,date_upload, url_sq, url_t, url_s, url_q, url_m, url_n, url_z, url_c, url_l, url_o"])

    }

    static var recentPhotosURL: URL {
        return flickrURL(method: .recentPhotos,
                         parameters: ["extras": "url_h,date_taken,date_upload, url_sq, url_t, url_s, url_q, url_m, url_n, url_z, url_c, url_l, url_o"])

    }



}
