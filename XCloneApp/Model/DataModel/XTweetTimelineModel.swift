//
//  XTweetTimelineModel.swift
//  XCloneApp
//
//  Created by Abhay Curam on 9/28/25.
//

import Foundation

public class XTweetTimelineModel {
    
    private let boundedDeque: XBoundedDeque<XTweetPageModel>
    private let capacity: Int
    
    subscript(indexPath: IndexPath) -> XTweetModel? {
        guard let subscriptIndex = subscriptIndex(for: indexPath) else { return nil }
        var lower = 0
        for i in 0..<boundedDeque.count {
            let pageModel = boundedDeque[i]
            let upper = lower + pageModel.tweetCount
            if subscriptIndex >= lower && subscriptIndex < upper {
                return pageModel.tweets[subscriptIndex - lower]
            }
            lower = upper
        }
        return nil
    }
    
    public init(capacity: Int) {
        self.capacity = capacity
        boundedDeque = XBoundedDeque<XTweetPageModel>(capacity)
    }
    
    public func appendTweets(_ tweetPageModel: XTweetPageModel) {
        boundedDeque.insertBack(tweetPageModel)
    }
    
    public func prependTweets(_ tweetPageModel: XTweetPageModel) {
        boundedDeque.insertFront(tweetPageModel)
    }
    
    private func subscriptIndex(for indexPath: IndexPath) -> Int? {
        guard indexPath.section == 0 else { return nil }
        return indexPath.row
    }
}
