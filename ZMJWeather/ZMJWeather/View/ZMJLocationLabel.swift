//
//  ZMJLocationLabel.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/6/12.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit
import SnapKit

class ZMJLocationLabel: UILabel {
    
    private var lineView:UIView = UIView()

    override func layoutSubviews() {
        super.layoutSubviews()
        addSubview(lineView)
        lineView.backgroundColor = UIColor.init(red: 229.0/255.0, green: 229.0/255.0, blue: 229.0/255.0, alpha: 1.0)
        lineView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
}
