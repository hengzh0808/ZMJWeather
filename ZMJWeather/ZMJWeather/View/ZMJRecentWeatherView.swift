//
//  ZMJRecentWeatherView.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/6/1.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit
import SnapKit

let contractionFactor:CGFloat = 0.5

class ZMJRecentWeatherView: UIView {
    
    var topView:ZMJRecentTopView = ZMJRecentTopView()
    var middleView:ZMJRecentMiddleView = ZMJRecentMiddleView()
    var bottomView:ZMJRecentBottomView = ZMJRecentBottomView()
    
    private var recentWeathers:Array<ZMJWeather> = []
    
    open var daily_forecast:NSArray! {
        didSet {
            recentWeathers = []
            for value in daily_forecast {
                let dic = value as! NSDictionary
                var weather:ZMJWeather = ZMJWeather()
                weather.date = (dic.value(forKey: "date") as? String) ?? ""
                weather.weatherCode = ((dic.value(forKey: "cond") as? NSDictionary)?.value(forKey: "code_d") as? String) ?? ""
                weather.weatherText = ((dic.value(forKey: "cond") as? NSDictionary)?.value(forKey: "txt_d") as? String) ?? ""
                weather.maxTemp = ((dic.value(forKey: "tmp") as? NSDictionary)?.value(forKey: "max") as? String) ?? ""
                weather.minTemp = ((dic.value(forKey: "tmp") as? NSDictionary)?.value(forKey: "min") as? String) ?? ""
                recentWeathers.append(weather)
                if recentWeathers.count == 5 {
                    break
                }
            }
            topView.weathers = recentWeathers
            
            middleView.setTemps(recentWeathers: recentWeathers)
            middleView.changeTemplines(withDirection: .down)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        topView.frame = CGRect.init(x: 0, y: 0, width: self.frame.width, height: self.frame.height * (1 / 3))
        middleView.frame = CGRect.init(x: 0, y: self.frame.height * (1 / 3), width: self.frame.width, height: self.frame.height * (1 / 3))
        bottomView.frame = CGRect.init(x: 0, y: self.frame.height * (2 / 3), width: self.frame.width, height: self.frame.height * (1 / 3))
    }
    
    private func initSubViews() {
        topView.backgroundColor = UIColor.clear
        self.addSubview(topView)
        
        middleView.backgroundColor = UIColor.clear
        self.addSubview(middleView)
        
        bottomView.backgroundColor = UIColor.red
        self.addSubview(bottomView)
    }
}

// 未来天气
class ZMJRecentTopView: UIView {
    
    private var weatherViews:Array<WeatherView> = []
    var hideView:UIView = UIView.init()
    
    var weathers:Array<ZMJWeather> = [] {
        didSet {
            initSubViews()
        }
    }
    
    let weeks:Dictionary<String, String> = ["星期一" :"周一", "星期二" :"周二", "星期三" :"周三", "星期四" :"周四", "星期五" :"周五", "星期六" :"周六", "星期日" :"周日"]
    
    func initSubViews() {
        for view in weatherViews {
            view.removeFromSuperview()
        }
        weatherViews = []
        for (index, weather) in weathers.enumerated() {
            let weatherView = WeatherView.init(weather: weather)
            weatherView.backgroundColor = .clear
            weatherViews.append(weatherView)
            self.addSubview(weatherView)
            let dateFormatter:DateFormatter = DateFormatter.init()
            dateFormatter.setLocalizedDateFormatFromTemplate("yyyy-MM-dd")
            let nowDate:Date! = dateFormatter.date(from: weather.date)
            if index == 0 {
                weatherView.weekLabel.text = "今日"
            } else {
                dateFormatter.setLocalizedDateFormatFromTemplate("EEEE")
                let week = weeks[dateFormatter.string(from: nowDate)]
                weatherView.weekLabel.text = week
            }
            
            dateFormatter.setLocalizedDateFormatFromTemplate("M.d")
            let date = dateFormatter.string(from: nowDate).replacingOccurrences(of: "/", with: ".")
            weatherView.dateLabel.text = date
            
            let signName:NSString = NSString.init(format: "weather%@_icon", weather.weatherCode)
            weatherView.weatherSign.image = UIImage.init(named: signName as String)?.withRenderingMode(.alwaysTemplate)
            weatherView.tintColor = Color204
            
            weatherView.maxTempLabel.text = weather.maxTemp + tempSign
            weatherView.minTempLabel.text = weather.minTemp + tempSign
        }
        
        hideView.backgroundColor = UIColor.white
        hideView.layer.shadowColor = UIColor.white.cgColor
        hideView.layer.shadowOffset = CGSize.init(width: 0, height: 2.0)
        hideView.layer.shadowRadius = 2.0
        hideView.layer.shadowOpacity = 1.0
        insertSubview(hideView, at: 0)
        hideView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(83.0)
        }
    }
    
    override func layoutSubviews() {
        let itemWidth:CGFloat = self.frame.width / CGFloat(weathers.count)
        for (index, weatherView) in weatherViews.enumerated() {
            weatherView.frame = CGRect.init(x: itemWidth / 2 + CGFloat(index) * itemWidth, y: 0, width: itemWidth - 30, height: self.frame.height)
            weatherView.center = CGPoint.init(x: itemWidth / 2 + CGFloat(index) * itemWidth, y: self.frame.height / 2.0)
        }
    }
    
    func changeBackgroundColor(withDirection direction:AnimateDirection) {
        hideView.alpha = direction == .up ? 0.0 : 1.0
        for weatherView in weatherViews {
            weatherView.dateLabel.textColor = direction == .up ? UIColor.white : Color204
            weatherView.weekLabel.textColor = direction == .up ? UIColor.white : Color204
            weatherView.maxTempLabel.textColor = direction == .up ? UIColor.white : Color204
            weatherView.minTempLabel.textColor = direction == .up ? UIColor.white : Color204
            weatherView.weatherSign.tintColor = direction == .up ? UIColor.white : Color204
        }
    }
    
    func changeStyle(withDirection direction:AnimateDirection = .pan, percent:CGFloat = CGFloat.leastNormalMagnitude) {
        if (direction == .pan && percent == CGFloat.leastNormalMagnitude) ||  direction != .pan && percent != CGFloat.leastNormalMagnitude {
            return
        }
        for weatherView in self.weatherViews {
            weatherView.changeStyle(withPercent: percent != CGFloat.leastNormalMagnitude ? percent : direction == .up ? 1.0 : 0.0)
        }
    }
    
    // MARK:最近天气小View
    private class WeatherView: UIView {
        var weather:ZMJWeather!
        var dateLabel:UILabel = UILabel()
        var weekLabel:UILabel = UILabel()
        var weatherSign:UIImageView = UIImageView()
        var maxTempLabel:UILabel = UILabel()
        var minTempLabel:UILabel = UILabel()
        var labelHeight:CGFloat = 0.0
        
        init(weather: ZMJWeather) {
            super.init(frame: CGRect.zero)
            self.weather = weather
            initSubViews()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func draw(_ rect: CGRect) {
            super.draw(rect)
            labelHeight = (self.frame.height - 50 - 20.0) / 4.0
            weekLabel.frame = CGRect.init(x: 0, y: 10.0, width: self.frame.width, height: labelHeight)
            dateLabel.frame = CGRect.init(x: 0, y: weekLabel.frame.maxY + 10.0, width: self.frame.width, height: 0)
            weatherSign.frame = CGRect.init(x: (self.frame.width - 50.0) / 2.0, y: weekLabel.frame.maxY + 5.0, width: 50.0, height: 50.0)
            maxTempLabel.frame = CGRect.init(x: 0, y: weatherSign.frame.maxY, width: self.frame.width, height: 0)
            minTempLabel.frame = CGRect.init(x: 0, y: maxTempLabel.frame.maxY + 10.0, width: self.frame.width, height: 0)
        }
        
        func initSubViews()  {
            weekLabel.textColor = Color204
            weekLabel.font = UIFont.systemFont(ofSize: 13.0)
            weekLabel.textAlignment = .center
            weekLabel.layer.masksToBounds = true
            addSubview(weekLabel)
            
            dateLabel.textColor = .white
            dateLabel.font = UIFont.systemFont(ofSize: 13.0)
            dateLabel.textAlignment = .center
            dateLabel.layer.masksToBounds = true
            addSubview(dateLabel)
            
            weatherSign.contentMode = UIViewContentMode.scaleAspectFit
            addSubview(weatherSign)
            
            maxTempLabel.textColor = .white
            maxTempLabel.font = UIFont.systemFont(ofSize: 13.0)
            maxTempLabel.textAlignment = .center
            maxTempLabel.layer.masksToBounds = true
            addSubview(maxTempLabel)
            
            minTempLabel.textColor = .white
            minTempLabel.font = UIFont.systemFont(ofSize: 13.0)
            minTempLabel.textAlignment = .center
            minTempLabel.layer.masksToBounds = true
            addSubview(minTempLabel)
        }
        
        func changeStyle(withPercent percent:CGFloat) {
            if percent > 1.0 || percent < 0.0 {
                return
            }
            let inset:CGFloat = percent == 1.0 ? 5.0 : 0
            labelHeight = (self.frame.height - 50 - 20.0) / 4.0
            weekLabel.frame = CGRect.init(x: 0, y: 10.0 * (1 - percent), width: self.frame.width, height: labelHeight)
            dateLabel.frame = CGRect.init(x: 0, y: weekLabel.frame.maxY + 10.0, width: self.frame.width, height: labelHeight * percent)
            weatherSign.frame = CGRect.init(x: (self.frame.width - 50.0) / 2.0, y: dateLabel.frame.maxY - 5 * (1 - percent), width: 50.0, height: 50.0).insetBy(dx: inset, dy: inset)
            maxTempLabel.frame = CGRect.init(x: 0, y: weatherSign.frame.maxY + inset, width: self.frame.width, height: labelHeight * percent)
            minTempLabel.frame = CGRect.init(x: 0, y: maxTempLabel.frame.maxY + 10.0, width: self.frame.width, height: labelHeight * percent)
        }
    }
}

// 未来温度
class ZMJRecentMiddleView: UIView {
    var maxTemps:Array<Int> = []
    var minTemps:Array<Int> = []
    var maxTemp:Int = 0
    var minTemp:Int = 0
    
    var maxLineLayer:CAShapeLayer = CAShapeLayer()
    
    var maxPointLayers:Array<CALayer> = []
    
    var maxLineGradientLayer:CAGradientLayer = CAGradientLayer()
    
    var minLineLayer:CAShapeLayer = CAShapeLayer()
    
    var minPointLayers:Array<CALayer> = []
    
    var minLineGradientLayer:CAGradientLayer = CAGradientLayer()
    
    func setTemps(recentWeathers:Array<ZMJWeather>) {
        maxTemps = []
        minTemps = []
        for weather in recentWeathers {
            maxTemps.append(Int(weather.maxTemp)!)
            minTemps.append(Int(weather.minTemp)!)
        }
        maxTemp = [minTemps.max()!, maxTemps.max()!].max()!
        minTemp = [minTemps.min()!, maxTemps.min()!].min()!
        initSublayers()
    }
    
    func initSublayers() {
        // 高温阴影
        maxLineGradientLayer.removeFromSuperlayer()
        maxLineGradientLayer.colors = [UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5).cgColor, UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0).cgColor]
        maxLineGradientLayer.mask = CAShapeLayer.init()
        self.layer.addSublayer(maxLineGradientLayer)
        // 高温线条
        maxLineLayer.removeFromSuperlayer()
        maxLineLayer.strokeColor = UIColor.white.cgColor
        maxLineLayer.fillColor = UIColor.clear.cgColor
        maxLineLayer.lineWidth = 1.5
        self.layer.addSublayer(maxLineLayer)
        // 高温温点
        for pointLayer in maxPointLayers {
            pointLayer.removeFromSuperlayer()
        }
        maxPointLayers = []
        for _ in 0..<maxTemps.count {
            let pointLayer0 = CALayer.init()
            pointLayer0.bounds = CGRect.init(x: 0, y: 0, width: 10.0, height: 10.0)
            pointLayer0.cornerRadius = 5.0;
            pointLayer0.masksToBounds = true
            pointLayer0.backgroundColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5).cgColor
            
            let pointLayer1 = CALayer.init()
            pointLayer1.bounds = CGRect.init(x: 0, y: 0, width: 5.0, height: 5.0)
            pointLayer1.cornerRadius = 2.5;
            pointLayer1.masksToBounds = true
            pointLayer1.backgroundColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
            pointLayer1.position = CGPoint.init(x: 5.0, y: 5.0)
            pointLayer0.addSublayer(pointLayer1)
            
            maxPointLayers.append(pointLayer0)
            self.layer.addSublayer(pointLayer0)
        }
        
        // 低温阴影
        minLineGradientLayer.removeFromSuperlayer()
        minLineGradientLayer.colors = [UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5).cgColor, UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0).cgColor]
        minLineGradientLayer.mask = CAShapeLayer.init()
        self.layer.addSublayer(minLineGradientLayer)
        // 低温线条
        minLineLayer.removeFromSuperlayer()
        minLineLayer.removeFromSuperlayer()
        minLineLayer.strokeColor = UIColor.white.cgColor
        minLineLayer.fillColor = UIColor.clear.cgColor
        minLineLayer.lineWidth = 1.5
        self.layer.addSublayer(minLineLayer)
        // 低温温点
        for pointLayer in minPointLayers {
            pointLayer.removeFromSuperlayer()
        }
        minPointLayers = []
        for _ in 0..<maxTemps.count {
            let pointLayer0 = CALayer.init()
            pointLayer0.bounds = CGRect.init(x: 0, y: 0, width: 10.0, height: 10.0)
            pointLayer0.cornerRadius = 5.0;
            pointLayer0.masksToBounds = true
            pointLayer0.backgroundColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5).cgColor
            
            let pointLayer1 = CALayer.init()
            pointLayer1.bounds = CGRect.init(x: 0, y: 0, width: 5.0, height: 5.0)
            pointLayer1.cornerRadius = 2.5;
            pointLayer1.masksToBounds = true
            pointLayer1.backgroundColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
            pointLayer1.position = CGPoint.init(x: 5.0, y: 5.0)
            pointLayer0.addSublayer(pointLayer1)
            
            minPointLayers.append(pointLayer0)
            self.layer.addSublayer(pointLayer0)
        }
    }
    
    func changeTemplines(withDirection direction:AnimateDirection) {
        if direction == .up {
            draw(minTemps: minTemps, maxTemps: maxTemps, animete: true)
        } else if direction == .down {
            var averageMaxTemps:Array<Int> = []
            var averageMinTemps:Array<Int> = []
            
            for _ in 0..<maxTemps.count {
                averageMaxTemps.append(maxTemp - (maxTemp - minTemp) / 3)
            }
            
            for _ in 0..<minTemps.count {
                averageMinTemps.append(minTemp + (maxTemp - minTemp) / 3)
            }
            
            draw(minTemps: averageMinTemps, maxTemps: averageMaxTemps, animete: false)
        }
    }
    
    private func draw(minTemps:Array<Int>, maxTemps:Array<Int>, animete:Bool) {
        if minTemps.count > 0 && maxTemps.count > 0 {
            
            let yPadding:Float = Float(self.frame.height * 0.3333 / 2.0)
            let perHeight:Float = Float(self.frame.height * 0.6666 / CGFloat(maxTemp - minTemp))
            let xPadding:Float = Float(self.frame.width / CGFloat(maxTemps.count * 2))
            let itemPadding:Float = Float(self.frame.width) / Float(maxTemps.count)
            
            // 计算最高温度点坐标
            var maxPoints:Array<CGPoint> = []
            for index in 0..<maxTemps.count {
                var point:CGPoint = CGPoint.init()
                point.x = CGFloat((xPadding + itemPadding * Float(index)))
                point.y = CGFloat((yPadding + perHeight * Float((maxTemp - maxTemps[index]))))
                maxPoints.append(point)
            }
            
            // 计算最低温度点坐标
            var minPoints:Array<CGPoint> = []
            for index in 0..<minTemps.count {
                var point:CGPoint = CGPoint.init()
                point.x = CGFloat((xPadding + itemPadding * Float(index)))
                point.y = CGFloat((yPadding + perHeight * Float((maxTemp - minTemps[index]))))
                minPoints.append(point)
            }
            
            // 画最高温度线
            let maxShadowStartPoint:CGPoint = maxPoints.min(by: { (point1, point2) -> Bool in
                return point1.y < point2.y
            })!
            let maxShadowEndPoint:CGPoint = minPoints.max(by: { (point1, point2) -> Bool in
                return point2.y > point1.y
            })!
            self.drawTempPoints(points: maxPoints, startShadowPoint: maxShadowStartPoint, endShadowPoint: maxShadowEndPoint, max: true, animate: animete)
            
            // 画最低温度线
            let minShadowStartPoint:CGPoint = minPoints.min(by: { (point1, point2) -> Bool in
                return point1.y < point2.y
            })!
            let minShadowEndPoint:CGPoint = CGPoint.init(x: 0, y: self.frame.height)
            self.drawTempPoints(points: minPoints, startShadowPoint: minShadowStartPoint, endShadowPoint: minShadowEndPoint, max: false, animate: animete)
        }
    }
    
    func convert(points:Array<CGPoint>, toFrame:CGRect) -> Array<CGPoint> {
        var newPoints:Array<CGPoint> = []
        let offsetX:CGFloat = -toFrame.minX
        let offsetY:CGFloat = -toFrame.minY
        for point in points {
            let newPoint:CGPoint = CGPoint.init(x: point.x + offsetX, y: point.y + offsetY)
            newPoints.append(newPoint)
        }
        return newPoints
    }
    
    func createCurveLinePath(points:Array<CGPoint>) -> UIBezierPath {
        
        let path = UIBezierPath.init()
        path.move(to: points.first!)
        
        var previousPoint:CGPoint = path.currentPoint
        
        var previousCenterPoint:CGPoint = CGPoint.zero
        var centerPoint:CGPoint = CGPoint.zero
        var centerPointDistance:CGFloat = 0
        
        var obliqueRatio:CGFloat = 0
        var obliqueAngle:CGFloat = 0
        
        var previousControlPoint1:CGPoint = CGPoint.zero
        var previousControlPoint2:CGPoint = CGPoint.zero
        var controlPoint1:CGPoint = CGPoint.zero
        
        for index in 1..<points.count {
            let toPoint = points[index]
            if index > 0 {
                previousCenterPoint = CenterPointOf(point1: path.currentPoint, point2: previousPoint)
                centerPoint = CenterPointOf(point1: previousPoint, point2: toPoint)
                
                centerPointDistance = DistanceBetweenPoint(point1: previousCenterPoint, point2: centerPoint)
                
                if previousCenterPoint.x != centerPoint.x {
                    obliqueRatio = (centerPoint.y - previousCenterPoint.y) / (centerPoint.x - previousCenterPoint.x);
                    obliqueAngle = atan(obliqueRatio);
                } else {
                    obliqueAngle = CGFloat.pi / 2.0
                }
                previousControlPoint2 = CGPoint.init(x: previousPoint.x - 0.5 * contractionFactor * centerPointDistance * cos(obliqueAngle), y: previousPoint.y - 0.5 * contractionFactor * centerPointDistance * sin(obliqueAngle))
                controlPoint1 = CGPoint.init(x: previousPoint.x + 0.5 * contractionFactor * centerPointDistance * cos(obliqueAngle), y: previousPoint.y + 0.5 * contractionFactor * centerPointDistance * sin(obliqueAngle))
            }
            if index == 1 {
                path.addQuadCurve(to: previousPoint, controlPoint: previousControlPoint2)
            } else if index == points.count - 1 {
                path.addCurve(to: previousPoint, controlPoint1: previousControlPoint1, controlPoint2: previousControlPoint2)
                path.addQuadCurve(to: toPoint, controlPoint: controlPoint1)
            } else {
                path.addCurve(to: previousPoint, controlPoint1: previousControlPoint1, controlPoint2: previousControlPoint2)
            }
            
            previousControlPoint1 = controlPoint1
            previousPoint = toPoint
        }
        return path
    }
    
    func drawTempPoints(points:Array<CGPoint>, startShadowPoint:CGPoint, endShadowPoint:CGPoint, max:Bool, animate:Bool) {
        var tempPoint = points
        
        // 温度点位置
        for (index, pointLayer) in (max ? maxPointLayers : minPointLayers).enumerated() {
            if animate {
                let lineAnimate = CABasicAnimation.init(keyPath: "position")
                lineAnimate.fromValue = pointLayer.position
                lineAnimate.toValue = tempPoint[index]
                lineAnimate.duration = 0.25
                lineAnimate.fillMode = kCAFillModeForwards;
                lineAnimate.isRemovedOnCompletion = false
                pointLayer.add(lineAnimate, forKey: "position")
            } else {
                pointLayer.removeAnimation(forKey: "position")
                pointLayer.position = tempPoint[index]
            }
        }
        
        // 温度线条
        tempPoint.insert(CGPoint.init(x: 0, y: tempPoint.first!.y), at: 0)
        tempPoint.append(CGPoint.init(x: self.frame.width, y: tempPoint.last!.y))
        
        let tempLinePath = createCurveLinePath(points: tempPoint)
        let tempLineLayer = max ? maxLineLayer : minLineLayer
        
        
        if animate {
            let lineAnimate = CABasicAnimation.init(keyPath: "path")
            lineAnimate.fromValue = tempLineLayer.path
            lineAnimate.toValue = tempLinePath.cgPath
            lineAnimate.duration = 0.25
            lineAnimate.fillMode = kCAFillModeForwards;
            lineAnimate.isRemovedOnCompletion = false
            tempLineLayer.add(lineAnimate, forKey: "path")
        } else {
            tempLineLayer.removeAnimation(forKey: "path")
            tempLineLayer.path = tempLinePath.cgPath
        }
        
        
        
        
        // 温度线阴影
        let tempLineShadowLayer = max ? maxLineGradientLayer : minLineGradientLayer
        tempLineShadowLayer.frame = CGRect.init(x: 0, y: startShadowPoint.y, width: self.frame.width, height: endShadowPoint.y - startShadowPoint.y)
        let gradietPoints = convert(points: tempPoint, toFrame: tempLineShadowLayer.frame)
        let gradietPath = createCurveLinePath(points: gradietPoints)
        gradietPath.addLine(to: CGPoint.init(x: tempLineShadowLayer.frame.width, y: tempLineShadowLayer.frame.height))
        gradietPath.addLine(to: CGPoint.init(x: 0, y: tempLineShadowLayer.frame.height))
        gradietPath.close()
        
        let shadowMaskLayer:CAShapeLayer = tempLineShadowLayer.mask as! CAShapeLayer
        if animate {
            let shadowAnimate = CABasicAnimation.init(keyPath: "path")
            shadowAnimate.fromValue = shadowMaskLayer.path
            shadowAnimate.toValue = gradietPath.cgPath
            shadowAnimate.duration = 0.25
            shadowAnimate.fillMode = kCAFillModeForwards;
            shadowAnimate.isRemovedOnCompletion = false
            shadowMaskLayer.add(shadowAnimate, forKey: "path")
        } else {
            shadowMaskLayer.removeAnimation(forKey: "path")
            shadowMaskLayer.path = gradietPath.cgPath
        }
        
    }
    
    private func ControlPointForTheBezierCanThrough3Point(point1:CGPoint, point2:CGPoint, point3:CGPoint) -> CGPoint {
        return CGPoint.init(x: 2 * point2.x - (point1.x + point3.x) / 2, y: 2 * point2.y - (point1.y + point3.y) / 2)
    }
    
    private func DistanceBetweenPoint(point1:CGPoint, point2:CGPoint) -> CGFloat {
        return sqrt((point1.x - point2.x) * (point1.x - point2.x) + (point1.y - point2.y) * (point1.y - point2.y))
    }
    
    private func CenterPointOf(point1:CGPoint, point2:CGPoint) -> CGPoint {
        return CGPoint.init(x: (point1.x + point2.x) * 0.5, y: (point1.y + point2.y) * 0.5)
    }
}

class ZMJRecentBottomView: UIView {
    
}
