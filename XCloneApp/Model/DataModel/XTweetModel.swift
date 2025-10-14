//
//  XTweetModel.swift
//  XCloneApp
//
//  Created by Abhay Curam on 9/28/25.
//

/**
 * Data model encapsulating a user tweet on X.
 * Encapsulates and contains all the information required to display a tweet.
 */
public struct XTweetModel {
    public let text: String
    public let createdTime: String
    public let author: XUserModel?
    public let attachments: [XMediaAttachmentModel]?
}

private struct XTweetModelFactory {
    
    static func createTweets(_ timelineResponseModel: XTimelineResponseModel) -> [XTweetModel] {
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
