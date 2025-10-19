//
//  XTweet.swift
//  XCloneApp
//
//  Created by Abhay Curam on 10/18/25.
//

public struct XTweetContentViewModel {
    let tweetText: String
    let mediaAttachments: [XMediaAttachmentModel]
}

public struct XTweetContentViewModelFactory: XViewModelFactory {
    
    public typealias InputModel = XTweetModel
    public typealias ViewModel = XTweetContentViewModel
    
    public static func createViewModel(_ inputModel: XTweetModel) -> XTweetContentViewModel {
        // Only supporting photo at the moment.
        let filteredAttachments = inputModel.attachments?.filter { $0.mediaType == .photo } ?? []
        return XTweetContentViewModel(tweetText: inputModel.tweetText, mediaAttachments: filteredAttachments)
    }
}
