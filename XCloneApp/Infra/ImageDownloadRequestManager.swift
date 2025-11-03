//
//  ImageDownloadRequestManager.swift
//  XCloneApp
//
//  Created by Abhay Curam on 11/2/25.
//

import Foundation
import UIKit

public class ImageDownloadRequest: Hashable {
    public var imageUri: String
    public var requestHandler: ((UIImage?) -> Void)
    
    public init(_ imageUri: String, _ handler: @escaping ((UIImage?) -> Void)) {
        self.imageUri = imageUri
        self.requestHandler = handler
    }
    
    public static func ==(lhs: ImageDownloadRequest, rhs: ImageDownloadRequest) -> Bool {
        return lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

public class ImageDownloadRequestManager {
    
    private var currentRequests = [String: (currentTask: URLSessionDataTask, observers: Set<ImageDownloadRequest>)]()
    public var imageCache = NSCache<NSString, UIImage>()
    
    public init() {
        preconditionMainThread()
        NotificationCenter.default.addObserver(self, selector: #selector(handleMemoryPressure(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 1024 * 1024 * 50 // 50 MB
    }
    
    public func addRequest(_ ImageDownloadRequest: ImageDownloadRequest) {
        preconditionMainThread()
        if let cachedImage = imageCache.object(forKey: ImageDownloadRequest.imageUri as NSString) {
            ImageDownloadRequest.requestHandler(cachedImage)
        } else {
            // first check if we currently are serving this request
            if currentRequests[ImageDownloadRequest.imageUri] != nil {
                currentRequests[ImageDownloadRequest.imageUri]?.observers.insert(ImageDownloadRequest)
            } else {
                // create the request, record it, then execute it
                if let url = URL(string: ImageDownloadRequest.imageUri) {
                    let task = URLSession.shared.dataTask(with: url, completionHandler: { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
                        if let strongSelf = self {
                            if error != nil {
                                strongSelf.publishResponse(nil, ImageDownloadRequest.imageUri)
                            }
                            if let imageData = data {
                                let image = UIImage(data: imageData)
                                let decodedImage = image?.preparingForDisplay()
                                strongSelf.publishResponse(decodedImage, ImageDownloadRequest.imageUri)
                            } else {
                                strongSelf.publishResponse(nil, ImageDownloadRequest.imageUri)
                            }
                        }
                    })
                    currentRequests[ImageDownloadRequest.imageUri] = (task, Set<ImageDownloadRequest>([ImageDownloadRequest]))
                    task.resume()
                }
            }
        }
    }
    
    public func cancelRequest(_ ImageDownloadRequest: ImageDownloadRequest) {
        // you clear the passed in ImageDownloadRequest call back first.
        // If you have cleared them all then suspend the download task since its not needed.
        preconditionMainThread()
        if currentRequests[ImageDownloadRequest.imageUri] != nil {
            currentRequests[ImageDownloadRequest.imageUri]?.observers.remove(ImageDownloadRequest)
            if currentRequests[ImageDownloadRequest.imageUri]?.observers.count == 0 {
                currentRequests[ImageDownloadRequest.imageUri]?.currentTask.cancel()
                currentRequests.removeValue(forKey: ImageDownloadRequest.imageUri)
            }
        }
    }
    
    private func publishResponse(_ image: UIImage?, _ uri: String) {
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self, let storedRequest = strongSelf.currentRequests[uri] {
                if let image = image {
                    strongSelf.imageCache.setObject(image, forKey: uri as NSString)
                }
                let observers = storedRequest.observers
                for observer in observers {
                    observer.requestHandler(image)
                }
                strongSelf.currentRequests.removeValue(forKey: uri)
            }
        }
    }
    
    @objc private func handleMemoryPressure(_ notification: Notification) {
        imageCache.removeAllObjects()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
