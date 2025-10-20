//
//  XTweetHeaderView.swift
//  XCloneApp
//
//  Created by Abhay Curam on 10/19/25.
//

import UIKit

/**
 * A custom UIView subclass used to render a tweet's header information.
 * Diplays the tweet author's userHandle, and the date the tweet was posted.
 */
public class XTweetHeaderView: UIView {
    
    public var viewModel: XTweetHeaderViewModel? {
        didSet {
            userNameLabel.text = viewModel?.userNameText
            dateLabel.text = viewModel?.postedDateText
        }
    }
    
    private let userNameLabelFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
    private let userNameLabelColor = UIColor.black
    private let dateLabelFont = UIFont.systemFont(ofSize: 12, weight: .bold)
    private let dateLabelColor = UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 1.0)
    private let interLabelSpacing = 3.0
    
    private lazy var userNameLabel: UILabel = {
        let userNameLabel = UILabel()
        userNameLabel.font = userNameLabelFont
        userNameLabel.textColor = userNameLabelColor
        userNameLabel.lineBreakMode = .byTruncatingTail
        userNameLabel.numberOfLines = 1
        return userNameLabel
    }()
    
    private lazy var dateLabel: UILabel = {
        let dateLabel = UILabel()
        dateLabel.font = dateLabelFont
        dateLabel.textColor = dateLabelColor
        dateLabel.lineBreakMode = .byTruncatingTail
        dateLabel.numberOfLines = 1
        return dateLabel
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(userNameLabel)
        addSubview(dateLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        super.layoutSubviews()
        let stackedLabelsHeight = userNameLabelFont.lineHeight + dateLabelFont.lineHeight + interLabelSpacing
        return CGSize(width: size.width, height: stackedLabelsHeight)
    }
    
    public override func layoutSubviews() {
        userNameLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: userNameLabelFont.lineHeight)
        let dateLabelOriginY = userNameLabelFont.lineHeight + interLabelSpacing
        dateLabel.frame = CGRect(x: 0, y: dateLabelOriginY, width: bounds.width, height: dateLabelFont.lineHeight)
    }
    
}
