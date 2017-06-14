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

private class ZMJAutoLocation: UITableViewCell {
    
}

private class ZMJSavedLocation: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        initSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initSubViews() {
        
    }
}
