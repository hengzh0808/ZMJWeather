//
//  ZMJWeatherStruct.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/6/2.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

//import Foundation

struct ZMJWeather {
    // 公用参数
    var date:String = ""
    var weatherCode:String = ""
    var weatherText:String = ""
    var maxTemp:String = ""
    var minTemp:String = ""
    // 今日参数
    var nowTemp:String = ""
    var pm10:String = ""
    var pm25:String = ""
    var pmText:String = ""
    init() {
        date = ""
        weatherCode = ""
        weatherText = ""
        maxTemp = ""
        minTemp = ""
        nowTemp = ""
        pm10 = ""
        pm25 = ""
        pmText = ""
    }
}
