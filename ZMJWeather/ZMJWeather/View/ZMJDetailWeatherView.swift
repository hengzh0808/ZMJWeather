//
//  ZMJDetailWeatherView.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/6/1.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit
import SnapKit
import DateToolsSwift

class ZMJDetailWeatherView: UIScrollView {
    
    var cityLabel: UILabel = UILabel()
    var districtLabel: UILabel = UILabel()
    private var weatherView:DetailWeatherView = DetailWeatherView()
    
    private var detailWeather:ZMJWeather = ZMJWeather()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentSize = CGSize.init(width: self.frame.width, height: self.frame.height)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let newPoint:CGPoint = change![NSKeyValueChangeKey.newKey] as! CGPoint
        if newPoint.y > 0 {
            self.setContentOffset(CGPoint.init(x: 0, y: 0), animated: false)
        }
    }
    
    // MARK:自定义方法
    private func initSubViews() {
        self.addObserver(self, forKeyPath: "contentOffset", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        cityLabel.textColor = UIColor.white
        cityLabel.font = UIFont.systemFont(ofSize: 17.0)
        cityLabel.text = ""
        cityLabel.textAlignment = NSTextAlignment.center
        self.addSubview(cityLabel)
        cityLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(12.0)
            make.width.equalToSuperview()
        }
        
        districtLabel.textColor = UIColor.white
        districtLabel.font = UIFont.systemFont(ofSize: 13.0)
        districtLabel.text = ""
        districtLabel.textAlignment = NSTextAlignment.center
        self.addSubview(districtLabel)
        districtLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(cityLabel.snp.bottom).offset(5.0)
            make.width.equalToSuperview()
        }
        
        self.addSubview(weatherView)
        weatherView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(150.0)
            make.centerX.equalToSuperview()
            make.height.equalTo(65)
        }
    }
    
    func animteWeatherView(top:Bool) {
        if top {
            weatherView.snp.remakeConstraints({ (make) in
                make.top.equalToSuperview().offset(64)
                make.left.equalToSuperview().offset(39)
                make.height.equalTo(65)
            })
        } else {
            weatherView.snp.remakeConstraints({ (make) in
                make.top.equalToSuperview().offset(150.0)
                make.centerX.equalToSuperview()
                make.height.equalTo(65)
            })
        }
        UIView.animate(withDuration: 0.25) { 
            self.layoutIfNeeded()
            self.weatherView.dateLable.alpha = top ? 1.0 : 0.0
            self.weatherView.weekLabel.alpha = top ? 1.0 : 0.0
            self.weatherView.aqiView.alpha = top ? 1.0 : 0.0
            self.weatherView.weatherSign.alpha = top ? 1.0 : 0.0
        }
    }
    
    func set(now:NSDictionary, today:NSDictionary, aqi:NSDictionary) {
        detailWeather.weatherCode =  ((now.value(forKey: "cond") as? NSDictionary)?.value(forKey: "code") as? String) ?? ""
        detailWeather.weatherText =  ((now.value(forKey: "cond") as? NSDictionary)?.value(forKey: "txt") as? String) ?? ""
        detailWeather.nowTemp = (now.value(forKey: "tmp") as? String) ?? ""

        detailWeather.date = (today.value(forKey: "date") as? String) ?? ""
        detailWeather.maxTemp = ((today.value(forKey: "tmp") as? NSDictionary)?.value(forKey: "max") as? String) ?? ""
        detailWeather.minTemp = ((today.value(forKey: "tmp") as? NSDictionary)?.value(forKey: "min") as? String) ?? ""
        
        
        detailWeather.pm25 = ((aqi.value(forKey: "city") as? NSDictionary)?.value(forKey: "pm25") as? String) ?? ""
        detailWeather.pm10 = ((aqi.value(forKey: "city") as? NSDictionary)?.value(forKey: "pm10") as? String) ?? ""
        detailWeather.pmText = ((aqi.value(forKey: "city") as? NSDictionary)?.value(forKey: "qlty") as? String) ?? ""
        
        weatherView.weather = detailWeather
    }
}

private class DetailWeatherView: UIView {
    var tempLable:UILabel = UILabel()
    var weatherLabel:UILabel = UILabel()
    var maxTempLabel:UILabel = UILabel()
    var minTempLabel:UILabel = UILabel()
    
    var dateLable:UILabel = UILabel()
    var weekLabel:UILabel = UILabel()
    
    var aqiLable:UILabel = UILabel()
    var aqiView:UIView = UIView()
    
    var weatherSign:UIImageView = UIImageView()
    
    let months = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二"]
    
    var weather:ZMJWeather! {
        didSet {
            tempLable.text = weather.nowTemp + tempSign
            weatherLabel.text = weather.weatherText
            weatherSign.image = UIImage.init(named: "weather" + weather.weatherCode + "_icon")?.withRenderingMode(.alwaysTemplate)
            weatherSign.tintColor = UIColor.white
            maxTempLabel.text = upArrow + weather.maxTemp + tempSign
            minTempLabel.text = downArrow + weather.minTemp + tempSign
            
            let nowDate:Date = Date.init()
            let dateFormatter:DateFormatter = DateFormatter.init()
            dateFormatter.setLocalizedDateFormatFromTemplate("EEEE")
            let week = dateFormatter.string(from: nowDate)
            dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd")
            let dateStr:String = dateFormatter.string(from: nowDate)
            let month:Int = Int(dateStr.components(separatedBy: "/")[1])!
            let day:Int = Int(dateStr.components(separatedBy: "/")[2])!
            
            dateLable.text = months[month - 1] + "月" + String(day) + "日"
            weekLabel.text = week
    
            aqiView.isHidden = false
            aqiLable.text = weather.pm25
            if Int(weather.pm25)! <= 35 {
                aqiLable.text = aqiLable.text?.appending("  空气质量优秀")
            } else if Int(weather.pm25)! > 35 && Int(weather.pm25)! <= 75 {
                aqiLable.text = aqiLable.text?.appending("  空气质量良好")
            } else if Int(weather.pm25)! > 75 && Int(weather.pm25)! <= 115 {
                aqiLable.text = aqiLable.text?.appending("  空气轻度污染")
            } else if Int(weather.pm25)! > 115 && Int(weather.pm25)! <= 150 {
                aqiLable.text = aqiLable.text?.appending("  空气中度污染")
            } else if Int(weather.pm25)! > 150 && Int(weather.pm25)! <= 250 {
                aqiLable.text = aqiLable.text?.appending("  空气重度污染")
            } else {
                aqiLable.text = aqiLable.text?.appending("  空气严重污染")
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initSubViews() {
        addSubview(tempLable)
        tempLable.font = UIFont.systemFont(ofSize: 83)
        tempLable.textColor = UIColor.white
        tempLable.textAlignment = NSTextAlignment.right
        tempLable.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        weatherLabel.font = UIFont.systemFont(ofSize: 24)
        weatherLabel.textColor = UIColor.white
        weatherLabel.textAlignment = NSTextAlignment.left
        addSubview(weatherLabel)
        weatherLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.top.equalToSuperview().offset(1.0)
            make.height.equalTo(21.0)
            make.left.equalTo(tempLable.snp.right).offset(25.0)
        }
        
        maxTempLabel.textAlignment = NSTextAlignment.left
        maxTempLabel.font = UIFont.systemFont(ofSize: 15)
        maxTempLabel.textColor = UIColor.white
        maxTempLabel.textAlignment = NSTextAlignment.left
        addSubview(maxTempLabel)
        maxTempLabel.snp.makeConstraints { (make) in
            make.top.equalTo(weatherLabel.snp.bottom).offset(5.0)
            make.left.equalTo(tempLable.snp.right).offset(25.0)
        }

        minTempLabel.textAlignment = NSTextAlignment.left
        minTempLabel.font = UIFont.systemFont(ofSize: 15)
        minTempLabel.textColor = UIColor.white
        minTempLabel.textAlignment = NSTextAlignment.left
        minTempLabel.textAlignment = NSTextAlignment.left
        addSubview(minTempLabel)
        minTempLabel.snp.makeConstraints { (make) in
            make.height.equalTo(maxTempLabel.snp.height)
            make.top.equalTo(maxTempLabel.snp.bottom).offset(5.0)
            make.left.equalTo(tempLable.snp.right).offset(25.0)
            make.bottom.equalToSuperview().offset(0.0)
        }
        
        weatherSign.contentMode = .scaleAspectFit
        weatherSign.alpha = 0.0
        addSubview(weatherSign)
        weatherSign.snp.makeConstraints { (make) in
            make.top.equalTo(weatherLabel.snp.top)
            make.left.equalTo(weatherLabel.snp.right).offset(30.0)
            make.bottom.equalTo(minTempLabel.snp.bottom)
            make.width.equalTo(weatherSign.snp.height)
        }
        
        
        dateLable.textColor = UIColor.white
        dateLable.font = UIFont.systemFont(ofSize: 15)
        dateLable.alpha = 0.0
        addSubview(dateLable)
        dateLable.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(self.snp.bottom).offset(15)
        }
        
        weekLabel.textColor = UIColor.white
        weekLabel.font = UIFont.systemFont(ofSize: 15)
        weekLabel.alpha = 0.0
        addSubview(weekLabel)
        weekLabel.snp.makeConstraints { (make) in
            make.left.equalTo(dateLable.snp.right).offset(10.0)
            make.centerY.equalTo(dateLable.snp.centerY)
        }
        
        aqiView.isHidden = true
        aqiView.layer.cornerRadius = 10.0
        aqiView.backgroundColor = UIColor.white
        aqiView.layer.masksToBounds = true
        aqiView.alpha = 0.0
        addSubview(aqiView)
        aqiView.snp.makeConstraints { (make) in
            make.left.equalTo(weekLabel.snp.right).offset(10.0)
            make.centerY.equalTo(weekLabel.snp.centerY)
            make.height.equalTo(25.0)
        }
        
        aqiLable.textColor = ColorBlue
        aqiLable.font = UIFont.systemFont(ofSize: 15)
        aqiLable.adjustsFontSizeToFitWidth = true
        aqiView.addSubview(aqiLable)
        aqiLable.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15.0)
            make.right.equalToSuperview().offset(-15.0)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}

