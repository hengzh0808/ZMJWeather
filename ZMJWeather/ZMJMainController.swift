//
//  ZMJMainController.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/5/29.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit
import SnapKit


class ZMJMainController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        (self.tabBar as! ZMJTabbar) .setSelectedIndex(index: 0)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        (self.tabBar as! ZMJTabbar) .setSelectedIndex(index: (tabBar.items?.index(of: item))!)
    }
}

class ZMJTabbar: UITabBar, UITabBarDelegate {
    var line:UIView = UIView.init()
    var labels:Array<UILabel> = Array.init()
    var titles:Array<String> = Array.init()
    let selectedColor:UIColor = UIColor.init(red: 115.0/225.0, green: 115.0/225.0, blue: 115.0/225.0, alpha: 1.0)
    let unselectedColor:UIColor = UIColor.init(red: 184/225.0, green: 184.0/225.0, blue: 184.0/225.0, alpha: 1.0)
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        size.height = 69.5
        return size
    }
    
    override func setItems(_ items: [UITabBarItem]?, animated: Bool) {
        for item in items! {
            if item.title != nil {
                titles.append(item.title!)
                
                let label:UILabel = UILabel.init()
                label.text = item.title
                label.textColor = unselectedColor
                if items?.count == 2 {
                    label.textAlignment = items?.index(of: item) == 0 ? NSTextAlignment.right : NSTextAlignment.left
                } else {
                    label.textAlignment = NSTextAlignment.center
                }
                self.addSubview(label)
                self.labels.append(label)
                

                item.title = nil
            }
        }
        
        super.setItems(items, animated: animated)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var labelIndex = 0
        for view in self.subviews {
            if NSStringFromClass(view.classForCoder) == "UITabBarButton" {
                let label = labels[labelIndex]
                view.addSubview(label)
                label.snp.makeConstraints({ (make) in
                    make.center.equalToSuperview()
                    make.width.equalToSuperview().offset(-20)
                    make.height.equalToSuperview()
                })
                labelIndex += 1
            }
        }
    }
    
    // MARK:自定义实例方法
    private func initialize() {
        line.backgroundColor = UIColor.init(red: 184.0 / 255.0, green: 184.0 / 255.0, blue: 184.0 / 255.0, alpha: 1.0)
        self.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(0.5)
            make.height.equalTo(10.0)
        }
    }
    
    public func setSelectedIndex(index: Int) {
        for label in labels {
            label.textColor = labels.index(of: label) == index ? selectedColor : unselectedColor
        }
    }
    
    // MARK:自定义类方法
    class func customeappearance() {
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
    }
}
