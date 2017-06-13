//
//  ZMJWeaterNavigation.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/6/12.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit

class ZMJWeatherNavController: UINavigationController, UIGestureRecognizerDelegate, UINavigationControllerDelegate {
    var locationController:ZMJEditLocationController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ZMJEditLocationController") as! ZMJEditLocationController
    private var locationShow:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.red
        self.viewControllers.insert(locationController, at: 0)
        self.view.insertSubview(locationController.view, at: 0)
//        self.interactivePopGestureRecognizer?.delegate = self
//        self.delegate = self;
    }
    
    func showEditLocation(complete: ((_ show:Bool)-> Void)!) {
        let view:UIView = self.viewControllers.last!.view
        if complete != nil {
            complete(!self.locationShow)
        }
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            view.frame = CGRect.init(origin: CGPoint.init(x: view.frame.width * (self.locationShow ? 0.0 : 0.8), y: 0), size: view.frame.size)
            self.locationShow = !self.locationShow
        }) { (result) in
            print("")
        }
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        self.interactivePopGestureRecognizer?.isEnabled = false
        super.pushViewController(viewController, animated: animated)
    }
    
    
    override func popViewController(animated: Bool) -> UIViewController? {
        self.interactivePopGestureRecognizer?.isEnabled = false
        return super.popViewController(animated: animated)
    }
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        self.interactivePopGestureRecognizer?.isEnabled = false
        return super.popToRootViewController(animated: animated)
    }
    
    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        return super.popToViewController(viewController, animated: animated)
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if self.viewControllers.count > 1 {
            self.interactivePopGestureRecognizer?.isEnabled = true;
        } else {
            self.interactivePopGestureRecognizer?.isEnabled = false;
        }
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if self.viewControllers.count == 1 {
            return false
        }
        return true
    }
    
    func showViewControllerFromBelow(viewController: UIViewController) {
        self.viewControllers.insert(viewController, at: 0)
        self.view.insertSubview(viewController.view, at: 0)
        let view:UIView = self.viewControllers.last!.view
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            view.frame = CGRect.init(origin: CGPoint.init(x: view.frame.width * 0.8, y: 0), size: view.frame.size)
        }, completion: nil)
    }
    
    func hideViewControllerFromBelow(viewController: UIViewController) {
        let view:UIView = self.viewControllers.last!.view
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
            view.frame = CGRect.init(origin: CGPoint.init(x: 0, y: 0), size: view.frame.size)
        }) { (result) in
            viewController.removeFromParentViewController()
            viewController.view.removeFromSuperview()
        }
    }
}

/*
 //
 //  ZMJWeaterNavigation.swift
 //  ZMJWeather
 //
 //  Created by zhangheng on 2017/6/12.
 //  Copyright © 2017年 zhangheng. All rights reserved.
 //
 
 import UIKit
 
 class ZMJWeatherNavController: UINavigationController {
 override func didReceiveMemoryWarning() {
 super.didReceiveMemoryWarning()
 // Dispose of any resources that can be recreated.
 }
 
 func showViewControllerFromBelow(viewController: UIViewController) {
 self.viewControllers.insert(viewController, at: 0)
 self.view.insertSubview(viewController.view, at: 0)
 let view:UIView = self.viewControllers.last!.view
 UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
 view.frame = CGRect.init(origin: CGPoint.init(x: view.frame.width * 0.8, y: 0), size: view.frame.size)
 }, completion: nil)
 }
 
 func hideViewControllerFromBelow(viewController: UIViewController) {
 let view:UIView = self.viewControllers.last!.view
 UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
 view.frame = CGRect.init(origin: CGPoint.init(x: 0, y: 0), size: view.frame.size)
 }) { (result) in
 viewController.removeFromParentViewController()
 viewController.view.removeFromSuperview()
 }
 }
 }

 */
