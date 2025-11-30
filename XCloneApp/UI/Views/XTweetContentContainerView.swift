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
public class XTweetContentContainerView: UIView, XTweetContentViewModelSizeThatFits {
    
    public var viewModel: XTweetContentContainerViewModel? {
        didSet {
            tweetHeaderView.viewModel = viewModel?.headerViewModel
            tweetContentView.viewModel = viewModel?.contentViewModel
            profileBadgeImageURI = viewModel?.headerViewModel.profileImageURI
        }
    }
    
    public var imageDownloader: ImageDownloadRequestManager? {
        didSet {
            tweetContentView.imageDownloader = imageDownloader
        }
    }
    
    private var profileBadgeImageDownloadRequest: ImageDownloadRequest?
    
    private var profileBadgeImageURI: String? {
        didSet {
            if let outstandingImageDownloadRequest = profileBadgeImageDownloadRequest {
                imageDownloader?.cancelRequest(outstandingImageDownloadRequest)
                profileBadgeImageDownloadRequest = nil
            }
            if let imageUri = profileBadgeImageURI {
                let newImageDownloadRequest = ImageDownloadRequest(imageUri, { [weak self] image in
                    if let strongSelf = self {
                        strongSelf.profileBadgeImageView.image = image
                        strongSelf.profileBadgeImageDownloadRequest = nil
                    }
                })
                profileBadgeImageDownloadRequest = newImageDownloadRequest
                imageDownloader?.addRequest(newImageDownloadRequest)
            }
        }
    }
    
    private let profileBadgeImageViewSize: CGFloat = 36
    private let contentContainerBottomPadding: CGFloat = 20
    private let tweetContentViewTopSpacing: CGFloat = 10
    private let tweetHeaderLeftSpacing: CGFloat = 22
    private let profileBadgeImageViewRightSpacing: CGFloat = 8
    private let profileBadgeImageViewOriginX: CGFloat = 13
    private let profileBadgeImageViewOriginY: CGFloat = 23
    private let tweetHeaderViewOriginY: CGFloat = 25
    
    private lazy var profileBadgeImageView: UIImageView = {
        let fixedSize: CGFloat = profileBadgeImageViewSize
        let profileBadgeImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: fixedSize, height: fixedSize))
        profileBadgeImageView.layer.cornerRadius = fixedSize / 2
        profileBadgeImageView.clipsToBounds = true
        profileBadgeImageView.backgroundColor = UIColor.systemGray
        return profileBadgeImageView
    }()
    
    private let tweetHeaderView: XTweetHeaderView = XTweetHeaderView(frame: .zero)
    private let tweetContentView: XTweetContentView = XTweetContentView(frame: .zero)
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(profileBadgeImageView)
        addSubview(tweetHeaderView)
        addSubview(tweetContentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        profileBadgeImageView.frame = CGRect(x: profileBadgeImageViewOriginX,
                                             y: profileBadgeImageViewOriginY,
                                             width: profileBadgeImageViewSize,
                                             height: profileBadgeImageViewSize)
        
        let tweetHeaderViewOriginX = getTweetHeaderViewOriginX()
        let tweetHeaderViewHeight = tweetHeaderView.sizeThatFits(bounds.size).height
        let tweetHeaderViewWidth = bounds.width - tweetHeaderViewOriginX - tweetHeaderLeftSpacing
        tweetHeaderView.frame = CGRect(x: tweetHeaderViewOriginX,
                                       y: tweetHeaderViewOriginY,
                                       width: tweetHeaderViewWidth,
                                       height: tweetHeaderViewHeight)
        
        let tweetContentViewOriginX = tweetHeaderViewOriginX
        let tweetContentViewOriginY = tweetHeaderViewOriginY + tweetHeaderViewHeight + tweetContentViewTopSpacing
        let tweetContentViewHeight = bounds.size.height - tweetContentViewOriginY - contentContainerBottomPadding
        let tweetContentViewWidth = tweetHeaderViewWidth
        tweetContentView.frame = CGRect(x: tweetContentViewOriginX,
                                        y: tweetContentViewOriginY,
                                        width: tweetContentViewWidth,
                                        height: tweetContentViewHeight)
    }
    
    public func sizeThatFitsContentViewModel(_ tweetContentViewModel: XTweetContentViewModel,
                                             _ size: CGSize) -> CGSize {
        let headerViewHeight = tweetHeaderView.sizeThatFits(size).height
        let tweetHeaderViewWidth = size.width - getTweetHeaderViewOriginX() - tweetHeaderLeftSpacing
        let tweetContentViewWidth = tweetHeaderViewWidth
        let tweetContentViewSize = CGSize(width: tweetContentViewWidth, height: size.height)
        let tweetContentViewHeight = tweetContentView.sizeThatFitsContentViewModel(tweetContentViewModel,
                                                                                   tweetContentViewSize).height
        let contentContainerHeight = tweetHeaderViewOriginY + headerViewHeight + tweetContentViewTopSpacing + tweetContentViewHeight + contentContainerBottomPadding
        return CGSize(width: size.width, height: contentContainerHeight)
    }
    
    private func getTweetHeaderViewOriginX() -> CGFloat {
        return profileBadgeImageViewOriginX + profileBadgeImageViewSize + profileBadgeImageViewRightSpacing
    }
    
}
