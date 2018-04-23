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
import pop

class ZMJWeatherDetailController: UIViewController, UIGestureRecognizerDelegate {
    
    
    var locationInfo:LocationInfo!
    
    private var detailWeatherView:ZMJDetailWeatherView = ZMJDetailWeatherView()
    private var recentWeatherView:ZMJRecentWeatherView = ZMJRecentWeatherView()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSubView()
        NotificationCenter.default.addObserver(self, selector: #selector(requestWeatherInfo), name: .UIApplicationDidEnterBackground, object: nil)
        if self.locationInfo != nil {
            weak var weakSelf = self
            _ = locationManager.queryWeather(adcode: self.locationInfo.adcode).then(execute: { (weatherInfo) -> Void in
                if weatherInfo != nil {
                    weakSelf?.updateWeather(weatherInfo: weatherInfo);
                }
            })
        }
        self.detailWeatherView.mj_header.beginRefreshing()
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
        detailWeatherView.mj_header = MJRefreshStateHeader.init(refreshingTarget: self, refreshingAction: #selector(requestWeatherInfo))
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
        recentWeatherView.backgroundColor = UIColor.clear
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
            weakSelf?.detailWeatherView.districtLabel.text = locationInfo.district + (locationInfo.type == LocationType.Auto ? "(自动定位)" : "")
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
        self.detailWeatherView.setWeather(withNow: now, today: (daily_forecast.firstObject! as? NSDictionary)!, aqi: aqi)
    }
    
    func panRecentWeatherView(panGesture:UIPanGestureRecognizer) {
        let offset:CGPoint = panGesture.translation(in: panGesture.view)
        var velocity:CGPoint = panGesture.velocity(in: recentWeatherView)
        switch panGesture.state {
        case .began:
            self.recentWeatherView.topView.changeBackgroundColor(withDirection: .up)
            self.detailWeatherView.changeWeatherView(withDirection: .pan, percent: 0.0)
            break
        case .changed:
            var distance:CGFloat = offset.y
            var ratio:CGFloat
            if recentWeatherView.frame.minY < ceil(self.view.frame.height * 0.37) {
                ratio = 1 - (ceil(self.view.frame.height * 0.37) - recentWeatherView.frame.minY) / 85.0
            } else if distance > 0 && ceil(recentWeatherView.frame.minY) == ceil(self.view.frame.height - 85.0) {
//                ratio = 1 - (recentWeatherView.frame.minY - ceil(self.view.frame.height - 85.0)) / 85.0
                break
            } else {
                ratio = 1.0
            }
            panGesture.setTranslation(CGPoint.zero, in: panGesture.view)
            distance = distance * ratio
            recentWeatherView.frame = CGRect.init(origin: CGPoint.init(x: 0.0, y:recentWeatherView.frame.minY + distance), size: recentWeatherView.frame.size)
            let current = (recentWeatherView.frame.minY - self.view.frame.height * 0.37) / (self.view.frame.height - 85.0 - self.view.frame.height * 0.37)
            let percent:CGFloat = 1 - current
            recentWeatherView.topView.changeStyle(percent: percent)
            detailWeatherView.changeWeatherView(percent: percent)
            break
        case .cancelled,.ended:
            if recentWeatherView.frame.minY > ceil(self.view.frame.height - 85.0) || recentWeatherView.frame.minY < ceil(self.view.frame.height * 0.37) {
                velocity = CGPoint.init(x: 0, y: 0)
            }
            animateWeatherViews(velocity: velocity, offset: offset)
            break
        default:
            break
        }
    }
    
    func animateWeatherViews(velocity:CGPoint, offset:CGPoint) {
        if offset.y > 0 && ceil(recentWeatherView.frame.origin.y) == ceil(self.view.frame.height - 85.0) {
            UIView.animate(withDuration: 0.25, animations: { 
                self.recentWeatherView.topView.changeBackgroundColor(withDirection: .down)
            })
            return
        }
        let centerY:CGFloat = self.view.frame.height * 0.37 + self.view.frame.height * 0.63 * 0.5
        let endFrame:CGRect
        let direction:AnimateDirection
        if velocity.y < 0 {
            // 向上托
            if velocity.y > -500 && recentWeatherView.frame.minY > centerY {
                endFrame = CGRect.init(origin: CGPoint.init(x: 0, y: self.view.frame.height - 85.0), size: recentWeatherView.frame.size)
                direction = AnimateDirection.down
            } else {
                endFrame = CGRect.init(origin: CGPoint.init(x: 0, y: self.view.frame.height * 0.37), size: recentWeatherView.frame.size)
                direction = AnimateDirection.up
            }
        } else {
            // 向下托
            if velocity.y < 500.0 && recentWeatherView.frame.minY < centerY {
                endFrame = CGRect.init(origin: CGPoint.init(x: 0, y: self.view.frame.height * 0.37), size: recentWeatherView.frame.size)
                direction = AnimateDirection.up
            } else {
                endFrame = CGRect.init(origin: CGPoint.init(x: 0, y: self.view.frame.height - 85.0), size: recentWeatherView.frame.size)
                direction = AnimateDirection.down
            }
        }
        let initialSpringVelocity:CGFloat = (velocity.y < -3000 || velocity.y > 3000) ? 30.0 : fabs((velocity.y / 3000) * 30.0)
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: initialSpringVelocity, options: .curveEaseInOut, animations: { 
            self.recentWeatherView.frame = endFrame
            self.recentWeatherView.topView.changeStyle(withDirection: direction)
            self.detailWeatherView.changeWeatherView(withDirection: direction)
        }, completion: nil)
        UIView.animate(withDuration: 0.25, delay: 0.20, options: .curveEaseInOut, animations: {
            if direction == .down {
                self.recentWeatherView.topView.changeBackgroundColor(withDirection: direction)
            }
            self.recentWeatherView.middleView.changeTemplines(withDirection: direction)
        }, completion: nil)
    }
}
