//
//  PhotoStore.swift
//  Photorama
//
//  Created by Andy Steinmann on 3/30/17.
//  Copyright © 2017 DLS. All rights reserved.
//

import UIKit

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


class PhotoStore {
    let imageStore = ImageStore()
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()


    private func processPhotosRequest(data: Data?, error: Error?) -> PhotosResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        return FlickrAPI.photos(fromJSON: jsonData)
    }
    
    private func fetchPhotos(url:URL, completion: @escaping (PhotosResult) -> Void) {
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                self.printHttpResponseInfo(response: httpResponse)
            }
            let result = self.processPhotosRequest(data: data, error: error)
            DispatchQueue.main.async {
                completion(result)
            }
        }
        task.resume()
    }

    func fetchRecentPhotos(completion: @escaping (PhotosResult) -> Void) {
        fetchPhotos(url: FlickrAPI.recentPhotosURL, completion: completion)
    }

    func fetchInterestingPhotos(completion: @escaping (PhotosResult) -> Void) {
        fetchPhotos(url: FlickrAPI.interestingPhotosURL, completion: completion)
    }


    func fetchImage(for photo: Photo, completion: @escaping (ImageResult) -> Void) {
        
        let photoKey = photo.photoId!
        if let image = imageStore.imageForKey(key: photoKey) {
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            return
        }
        
        
        let photoURL = photo.remoteURL!
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

    private func processImageRequest(data: Data?, error: Error?) -> ImageResult {
        guard
            let imageData = data,
            let image = UIImage(data: imageData) else {
                // Couldn't create an image
                return data == nil ? .failure(error!) : .failure(PhotoError.imageCreationError)
        }

        return .success(image)
    }

    private func printHttpResponseInfo(response:HTTPURLResponse){
        print("Status Code: \(response.statusCode)")
        print("Headers:")
        for (key,value) in response.allHeaderFields {
            print("\t\(key): \(value)")
        }
    }

}
