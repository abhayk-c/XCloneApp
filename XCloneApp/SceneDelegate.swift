//
//  SceneDelegate.swift
//  XClone
//
//  Created by Abhay Curam on 8/18/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, XLoginViewControllerDelegate {

    var window: UIWindow?
    let authenticationService: XAuthenticationService
    let userIdentityService: XUserIdentityService
    let tokenStore: XSecureKeychainTokenStore
    let userSession: XUserSession

    override init() {
        authenticationService = XAuthenticationService()
        userIdentityService = XUserIdentityService()
        tokenStore = XSecureKeychainTokenStore()
        userSession = XUserSession(authenticationService, userIdentityService, tokenStore)
        super.init()
    }
    
    // MARK: SceneDelegate Life Cycle
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = createTabBarController()
        self.window = window
        window.makeKeyAndVisible()
    }

    // MARK: XLoginViewControllerDelegate
    func loginViewControllerDidAuthenticateUser(_ userSession: XUserSession) {
        
    }

    func loginViewControllerUserAuthenticationFailed(_ error: XAuthenticationError?) {
        // no op
    }

    func loginViewControllerUserAuthenticationCancelled() {
        // no op
    }
    
    // MARK: Private Helpers
    private func createLoginViewController() -> XLoginViewController {
        let loginViewModel = XLoginViewModel(subHeaderText: "See what's happening in the world right now.",
                                             loginButtonText: "Log in")
        let loginViewController = XLoginViewController(userSession, self, authenticationService, loginViewModel)
        return loginViewController
    }
    
    private func createTabBarController() -> UITabBarController {
        let tabBarViewController = UITabBarController()
        tabBarViewController.viewControllers = [createFeedNavigationController()]
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
        let feedViewController = UIViewController()
        feedViewController.view.backgroundColor = UIColor.white
        feedViewController.navigationItem.title = "Feed"
        let navigationController = UINavigationController(rootViewController: feedViewController)
        navigationController.tabBarItem.image = UIImage(named: "home-unselected-tab-bar-icon")
        navigationController.tabBarItem.selectedImage = UIImage(named: "home-selected-tab-bar-icon")
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        navigationController.navigationBar.standardAppearance = navigationBarAppearance
        navigationController.navigationBar.compactAppearance = navigationBarAppearance
        navigationController.navigationBar.compactScrollEdgeAppearance = navigationBarAppearance
        return navigationController
    }

}
