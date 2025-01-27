//
//  UIViewController+TopVc.swift
//  Paywall
//
//  Created by Yusuf Tör on 28/02/2022.
//

import UIKit

extension UIViewController {
  static var topMostViewController: UIViewController? {
    var topViewController: UIViewController? = UIApplication.shared.activeWindow?.rootViewController
    while let presentedViewController = topViewController?.presentedViewController {
      topViewController = presentedViewController
    }
    return topViewController
  }
}
