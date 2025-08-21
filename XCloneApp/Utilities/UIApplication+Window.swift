//
//  Untitled.swift
//  XCloneApp
//
//  Created by Abhay Curam on 8/20/25.
//

import UIKit

extension UIApplication {
    
    public var currentSceneDelegateWindow: UIWindow? {
        guard let windowScene = connectedScenes.first as? UIWindowScene else { return nil }
        guard let sceneDelegate = windowScene.delegate as? SceneDelegate else { return nil }
        return sceneDelegate.window
    }
    
}
