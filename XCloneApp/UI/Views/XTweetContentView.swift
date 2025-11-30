//
//  XTweetContentView.swift
//  XCloneApp
//
//  Created by Abhay Curam on 10/21/25.
//

import UIKit
import AVFoundation

/**
 * Convenience class for grouping together an image download request and
 * it's backing UIImageView for render/display.
 */
private class XTweetContentImageLoadContext {
    var displayImageView: UIImageView
    var imageDownload: ImageDownloadRequest?
    init(_ imageView: UIImageView) {
        self.displayImageView = imageView
    }
}

/**
 * A custom UIView subclass that display's the content of a tweet. This includes the
 * tweet's text truncated to two lines and a dynamic "stack" of image media "ScaleAspectFitted"
 * to the View's bounding box. The height of this UIView is computed by the XTweetContentViewModel.
 */
public class XTweetContentView: UIView, XTweetContentViewModelSizeThatFits {
    
    public var viewModel: XTweetContentViewModel? {
        didSet {
            tweetTextLabel.text = viewModel?.tweetText
            var mediaImageLoads: [XTweetContentImageLoadContext] = []
            if let mediaAttachments = viewModel?.mediaAttachments {
                for mediaAttachment in mediaAttachments {
                    let mediaURI: String? = mediaAttachment.uri ?? mediaAttachment.previewImageUri
                    let mediaImageView = createTweetImageView(mediaAttachment.width, mediaAttachment.height)
                    var mediaImageLoadContext = XTweetContentImageLoadContext(mediaImageView)
                    if let imageURI = mediaURI {
                        mediaImageLoadContext.imageDownload = ImageDownloadRequest(imageURI) { image in
                            mediaImageLoadContext.displayImageView.image = image
                            mediaImageLoadContext.imageDownload = nil
                        }
                    }
                    mediaImageLoads.append(mediaImageLoadContext)
                }
            }
            tweetImageLoadContexts = mediaImageLoads
        }
    }
    
    public var imageDownloader: ImageDownloadRequestManager?
    
    private let tweetTextLabelFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
    private let tweetContentVerticalInterItemSpacing: CGFloat = 11.0
    
    private lazy var tweetTextLabel: UILabel = {
        let tweetTextLabel = UILabel()
        tweetTextLabel.font = tweetTextLabelFont
        tweetTextLabel.numberOfLines = 2
        tweetTextLabel.lineBreakMode = .byTruncatingTail
        tweetTextLabel.textColor = UIColor.black
        return tweetTextLabel
    }()
    
    private var tweetImageLoadContexts: [XTweetContentImageLoadContext] {
        didSet {
            let previousImageLoadContexts = oldValue
            for previousImageLoadContext in previousImageLoadContexts {
                previousImageLoadContext.displayImageView.removeFromSuperview()
                if let downloader = imageDownloader, let previousImageDownload = previousImageLoadContext.imageDownload {
                    downloader.cancelRequest(previousImageDownload)
                }
            }
            for newImageLoadContext in tweetImageLoadContexts {
                addSubview(newImageLoadContext.displayImageView)
                if let downloader = imageDownloader, let newImageDownload = newImageLoadContext.imageDownload {
                    downloader.addRequest(newImageDownload)
                }
            }
        }
    }
    
    public override init(frame: CGRect) {
        self.tweetImageLoadContexts = []
        super.init(frame: frame)
        addSubview(tweetTextLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        let tweetTextLabelHeight = tweetTextLabelFont.lineHeight * 2
        tweetTextLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: tweetTextLabelHeight)
        if let contentViewModel = viewModel, !tweetImageLoadContexts.isEmpty {
            var imageIndex = 0
            var imageViewOriginY = tweetTextLabelHeight + tweetContentVerticalInterItemSpacing
            let boundingSize = CGSize(width: bounds.width, height: bounds.height - tweetTextLabelHeight)
            let boundingRect = CGRect(origin: .zero, size: boundingSize)
            for mediaAttachment in contentViewModel.mediaAttachments {
                let imageView = tweetImageLoadContexts[imageIndex].displayImageView
                let idealImageSize = CGSize(width: mediaAttachment.width, height: mediaAttachment.height)
                let aspectFittedImageRect = AVMakeRect(aspectRatio: idealImageSize, insideRect: boundingRect)
                imageView.frame = CGRect(origin: CGPoint(x: 0, y: imageViewOriginY), size: aspectFittedImageRect.size)
                imageViewOriginY += aspectFittedImageRect.height + tweetContentVerticalInterItemSpacing
                imageIndex += 1
            }
        }
    }
    
    public func sizeThatFitsContentViewModel(_ tweetContentViewModel: XTweetContentViewModel,
                                             _ size: CGSize) -> CGSize {
        let tweetTextLabelHeight = tweetTextLabelFont.lineHeight * 2
        var boundingHeight: CGFloat = tweetTextLabelHeight
        for mediaAttachment in tweetContentViewModel.mediaAttachments {
            let idealImageSize = CGSize(width: mediaAttachment.width, height: mediaAttachment.height)
            let imageBoundingRect = CGRect(origin: .zero, size: size)
            let aspectFittedImageRect = AVMakeRect(aspectRatio: idealImageSize, insideRect: imageBoundingRect)
            boundingHeight += (tweetContentVerticalInterItemSpacing + aspectFittedImageRect.height)
        }
        return CGSize(width: size.width, height: boundingHeight)
    }
    
    private func createTweetImageView(_ width: Int, _ height: Int) -> UIImageView {
        let imageSize = CGSize(width: width, height: height)
        let imageView = UIImageView(frame: CGRect(origin: .zero, size: imageSize))
        imageView.backgroundColor = UIColor.systemGray
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        return imageView
    }
    
}
