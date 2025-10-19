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
public struct XTweetModel: Hashable {
    public let id: String
    public let tweetText: String
    public let createdTime: String
    public let author: XUserModel?
    public let attachments: [XMediaAttachmentModel]?
}
