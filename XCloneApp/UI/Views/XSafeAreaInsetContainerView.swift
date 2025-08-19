//
//  SafeAreaInsetContainerView.swift
//  XClone
//
//  Created by Abhay Curam on 8/18/25.
//

import UIKit

/**
 * A helpful container view for laying out view's safely
 * and respecting the iPhone's window safe area insets.
 */
public class XSafeAreaInsetContainerView : UIView {
    
    private var childView: UIView
    
    public init(frame: CGRect, childView: UIView) {
        self.childView = childView
        super.init(frame: frame)
        addSubview(self.childView)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        let adjustedWidth = bounds.width - safeAreaInsets.left - safeAreaInsets.right
        let adjustedHeight = bounds.height - safeAreaInsets.top - safeAreaInsets.bottom
        childView.frame = CGRectMake(safeAreaInsets.left, safeAreaInsets.top, adjustedWidth, adjustedHeight)
    }
    
}
