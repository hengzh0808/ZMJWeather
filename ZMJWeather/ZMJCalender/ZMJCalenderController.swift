//
//  ZMJCalenderController.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/5/31.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit
import FSCalendar

class ZMJCalenderController: UIViewController {

//    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var calenderView: FSCalendar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        topBarView.layer.shadowOffset = CGSize.init(width: 0, height: 1)
//        topBarView.backgroundColor = UIColor.white
//        topBarView.layer.shadowColor = UIColor.white.cgColor
//        topBarView.layer.shadowOffset = CGSize.init(width: 0, height: 2.0)
//        topBarView.layer.shadowRadius = 2.0
//        topBarView.layer.shadowOpacity = 1.0
        
        calenderView.scrollDirection = FSCalendarScrollDirection.vertical
        calenderView.pagingEnabled = false; // important
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
}
