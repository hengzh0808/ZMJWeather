//
//  ZMJEditLocationController.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/6/12.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit

class ZMJEditLocationController: UIViewController {
    
    var deleteAddress:((LocationInfo)->Void)!
    var defaultAddress:((LocationInfo)->Void)!
    var selectAddress:((LocationInfo)->Void)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
