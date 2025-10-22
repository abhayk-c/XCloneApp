//
//  XTweetContentView.swift
//  XCloneApp
//
//  Created by Abhay Curam on 10/21/25.
//

import UIKit

public class XTweetContentView: UIView {
    
    public var viewModel: XTweetContentViewModel? {
        didSet {
            tweetTextLabel.text = viewModel?.tweetText
        }
    }
    
    private let tweetTextLabelFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
    
    private lazy var tweetTextLabel: UILabel = {
        let tweetTextLabel = UILabel()
        tweetTextLabel.font = tweetTextLabelFont
        tweetTextLabel.numberOfLines = 2
        tweetTextLabel.lineBreakMode = .byTruncatingTail
        tweetTextLabel.textColor = UIColor.black
        return tweetTextLabel
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tweetTextLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        tweetTextLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: tweetTextLabelFont.lineHeight * 2)
    }
    
}
