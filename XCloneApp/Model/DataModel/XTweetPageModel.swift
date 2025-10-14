//
//  XTweetPageModel.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/30/25.
//

/**
 * The central data model we display on the Feed representing a "page" of tweets.
 * XTweetPageModel is nothing but a collection of "tweets" with metadata on
 * pagination information like previousPageToken and nextPageToken to fetch
 * the "next" or "previous" page.
 */
public struct XTweetPageModel {
    public let nextPageToken: String?
    public let previousPageToken: String?
    public let tweetCount: Int
    public let tweets: [XTweetModel]
    
    public init(_ timelineResponseModel: XTimelineResponseModel) {
        nextPageToken = timelineResponseModel.meta.nextToken
        previousPageToken = timelineResponseModel.meta.previousToken
        tweetCount = timelineResponseModel.meta.resultCount
        tweets = XTweetModelFactory.createTweets(timelineResponseModel)
    }
    
    private func createTweetsModel(_ timelineResponseModel: XTimelineResponseModel) -> [XTweetModel] {
        var tweets = [XTweetModel]()
        let mediaIDMap = timelineResponseModel.includes.mediaMap
        let usersIDMap = timelineResponseModel.includes.usersMap
        for dataFieldItem in timelineResponseModel.data {
            var mediaAttachments = [XMediaAttachmentModel]()
            if let mediaIDs = dataFieldItem.attachmentIds {
                for mediaID in mediaIDs {
                    if let mediaAttachment = mediaIDMap[mediaID] {
                        mediaAttachments.append(mediaAttachment)
                    }
                }
            }
            let tweet = XTweetModel(text: dataFieldItem.text,
                                    createdTime: dataFieldItem.createdTime,
                                    author: usersIDMap[dataFieldItem.authorId] ?? nil,
                                    attachments: !mediaAttachments.isEmpty ? mediaAttachments : nil)
            tweets.append(tweet)
        }
        return tweets
    }
    
}
