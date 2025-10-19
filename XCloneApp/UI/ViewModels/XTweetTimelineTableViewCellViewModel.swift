//
//  XTimelineTweetCellViewModel.swift
//  XCloneApp
//
//  Created by Abhay Curam on 10/18/25.
//

import Foundation

public struct XTweetTimelineTableViewCellViewModel {
    public let headerViewModel: XTweetHeaderViewModel
    public let contentViewModel: XTweetContentViewModel
}

public struct XTweetTimelineTableViewCellViewModelFactory: XViewModelFactory {
    
    public typealias InputModel = XTweetModel
    public typealias ViewModel = XTweetTimelineTableViewCellViewModel
    
    public static func createViewModel(_ inputModel: XTweetModel) -> XTweetTimelineTableViewCellViewModel {
        let tweetHeaderViewModel = XTweetHeaderViewModelFactory.createViewModel(inputModel)
        let tweetContentViewModel = XTweetContentViewModelFactory.createViewModel(inputModel)
        return XTweetTimelineTableViewCellViewModel(headerViewModel: tweetHeaderViewModel,
                                                    contentViewModel: tweetContentViewModel)
    }
    
}
