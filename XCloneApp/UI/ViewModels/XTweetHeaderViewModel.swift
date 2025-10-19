//
//  XTweetHeaderViewModel.swift
//  XCloneApp
//
//  Created by Abhay Curam on 10/18/25.
//

import Foundation

public struct XTweetHeaderViewModel {
    let userNameText: String
    let postedDateText: String
    let profileImageURI: String?
}

public struct XTweetHeaderViewModelFactory: XViewModelFactory {
    
    public typealias InputModel = XTweetModel
    public typealias ViewModel = XTweetHeaderViewModel
    
    public static func createViewModel(_ inputModel: XTweetModel) -> XTweetHeaderViewModel {
        let postedDateFormattedText = XTweetHeaderViewModelFactory.getPostedDateFormattedText(inputModel.createdTime)
        var profileImageURI: String?
        var userNameText: String = ""
        if let userNameHandle = inputModel.author?.username, let profileBadgeURI = inputModel.author?.profileImageUri {
            userNameText = "@" + userNameHandle
            profileImageURI = profileBadgeURI
        }
        return XTweetHeaderViewModel(userNameText: userNameText,
                                     postedDateText: postedDateFormattedText,
                                     profileImageURI: profileImageURI)
    }
    
    private static func getPostedDateFormattedText(_ createdTimeUTC: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let utcDate = isoFormatter.date(from: createdTimeUTC) else { return "" }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .long
        displayFormatter.timeStyle = .short
        displayFormatter.locale = .current
        displayFormatter.timeZone = .current
        return displayFormatter.string(from: utcDate)
    }
    
}
