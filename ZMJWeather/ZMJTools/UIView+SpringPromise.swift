//
//  UIView+SpringPromise.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/7/3.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit.UIView
import PromiseKit

extension UIView {
    public class func promise(withDuration duration: TimeInterval, delay: TimeInterval, usingSpringWithDamping dampingRatio: CGFloat, initialSpringVelocity velocity: CGFloat, options: UIViewAnimationOptions = [], animations: @escaping () -> Void) -> Promise<Bool> {
        return wrap {animate(withDuration: duration, delay: delay, usingSpringWithDamping: dampingRatio, initialSpringVelocity: velocity, options: options, animations: animations, completion: $0)}
    }
}
