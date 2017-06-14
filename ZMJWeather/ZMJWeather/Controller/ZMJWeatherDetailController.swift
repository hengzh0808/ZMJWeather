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

class ZMJWeatherDetailController: UIViewController, UIGestureRecognizerDelegate {
    
    
    var locationInfo:LocationInfo!
    
    private var detailWeatherView:ZMJDetailWeatherView = ZMJDetailWeatherView()
    private var recentWeatherView:ZMJRecentWeatherView = ZMJRecentWeatherView()
    
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
        detailWeatherView.contentSize = self.view.bounds.size
        detailWeatherView.mj_header = MJRefreshStateHeader.init(refreshingBlock: {
            self.requestWeatherInfo()
        })
        (detailWeatherView.mj_header as! MJRefreshStateHeader).lastUpdatedTimeLabel.textColor = UIColor.white
        (detailWeatherView.mj_header as! MJRefreshStateHeader).stateLabel.textColor = UIColor.white
        detailWeatherView.backgroundColor = ColorBlue
        detailWeatherView.alwaysBounceVertical = true
        self.view .addSubview(detailWeatherView)
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
    }
    
    @objc private func requestWeatherInfo() {
        (detailWeatherView.mj_header as! MJRefreshStateHeader).stateLabel.text = "正在获取位置信息"
        weak var weakSelf = self
        var promise:Promise<NSDictionary?>
        if locationInfo != nil {
            (weakSelf?.detailWeatherView.mj_header as! MJRefreshStateHeader).stateLabel.text = "正在获取天气状况"
            weakSelf?.detailWeatherView.cityLabel.text = locationInfo.city
            weakSelf?.detailWeatherView.districtLabel.text = locationInfo.district
            promise = ZMJSingleNet.request(request: ZMJRequest.WeatherAll, method: .get, paths: [], parameters: ["city":(String(locationInfo.longitude) + "," + String(locationInfo.latitude))], form: [:])
        } else {
            promise = locationManager.updateLocation().then { (locationInfo) -> Promise<NSDictionary?> in
                weakSelf?.locationInfo = locationInfo
                _ = locationManager.saveLocation(location: locationInfo, type: .Auto)
                (weakSelf?.detailWeatherView.mj_header as! MJRefreshStateHeader).stateLabel.text = "正在获取天气状况"
                weakSelf?.detailWeatherView.cityLabel.text = locationInfo.city
                weakSelf?.detailWeatherView.districtLabel.text = locationInfo.district + "(自动定位)"
                return ZMJSingleNet.request(request: ZMJRequest.WeatherAll, method: .get, paths: [], parameters: ["city":(String(locationInfo.longitude) + "," + String(locationInfo.latitude))], form: [:])
            }
        }
        promise.then { (todayInfo:NSDictionary?) -> Void in
            locationManager.saveWeather(weatherInfo: todayInfo!, adcode: weakSelf?.locationInfo.adcode)
            weakSelf?.detailWeatherView.mj_header.endRefreshing()
            weakSelf?.updateWeather(weatherInfo: todayInfo)
        }.catch { (error) in
            weakSelf?.detailWeatherView.mj_header.endRefreshing()
            print("无法获取地理位置，请检查访问位置权限以及网络状态")
        }
    }
    
    func updateWeather(weatherInfo:NSDictionary?) {
        let daily_forecast:NSArray! = weatherInfo?.value(forKey: "daily_forecast") as? NSArray ?? NSArray.init() // 3~10天预报
        let now:NSDictionary! = weatherInfo?.value(forKey: "now") as? NSDictionary ?? NSDictionary.init() // 实况天气
        var _:NSArray! = weatherInfo?.value(forKey: "hourly_forecast") as? NSArray ?? NSArray.init() // 未来每小时天气预报
        var _:NSDictionary! = weatherInfo?.value(forKey: "suggestion") as? NSDictionary ?? NSDictionary.init() // 生活指数
        let aqi:NSDictionary! = weatherInfo?.value(forKey: "aqi") as? NSDictionary ?? NSDictionary.init() // 空气污染指数
        self.recentWeatherView.daily_forecast = daily_forecast
        self.detailWeatherView.set(now: now, today: (daily_forecast.firstObject! as? NSDictionary)!, aqi: aqi)
    }
    
    @objc private func panRecentWeatherView(panGesture:UIPanGestureRecognizer) {
        if panGesture.state == .began {
            recentWeatherView.panBegin()
        }
        let offset:CGPoint = panGesture.translation(in: panGesture.view)
        panGesture.setTranslation(CGPoint.init(x: 0, y: 0), in: panGesture.view)
        if (recentWeatherView.frame.minY + offset.y) > self.view.frame.height - 85.0 {
            recentWeatherView.frame = CGRect.init(x: 0.0, y:self.view.frame.height - 85.0, width: self.view.frame.width, height: recentWeatherView.frame.height)
        } else if (recentWeatherView.frame.minY + offset.y) < self.view.frame.height - recentWeatherView.frame.height {
            recentWeatherView.frame = CGRect.init(x: 0.0, y: self.view.frame.height - recentWeatherView.frame.height, width: self.view.frame.width, height: recentWeatherView.frame.height)
        } else {
            recentWeatherView.frame = CGRect.init(x: 0.0, y:recentWeatherView.frame.minY + offset.y, width: self.view.frame.width, height: recentWeatherView.frame.height)
        }
        
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
