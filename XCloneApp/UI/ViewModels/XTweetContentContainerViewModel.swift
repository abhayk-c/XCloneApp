//
//  XTweetContentContainerViewModel.swift
//  XCloneApp
//
//  Created by Abhay Curam on 10/18/25.
//

import Foundation

public struct XTweetContentContainerViewModel {
    public let headerViewModel: XTweetHeaderViewModel
    public let contentViewModel: XTweetContentViewModel
}

public struct XTweetContentContainerViewModelFactory: XViewModelFactory {
    
    public typealias InputModel = XTweetModel
    public typealias ViewModel = XTweetContentContainerViewModel
    
    public static func createViewModel(_ inputModel: XTweetModel) -> XTweetContentContainerViewModel {
        let tweetHeaderViewModel = XTweetHeaderViewModelFactory.createViewModel(inputModel)
        let tweetContentViewModel = XTweetContentViewModelFactory.createViewModel(inputModel)
        return XTweetContentContainerViewModel(headerViewModel: tweetHeaderViewModel,
                                               contentViewModel: tweetContentViewModel)
    }
    
}
