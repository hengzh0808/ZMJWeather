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
    
    private var topView:ZMJRecentTopView = ZMJRecentTopView()
    private var middleView:ZMJRecentMiddleView = ZMJRecentMiddleView()
    private var bottomView:ZMJRecentBottomView = ZMJRecentBottomView()
    
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
            topView.setTemps(recentWeathers: recentWeathers)
            
            middleView.setTemps(recentWeathers: recentWeathers)
            middleView.resetTemplines()
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
        topView.backgroundColor = UIColor.red
        self.addSubview(topView)
        
        middleView.backgroundColor = UIColor.init(red: 94/255.0, green: 201/255.0, blue: 255/255.0, alpha: 1.0)
        self.addSubview(middleView)

        bottomView.backgroundColor = UIColor.blue
        self.addSubview(bottomView)
    }
    
    func showTemplines() {
        middleView.showTemplines()
    }
    
    func resetTemplines() {
        middleView.resetTemplines()
    }
}

// 未来天气
private class ZMJRecentTopView: UIView {
    var maxTemps:Array<Int> = []
    var minTemps:Array<Int> = []
    func setTemps(recentWeathers:Array<ZMJWeather>) {
        
    }
}

// 未来温度
private class ZMJRecentMiddleView: UIView {
    var maxTemps:Array<Int> = []
    var minTemps:Array<Int> = []
    
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
        initSublayers()
    }
    
    func initSublayers() {
        // 高温阴影
        maxLineGradientLayer.removeFromSuperlayer()
        self.layer.addSublayer(maxLineGradientLayer)
        // 高温线条
        maxLineLayer.removeFromSuperlayer()
        self.layer.addSublayer(maxLineLayer)
        // 高温温点
        for pointLayer in maxPointLayers {
            pointLayer.removeFromSuperlayer()
        }
        maxPointLayers = []
        for _ in -1...maxTemps.count {
            let pointLayer = CALayer.init()
            maxPointLayers.append(pointLayer)
            self.layer.addSublayer(pointLayer)
        }
        // 低温阴影
        minLineGradientLayer.removeFromSuperlayer()
        self.layer.addSublayer(minLineGradientLayer)
        // 低温线条
        minLineLayer.removeFromSuperlayer()
        self.layer.addSublayer(minLineLayer)
        // 低温温点
        for pointLayer in minPointLayers {
            pointLayer.removeFromSuperlayer()
        }
        minPointLayers = []
        for _ in -1...maxTemps.count {
            let pointLayer = CALayer.init()
            minPointLayers.append(pointLayer)
            self.layer.addSublayer(pointLayer)
        }
    }
    
    func showTemplines() {
        draw(minTemps: minTemps, maxTemps: maxTemps, animete: false)
    }
    
    func resetTemplines() {
        var averageMaxTemps:Array<Int> = []
        var averageMinTemps:Array<Int> = []
        
        var totalMaxValue = 0
        for value in maxTemps {
            totalMaxValue = totalMaxValue + value
        }
        let averageMaxTemp = totalMaxValue / maxTemps.count
        for _ in 0..<maxTemps.count {
            averageMaxTemps.append(averageMaxTemp)
        }
        
        var totalMinValue = 0
        for value in minTemps {
            totalMinValue = totalMinValue + value
        }
        let averageMinTemp = totalMinValue / minTemps.count
        for _ in 0..<minTemps.count {
            averageMinTemps.append(averageMinTemp)
        }

        draw(minTemps: averageMinTemps, maxTemps: averageMaxTemps, animete: false)
    }
    
    private func draw(minTemps:Array<Int>, maxTemps:Array<Int>, animete:Bool) {
        if minTemps.count > 0 && maxTemps.count > 0 {
            let maxTemp:Int = [minTemps.max()!, maxTemps.max()!].max()!
            let minTemp:Int = [minTemps.min()!, maxTemps.min()!].min()!
            
            let yPadding:CGFloat = self.frame.height * 0.3333 / 3
            let perHeight:CGFloat = self.frame.height * 0.6666 / CGFloat(maxTemp - minTemp)
            let xPadding:CGFloat = self.frame.width / CGFloat(maxTemps.count * 2)
            let itemPadding:CGFloat = self.frame.width / CGFloat(maxTemps.count)
            
            // 计算最高温度点坐标
            var maxPoints:Array<CGPoint> = []
            for index in 0..<maxTemps.count {
                let point:CGPoint = CGPoint.init(x: xPadding + itemPadding * CGFloat(index), y: yPadding + perHeight * CGFloat((maxTemp - maxTemps[index])))
                maxPoints.append(point)
            }
            
            // 计算最低温度点坐标
            var minPoints:Array<CGPoint> = []
            for index in 0..<minTemps.count {
                let point:CGPoint = CGPoint.init(x: xPadding + itemPadding * CGFloat(index), y: yPadding + perHeight * CGFloat((maxTemp - minTemps[index])))
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
            self.drawTempPoints(points: minPoints, startShadowPoint: minShadowStartPoint, endShadowPoint: minShadowEndPoint, max: true, animate: animete)
        }
    }
    
    func createShadowLayer() -> CALayer {
        let shadowLayer = CALayer()
        shadowLayer.shadowColor = UIColor.black.cgColor
        shadowLayer.shadowOffset = CGSize.init(width: 0, height: 5.0)
        shadowLayer.shadowRadius = 5.0
        shadowLayer.shadowOpacity = 1.0
        shadowLayer.backgroundColor = UIColor.clear.cgColor
        return shadowLayer
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
    
    func createCurveLine(points:Array<CGPoint>) -> UIBezierPath {
        
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
        
        if animate {
            tempPoint.insert(CGPoint.init(x: 0, y: tempPoint.first!.y), at: 0)
            tempPoint.append(CGPoint.init(x: self.frame.width, y: tempPoint.last!.y))
        } else {
            tempPoint.insert(CGPoint.init(x: 0, y: tempPoint.first!.y), at: 0)
            tempPoint.append(CGPoint.init(x: self.frame.width, y: tempPoint.last!.y))
        }
        
        // 画温度线
        let maxTempLine = createCurveLine(points: tempPoint)
        let maxTempLayer = CAShapeLayer()
        maxTempLayer.path = maxTempLine.cgPath
        maxTempLayer.strokeColor = UIColor.white.cgColor
        maxTempLayer.fillColor = UIColor.clear.cgColor
        maxTempLayer.lineWidth = 1.5
        self.layer.addSublayer(maxTempLayer)
        
        if max {
            // 画温度线阴影
            let shadowGradientLayer = CAGradientLayer.init()
            shadowGradientLayer.colors = [UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5).cgColor, UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0).cgColor]
            shadowGradientLayer.frame = CGRect.init(x: 0, y: startShadowPoint.y, width: self.frame.width, height: endShadowPoint.y - startShadowPoint.y)
            
            let gradietPoints = convert(points: tempPoint, toFrame: shadowGradientLayer.frame)
            let gradietPath = createCurveLine(points: gradietPoints)
            gradietPath.addLine(to: CGPoint.init(x: shadowGradientLayer.frame.width, y: shadowGradientLayer.frame.height))
            gradietPath.addLine(to: CGPoint.init(x: 0, y: shadowGradientLayer.frame.height))
            gradietPath.close()
            let maskShadowMask = CAShapeLayer.init()
            maskShadowMask.path = gradietPath.cgPath
            shadowGradientLayer.mask = maskShadowMask
            
            self.layer.insertSublayer(shadowGradientLayer, below: maxTempLayer)
        }
        
        // 画温度点
        for index in 1..<tempPoint.count-1 {
            let layer0 = CALayer.init()
            layer0.bounds = CGRect.init(x: 0, y: 0, width: 10.0, height: 10.0)
            layer0.cornerRadius = 5.0;
            layer0.masksToBounds = true
            layer0.position = tempPoint[index]
            layer0.backgroundColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5).cgColor
            
            let layer1 = CALayer.init()
            layer1.bounds = CGRect.init(x: 0, y: 0, width: 5.0, height: 5.0)
            layer1.cornerRadius = 2.5;
            layer1.masksToBounds = true
            layer1.position = CGPoint.init(x: 5.0, y: 5.0)
            layer1.backgroundColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
            layer0.addSublayer(layer1)
            
            self.layer.addSublayer(layer0)
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

private class ZMJRecentBottomView: UIView {
    
}
