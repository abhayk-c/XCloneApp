//
//  XTweetTimelineTableViewCell.swift
//  XCloneApp
//
//  Created by Abhay Curam on 10/19/25.
//

import UIKit

/**
 * A custom UITableViewCell subclass for displaying a user's tweets in a UITableView.
 * This is used in our XTweetTimelineFeedViewController to display a chronological paginated
 * timeline of a user's tweets. 
 */
public class XTweetTimelineTableViewCell: UITableViewCell {
    
    public var viewModel: XTweetContentContainerViewModel? {
        didSet {
            tweetContentContainerView.viewModel = viewModel
        }
    }
    
    public var imageDownloader: ImageDownloadRequestManager? {
        didSet {
            tweetContentContainerView.imageDownloader = imageDownloader
        }
    }
    
    private let tweetContentContainerView: XTweetContentContainerView
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        tweetContentContainerView = XTweetContentContainerView(frame: .zero)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(tweetContentContainerView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        tweetContentContainerView.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height)
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let contentContainerViewHeight = tweetContentContainerView.sizeThatFits(size).height
        return CGSize(width: size.width, height: contentContainerViewHeight)
    }
    
}
