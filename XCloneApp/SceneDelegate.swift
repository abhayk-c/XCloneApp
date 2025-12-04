//
//  SceneDelegate.swift
//  XClone
//
//  Created by Abhay Curam on 8/18/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, XLoginViewControllerDelegate {

    var window: UIWindow?
    private let authenticationService = XAuthenticationService()
    private let userIdentityService = XUserIdentityService()
    private let tokenStore = XSecureKeychainTokenStore()
    private let imageDownloader = ImageDownloadRequestManager()
    
    private lazy var userSession: XUserSession = {
        return XUserSession(authenticationService, userIdentityService, tokenStore)
    }()
    
    private lazy var tweetTimelineService: XTweetTimelineService = {
        return XTweetTimelineService(userSession, 100)
    }()
    
    private lazy var loginViewController: XLoginViewController = {
        return createLoginViewController()
    }()
    
    private lazy var tabBarController: UITabBarController = {
        return createTabBarController()
    }()
    
    private struct Constants {
        static let loginHeaderText = "See what's happening in the world right now."
        static let loginButtonText = "Log in"
        static let tabBarFeedIconImageName = "home-unselected-tab-bar-icon"
        static let tabBarFeedIconSelectedImageName = "home-selected-tab-bar-icon"
        static let tabBarSettingsIconImageName = "settings-selected-tab-bar-icon"
        static let tabBarSettingsIconSelectedImageName = "settings-unselected-tab-bar-icon"
    }
    
    // MARK: SceneDelegate Life Cycle
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let sceneWindow = UIWindow(windowScene: windowScene)
        window = sceneWindow
        window?.rootViewController = userSession.didAuthenticate() ? tabBarController : loginViewController
        window?.makeKeyAndVisible()
    }

    // MARK: XLoginViewControllerDelegate
    func loginViewControllerDidAuthenticateUser(_ userSession: XUserSession) {
        window?.rootViewController = tabBarController
    }

    func loginViewControllerUserAuthenticationFailed(_ error: XAuthenticationError?) {
        // no op
    }

    func loginViewControllerUserAuthenticationCancelled() {
        // no op
    }
    
    // MARK: Private Helpers
    private func createLoginViewController() -> XLoginViewController {
        let loginViewModel = XLoginViewModel(subHeaderText: Constants.loginHeaderText,
                                             loginButtonText: Constants.loginButtonText)
        let loginViewController = XLoginViewController(userSession, self, authenticationService, loginViewModel)
        return loginViewController
    }
    
    private func createTabBarController() -> UITabBarController {
        let tabBarViewController = UITabBarController()
        tabBarViewController.viewControllers = [createFeedNavigationController(), createSettingsNavigationController()]
        tabBarViewController.selectedIndex = 0
        let tabBarItemAppearance = UITabBarItemAppearance()
        tabBarItemAppearance.normal.iconColor = UIColor.black
        tabBarItemAppearance.selected.iconColor = UIColor.black
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance
        tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
        tabBarViewController.tabBar.standardAppearance = tabBarAppearance
        tabBarViewController.tabBar.scrollEdgeAppearance = tabBarAppearance
        return tabBarViewController
    }
    
    private func createFeedNavigationController() -> UINavigationController {
        let feedViewController = XTweetTimelineFeedViewController(userSession, tweetTimelineService, imageDownloader)
        return createTabBarEmbeddedNavigationController(feedViewController,
                                                        UIImage(named: Constants.tabBarFeedIconImageName),
                                                        UIImage(named: Constants.tabBarFeedIconSelectedImageName))
    }
    
    private func createSettingsNavigationController() -> UINavigationController {
        let settingsViewController = XSettingsViewController()
        return createTabBarEmbeddedNavigationController(settingsViewController,
                                                        UIImage(named: Constants.tabBarSettingsIconImageName),
                                                        UIImage(named: Constants.tabBarSettingsIconSelectedImageName))
    }
    
    private func createTabBarEmbeddedNavigationController(_ viewController: UIViewController,
                                                          _ tabBarUnselectedImage: UIImage?,
                                                          _ tabBarSelectedImage: UIImage?) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.tabBarItem.image = tabBarUnselectedImage
        navigationController.tabBarItem.selectedImage = tabBarSelectedImage
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        navigationController.navigationBar.standardAppearance = navigationBarAppearance
        navigationController.navigationBar.compactAppearance = navigationBarAppearance
        navigationController.navigationBar.compactScrollEdgeAppearance = navigationBarAppearance
        return navigationController
    }

}
