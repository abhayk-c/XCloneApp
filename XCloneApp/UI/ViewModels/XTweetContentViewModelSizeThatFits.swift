//
//  XTweetContentViewModelSizeThatFits.swift
//  XCloneApp
//
//  Created by Abhay Curam on 11/29/25.
//

import UIKit

/**
 * A protocol for UI Component's to size themselves based off of a XTweetContentViewModel.
 */
public protocol XTweetContentViewModelSizeThatFits {
    func sizeThatFitsContentViewModel(_ tweetContentViewModel: XTweetContentViewModel,
                                      _ size: CGSize) -> CGSize
}
