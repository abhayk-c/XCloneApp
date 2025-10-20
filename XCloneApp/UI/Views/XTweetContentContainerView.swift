//
//  XTweetContentContainerView.swift
//  XCloneApp
//
//  Created by Abhay Curam on 10/19/25.
//

import UIKit

/**
 * A custom UIView subclass that serves as the main content container view
 * for rendering tweet data. XTweetContentContainerView display's and lays out
 * a tweet's header, its content (text and media), along with a profile badge.
 */
public class XTweetContentContainerView: UIView {
    
    public var viewModel: XTweetContentContainerViewModel? {
        didSet {
            tweetHeaderView.viewModel = viewModel?.headerViewModel
        }
    }
    
    private let profileBadgeImageViewSize: CGFloat = 36
    private let tweetHeaderViewOriginY: CGFloat = 25
    private let contentContainerBottomPadding: CGFloat = 20
    
    private lazy var profileBadgeImageView: UIImageView = {
        let fixedSize: CGFloat = profileBadgeImageViewSize
        let profileBadgeImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: fixedSize, height: fixedSize))
        profileBadgeImageView.layer.cornerRadius = fixedSize / 2
        profileBadgeImageView.clipsToBounds = true
        profileBadgeImageView.backgroundColor = UIColor.systemGray
        return profileBadgeImageView
    }()
    
    private let tweetHeaderView: XTweetHeaderView = XTweetHeaderView(frame: .zero)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(profileBadgeImageView)
        addSubview(tweetHeaderView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let profileBadgeImageViewOriginX: CGFloat = 13
        let profileBadgeImageViewOriginY: CGFloat = 23
        profileBadgeImageView.frame = CGRect(x: profileBadgeImageViewOriginX,
                                             y: profileBadgeImageViewOriginY,
                                             width: profileBadgeImageViewSize,
                                             height: profileBadgeImageViewSize)
        
        let profileBadgeRightSpacing: CGFloat = 8
        let tweetHeaderLeftSpacing: CGFloat = 22
        let tweetHeaderViewOriginX = profileBadgeImageViewOriginX + profileBadgeImageViewSize + profileBadgeRightSpacing
        let tweetHeaderViewHeight = tweetHeaderView.sizeThatFits(bounds.size).height
        tweetHeaderView.frame = CGRect(x: tweetHeaderViewOriginX,
                                       y: tweetHeaderViewOriginY,
                                       width: bounds.width - tweetHeaderViewOriginX - tweetHeaderLeftSpacing,
                                       height: tweetHeaderViewHeight)
        
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let headerViewHeight = tweetHeaderView.sizeThatFits(size).height
        let contentContainerHeight = tweetHeaderViewOriginY + headerViewHeight + contentContainerBottomPadding
        return CGSize(width: size.width, height: contentContainerHeight)
    }
    
}
