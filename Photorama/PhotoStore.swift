//
//  PhotoStore.swift
//  Photorama
//
//  Created by Andy Steinmann on 3/30/17.
//  Copyright © 2017 DLS. All rights reserved.
//

import UIKit
import CoreData

enum PhotosResult {
    case success([Photo])
    case failure(Error)
}

enum ImageResult {
    case success(UIImage)
    case failure(Error)
}
enum PhotoError: Error {
    case imageCreationError
}

enum TagsResult {
    case success([Tag])
    case failure(Error)
}


class PhotoStore {
    let imageStore = ImageStore()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()

    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Photorama")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print("Error setting up Core Data (\(error)).")
            }
        }
        return container
    }()

    private func processPhotosRequest(fromFeed feed: FeedType, data: Data?, error: Error?) -> PhotosResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return FlickrAPI.photos(fromFeed: feed, fromJSON: jsonData, into: persistentContainer.viewContext)
    }

    private func fetchPhotos(fromFeed feed: FeedType, completion: @escaping (PhotosResult) -> Void) {

        let url = urlForFeed(feed: feed)

        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                self.printHttpResponseInfo(response: httpResponse)
            }
            var result = self.processPhotosRequest(fromFeed: feed, data: data, error: error)

            if case .success = result {
                do {
                    try self.persistentContainer.viewContext.save()
                } catch let error {
                    result = .failure(error)
                }
            }

            DispatchQueue.main.async {
                completion(result)
            }
        }
        task.resume()
    }

    private func urlForFeed(feed: FeedType) -> URL {
        switch feed {
        case .interesting:
            return FlickrAPI.interestingPhotosURL
        case .recent:
            return FlickrAPI.recentPhotosURL
        }
    }


    func fetchRecentPhotos(completion: @escaping (PhotosResult) -> Void) {
        fetchPhotos(fromFeed: .recent, completion: completion)
    }

    func fetchInterestingPhotos(completion: @escaping (PhotosResult) -> Void) {
        fetchPhotos(fromFeed: .interesting, completion: completion)
    }


    func fetchImage(for photo: Photo, completion: @escaping (ImageResult) -> Void) {

        guard let photoKey = photo.photoID else {
            preconditionFailure("Photo expected to have a photoID.")
        }

        if let image = imageStore.imageForKey(key: photoKey) {
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            return
        }


        guard let photoURL = photo.remoteURL else {
            preconditionFailure("Photo expected to have a remote URL.")
        }

        let request = URLRequest(url: photoURL as URL)
        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                self.printHttpResponseInfo(response: httpResponse)
            }
            let result = self.processImageRequest(data: data, error: error)

            if case let .success(image) = result {
                self.imageStore.setImage(image: image, forKey: photoKey)
            }


            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }


    func fetchAllPhotos(fromFeed feed: FeedType, completion: @escaping (PhotosResult) -> Void) {

        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "\(#keyPath(Photo.feedType)) == \(feed.rawValue)")
        fetchRequest.predicate = predicate

        let sortByDateTaken = NSSortDescriptor(key: #keyPath(Photo.dateTaken), ascending: true)

        fetchRequest.sortDescriptors = [sortByDateTaken]



        let context = persistentContainer.viewContext
        context.performAndWait {
            do {
                let allPhotos = try context.fetch(fetchRequest)

                completion(.success(allPhotos))
            } catch {
                completion(.failure(error))
            }

        }


    }

    func fetchAllTags(completion: @escaping (TagsResult) -> Void) {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        let sortByName = NSSortDescriptor(key: #keyPath(Tag.name), ascending: true)
        fetchRequest.sortDescriptors = [sortByName]
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let allTags = try fetchRequest.execute()
                completion(.success(allTags))
            } catch {
                completion(.failure(error))
            }
        }
    }


    private func processImageRequest(data: Data?, error: Error?) -> ImageResult {
        guard
            let imageData = data,
            let image = UIImage(data: imageData) else {
                // Couldn't create an image
                return data == nil ? .failure(error!) : .failure(PhotoError.imageCreationError)
        }

        return .success(image)
    }

    private func printHttpResponseInfo(response: HTTPURLResponse) {
        print("Status Code: \(response.statusCode)")
        print("Headers:")
        for (key, value) in response.allHeaderFields {
            print("\t\(key): \(value)")
        }
    }

}
