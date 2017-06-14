//
//  ZMJWeahterHolderController.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/6/14.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit

class ZMJWeahterHolderController: UIViewController {

    @IBOutlet weak var topBarView: UIView!
    
    let contentView:UIScrollView = UIScrollView.init()
    var editLocationController:ZMJEditLocationController {
        return (self.navigationController as! ZMJWeatherNavController).locationController
    }
    var tapGesture:UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSubViews()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func initSubViews() {
        tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(showEditLocation(_:)))

        weak var weakSelf = self
        _ = locationManager.locations(queue: DispatchQueue.main).then { (locations) -> Void in
            weakSelf?.contentView.frame = CGRect.init(x: 0, y: 0, width: (weakSelf?.view.frame.width)!, height: (weakSelf?.view.frame.height)!);
            weakSelf?.contentView.contentSize = CGSize.init(width: (weakSelf?.view.frame.width)! * CGFloat(locations.count + 1), height: (weakSelf?.view.frame.height)!)
            weakSelf?.contentView.isPagingEnabled = true;
            weakSelf?.contentView.showsHorizontalScrollIndicator = false
            weakSelf?.contentView.showsVerticalScrollIndicator = false
            weakSelf?.view.insertSubview((weakSelf?.contentView)!, at: 0)
            
            let controller = ZMJWeatherDetailController()
            controller.view.frame = CGRect.init(x: 0, y: 0, width: (weakSelf?.view.frame.width)!, height: (weakSelf?.view.frame.height)!)
            weakSelf?.addChildViewController(controller)
            weakSelf?.contentView.addSubview(controller.view)
        
            for (index, location) in locations.enumerated() {
                let controller = ZMJWeatherDetailController()
                controller.locationInfo = location;
                controller.view.frame = CGRect.init(x: (weakSelf?.view.frame.width)! * CGFloat(index + 1), y: 0, width: (weakSelf?.view.frame.width)!, height: (weakSelf?.view.frame.height)!)
                weakSelf?.addChildViewController(controller)
                weakSelf?.contentView.addSubview(controller.view)
            }
        }
    }
    
    @IBAction func showEditLocation(_ sender: Any) {
        (self.navigationController as! ZMJWeatherNavController).showEditLocation { (show) in
            if show {
                self.view.addGestureRecognizer(self.tapGesture)
            } else {
                self.view.removeGestureRecognizer(self.tapGesture)
            }
        }
        editLocationController.deleteAddress = {(locationInfo) in
            
        }
        editLocationController.selectAddress = {(locationInfo) in
            
        }
        editLocationController.defaultAddress = {(locationInfo) in
            
        }
    }
    
    @IBAction func showAddLocation(_ sender: Any) {
        let controller:ZMJAddLocationController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ZMJAddLocationController") as! ZMJAddLocationController
        controller.addAddress = {(locationInfo) in
            
        }
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
