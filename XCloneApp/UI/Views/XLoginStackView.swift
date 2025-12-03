//
//  XLoginStackView.swift
//  XClone
//
//  Created by Abhay Curam on 8/18/25.
//

import UIKit

public struct XLoginStackViewSpacingConfig {
    public let topSpacing: CGFloat
    public let subLabelTopSpacing: CGFloat
    public let loginButtonTopSpacing: CGFloat
    public init(_ size: CGSize) {
        let topMultiplier: CGFloat = 0.05
        let subLabelTopMultiplier: CGFloat = 0.0925
        let loginButtonTopMultiplier: CGFloat = 0.2
        topSpacing = topMultiplier * size.height
        subLabelTopSpacing = subLabelTopMultiplier * size.height
        loginButtonTopSpacing = loginButtonTopMultiplier * size.height
    }
}

public struct XLoginStackViewModel {
    public let loginViewModel: XLoginViewModel
    public let spacingConfig: XLoginStackViewSpacingConfig
}

public protocol XLoginStackViewDelegate: AnyObject {
    func loginStackViewDidTapLoginButton(_ loginView: XLoginStackView)
}

/**
 * A custom container view (XLoginStackView) that can be used to display
 * a simple X logo icon, subheader text, and a login button for a X
 * login experience. The container view leverages auto-layout and a UIStackView.
 */
public class XLoginStackView: UIView {

    public var delegate: XLoginStackViewDelegate?

    public var loginStackViewModel: XLoginStackViewModel {
        didSet {
            subHeaderLabel.text = loginStackViewModel.loginViewModel.subHeaderText
            loginButton.setTitle(loginStackViewModel.loginViewModel.loginButtonText, for: .normal)
            loginButton.setTitle(loginStackViewModel.loginViewModel.loginButtonText, for: .disabled)
            setupStackViewSpacing()
        }
    }
    
    public var shouldEnableLoginButton: Bool = true {
        didSet {
            loginButton.isEnabled = shouldEnableLoginButton
        }
    }

    private struct Constants {
        static let logoImageName = "x-large-logo-icon"
        static let subHeaderLabelPadding: CGFloat = 40
    }

    private lazy var xLogoImageView: UIImageView = {
        let logoImage = UIImage(named: Constants.logoImageName)
        let logoImageView = UIImageView(image: logoImage)
        logoImageView.tintColor = UIColor.white
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        return logoImageView
    }()

    private lazy var subHeaderLabel: UILabel = {
        let subHeaderLabel = UILabel()
        subHeaderLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        subHeaderLabel.numberOfLines = 0
        subHeaderLabel.textColor = UIColor.white
        subHeaderLabel.lineBreakMode = .byWordWrapping
        subHeaderLabel.textAlignment = .center
        subHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        return subHeaderLabel
    }()

    private lazy var loginButton: UIButton = {
        let loginButton = UIButton(type: .system)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 36, weight: .semibold)
        loginButton.setTitleColor(UIColor.white, for: .normal)
        loginButton.setTitleColor(UIColor.darkGray, for: .disabled)
        loginButton.addTarget(self, action: #selector(loginButtonTapped(_:)), for: .touchUpInside)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        return loginButton
    }()
    
    /**
     * Pure Auto-Layout instead of a StackView would have been cleaner.
     * UIStackView really didn't help us much.
     */
    private lazy var loginStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.addArrangedSubview(xLogoImageView)
        stackView.addArrangedSubview(subHeaderLabel)
        stackView.addArrangedSubview(loginButton)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    // MARK: Public Init
    public init(frame: CGRect,
                loginStackViewModel: XLoginStackViewModel,
                delegate: XLoginStackViewDelegate?) {
        self.loginStackViewModel = loginStackViewModel
        self.delegate = delegate
        super.init(frame: frame)
        addSubview(loginStackView)
        setupConstraints()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupStackViewSpacing() {
        loginStackView.setCustomSpacing(loginStackViewModel.spacingConfig.subLabelTopSpacing, after: xLogoImageView)
        loginStackView.setCustomSpacing(loginStackViewModel.spacingConfig.loginButtonTopSpacing, after: subHeaderLabel)
        loginStackView.layoutMargins.top = loginStackViewModel.spacingConfig.topSpacing
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            loginStackView.topAnchor.constraint(equalTo: topAnchor),
            loginStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            loginStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            loginStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            subHeaderLabel.leadingAnchor.constraint(equalTo: loginStackView.leadingAnchor,
                                                    constant: Constants.subHeaderLabelPadding),
            subHeaderLabel.trailingAnchor.constraint(equalTo: loginStackView.trailingAnchor,
                                                     constant: -Constants.subHeaderLabelPadding)
        ])
    }
    
    // MARK: XLoginViewDelegate
    @objc private func loginButtonTapped(_ sender: UIButton) {
        delegate?.loginStackViewDidTapLoginButton(self)
    }

}
