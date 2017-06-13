//
//  ZMJWeaterController.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/5/29.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit
import PromiseKit
import SnapKit
import MJRefresh

class ZMJWeaterController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var topBarView: UIView!
    
    var detailWeatherView:ZMJDetailWeatherView = ZMJDetailWeatherView()
    var recentWeatherView:ZMJRecentWeatherView = ZMJRecentWeatherView()
    var locationInfo:LocationInfo!
    var editLocationController:ZMJEditLocationController {
        return (self.navigationController as! ZMJWeatherNavController).locationController
    }
    var addLocationController:ZMJAddLocationController = ZMJAddLocationController()
    var tapGesture:UITapGestureRecognizer {
        return UITapGestureRecognizer.init(target: self, action: #selector(showEditLocation(_:)))
    }
    
//    var addressHandlerStart:(@convention(block) ()->Void)!
//    var addressHanderSuccess:(@convention(block) (LocationInfo) -> Void)!
//    var addressHanderError:(@convention(block) (String) -> Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSubView()
        self.detailWeatherView.mj_header.beginRefreshing()
        weak var weakSelf = self
        NotificationCenter.default.observe(once: NSNotification.Name.UIApplicationDidEnterBackground).then { (dictionary) -> Void in
            weakSelf?.detailWeatherView.mj_header.beginRefreshing()
        }.catch { (error) in }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        recentWeatherView.frame = CGRect.init(x: 0.0, y: self.view.frame.height - 85.0, width: self.view.frame.width, height: (self.view.frame.height > 667 ? 667 : self.view.frame.height) * 0.63)
    }
    
    // MARK:自定义方法
    private func initSubView() {
        detailWeatherView.mj_header = MJRefreshStateHeader.init(refreshingBlock: { 
            self.updateWeather()
        })
        (detailWeatherView.mj_header as! MJRefreshStateHeader).lastUpdatedTimeLabel.textColor = UIColor.white
        (detailWeatherView.mj_header as! MJRefreshStateHeader).stateLabel.textColor = UIColor.white
        detailWeatherView.backgroundColor = ColorBlue
        detailWeatherView.alwaysBounceVertical = true
        self.view.insertSubview(detailWeatherView, belowSubview: topBarView)
        detailWeatherView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        let panGesture:UIPanGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(panRecentWeatherView(panGesture:)))
        panGesture.delegate = self
        recentWeatherView.backgroundColor = UIColor.red
        recentWeatherView.addGestureRecognizer(panGesture)
        self.view.addSubview(recentWeatherView)
        
        editLocationInit()
        addLocationInit()
    }
    
    func editLocationInit() {
        editLocationController.deleteAddress = {(locationInfo) in
            
        }
        editLocationController.selectAddress = {(locationInfo) in
            
        }
        editLocationController.defaultAddress = {(locationInfo) in
            
        }
    }
    
    func addLocationInit() {
        addLocationController.addAddress = {(locationInfo) in
            
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
    }
    
    @IBAction func showAddLocation(_ sender: Any) {
        self.navigationController?.pushViewController(UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ZMJAddLocationController"), animated: true)
    }
    
    
    @objc private func updateWeather() {
        (detailWeatherView.mj_header as! MJRefreshStateHeader).stateLabel.text = "正在获取位置信息"
        weak var weakSelf = self
        locationManager.updateLocation().then { (locationInfo) -> Promise<NSDictionary?> in
            weakSelf?.locationInfo = locationInfo
            (weakSelf?.detailWeatherView.mj_header as! MJRefreshStateHeader).stateLabel.text = "正在获取天气状况"
            weakSelf?.detailWeatherView.cityLabel.text = locationInfo.city
            weakSelf?.detailWeatherView.districtLabel.text = locationInfo.district
            return ZMJSingleNet.request(request: ZMJRequest.WeatherAll, method: .get, paths: [], parameters: ["city":(String(locationInfo.longitude) + "," + String(locationInfo.latitude))], form: [:])
        }.then { (todayInfo) -> Void in
            weakSelf?.detailWeatherView.mj_header.endRefreshing()
            let daily_forecast:NSArray! = todayInfo?.value(forKey: "daily_forecast") as! NSArray // 3~10天预报
            let now:NSDictionary! = todayInfo?.value(forKey: "now") as! NSDictionary // 实况天气
            var _:NSArray! = todayInfo?.value(forKey: "hourly_forecast") as! NSArray // 未来每小时天气预报
            var _:NSDictionary! = todayInfo?.value(forKey: "suggestion") as! NSDictionary // 生活指数
            let aqi:NSDictionary! = todayInfo?.value(forKey: "aqi") as! NSDictionary // 空气污染指数
            weakSelf?.recentWeatherView.daily_forecast = daily_forecast
            weakSelf?.detailWeatherView.set(now: now, today: (daily_forecast.firstObject! as? NSDictionary)!, aqi: aqi)
        }.catch { (error) in
            weakSelf?.detailWeatherView.mj_header.endRefreshing()
            print("无法获取地理位置，请检查访问位置权限以及网络状态")
        }
    }
    
    @objc private func panRecentWeatherView(panGesture:UIPanGestureRecognizer) {
        let offset:CGPoint = panGesture.translation(in: panGesture.view)
        panGesture.setTranslation(CGPoint.init(x: 0, y: 0), in: panGesture.view)
        if (recentWeatherView.frame.minY + offset.y) > self.view.frame.height - 85.0 {
            recentWeatherView.frame = CGRect.init(x: 0.0, y:self.view.frame.height - 85.0, width: self.view.frame.width, height: recentWeatherView.frame.height)
        } else if (recentWeatherView.frame.minY + offset.y) < self.view.frame.height - recentWeatherView.frame.height {
            recentWeatherView.frame = CGRect.init(x: 0.0, y: self.view.frame.height - recentWeatherView.frame.height, width: self.view.frame.width, height: recentWeatherView.frame.height)
        } else {
            recentWeatherView.frame = CGRect.init(x: 0.0, y:recentWeatherView.frame.minY + offset.y, width: self.view.frame.width, height: recentWeatherView.frame.height)
        }
        
//        let distance = recentWeatherView.frame.height - 85
//        let offsetDistance =  (recentWeatherView.frame.height - 85) - (recentWeatherView.frame.maxY - self.view.frame.maxY)
//        let offsetRatio = offsetDistance / distance
//        recentWeatherView.set(offsetRatio: Float(offsetRatio))
        
        switch panGesture.state {
            case UIGestureRecognizerState.ended,UIGestureRecognizerState.cancelled,UIGestureRecognizerState.failed:
                animateRecentView(velocity: panGesture.velocity(in: recentWeatherView))
                break;
            default:
                break
        }
    }
    
    func animateRecentView(velocity:CGPoint) {
        var frame:CGRect = CGRect.init()
        if recentWeatherView.frame.minY > (self.view.frame.height * 0.37 + self.view.frame.height * 0.63 * 0.5){
            if velocity.y < -1000 {
//                print("向上")
                frame = CGRect.init(origin: CGPoint.init(x: 0.0, y: self.view.frame.height * 0.37), size: CGSize.init(width: self.view.frame.width, height: self.view.frame.height * 0.63))
                detailWeatherView.animteWeatherView(top: true)
            } else {
//                print("复原")
                frame = CGRect.init(origin: CGPoint.init(x: 0.0, y: self.view.frame.height - 85.0), size: CGSize.init(width: self.view.frame.width, height: self.view.frame.height * 0.63))
                detailWeatherView.animteWeatherView(top: false)
            }
        } else {
            if velocity.y > 1000 {
//                print("向下")
                frame = CGRect.init(origin: CGPoint.init(x: 0.0, y: self.view.frame.height - 85.0), size: CGSize.init(width: self.view.frame.width, height: self.view.frame.height * 0.63))
                detailWeatherView.animteWeatherView(top: false)
            } else {
//                print("复原")
                frame = CGRect.init(origin: CGPoint.init(x: 0.0, y: self.view.frame.height * 0.37), size: CGSize.init(width: self.view.frame.width, height: self.view.frame.height * 0.63))
                detailWeatherView.animteWeatherView(top: true)
            }
        }
        UIView.animate(withDuration: 0.25) { 
            self.recentWeatherView.frame = frame
        }
        if frame.minY == (self.view.frame.height - 85.0) {
            self.detailWeatherView.bounces = true
            self.recentWeatherView.resetRecentDetails()
        } else {
            self.detailWeatherView.bounces = false
            self.recentWeatherView.showRecentDetails()
        }
    }
}
