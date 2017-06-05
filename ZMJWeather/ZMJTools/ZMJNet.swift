//
//  ZMJNet.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/5/28.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit
import Alamofire
import PromiseKit
import SwiftyJSON

let homeUrl:String = "https://free-api.heweather.com/v5/"
let appKey:String = "57bd5fd099c748d39b1497f1bd795719"


/// 天气接口类型
///
/// - WeatherAll: 所有点天气
/// - WeatherNow: 实时天气
enum ZMJRequest : String {
    case WeatherAll = "weather"
    case WeatherNow = "now"
    case WeatherHitory = "historical"
}

struct ZMJRequestError {
    var code:Int!
    var message:String!
}

let ZMJSingleNet = ZMJNet()
class ZMJNet: NSObject {
    
    var maxTaskCount = 10
    private var currentTasks:NSMutableArray = NSMutableArray.init()
    
    override init() {
        super.init()
        let manager = Alamofire.SessionManager.default
        manager.session.configuration.timeoutIntervalForRequest = 10.0
    }
    
    func request(request:ZMJRequest, method:HTTPMethod, paths:Array<String>, parameters:[String:String], form:[String:String]) -> Promise<NSDictionary?> {
        let url = self.buildUrl(request: request, paths: paths, parameters: parameters)
        return Promise.init(resolvers: { (resolve, reject) in
            Alamofire.request(url, method:method, parameters:form).responseJSON(completionHandler: { (response) in
                if response.result.isFailure {
                    reject(response.result.error!)
                } else {
                    var json = JSON.init(response.result.value!)
                    if (json.type == Type.dictionary && (json.dictionaryObject?["HeWeather5"] != nil)) {
                        if (json.dictionaryValue["HeWeather5"]?.type == Type.array && (json.dictionaryValue["HeWeather5"]?.array?.count)! > 0) {
                            let data:NSDictionary! = json.dictionaryValue["HeWeather5"]?.array?.first?.dictionaryObject as NSDictionary?
                            let status:String! = data.value(forKey: "status") as! String
                            if status == "ok" {
                                resolve(data)
                            } else {
                                reject(NSError.init(domain: status, code: 9999, userInfo: nil))
                            }
                        } else {
                            reject(NSError.init(domain: "数据格式不正确", code: 9999, userInfo: nil))
                        }
                    } else if ((json.stringValue as NSString).length > 0) {
                        reject(NSError.init(domain: json.stringValue, code: 9999, userInfo: nil))
                    } else {
                        reject(NSError.init(domain: "请求失败", code: 9999, userInfo: nil))
                    }
                }
            })
        })
    }
    
    func buildUrl(request:ZMJRequest, paths:Array<String>, parameters:Dictionary<String, String>) -> String {
        var url:String = homeUrl + request.rawValue
        if parameters.count > 0 {
            url = url + "?"
            let keys = Array(parameters.keys)
            for key in keys {
                url = url + key + "=" + parameters[key]!
                if key != keys.last {
                    url = url + "&"
                }
            }
        }
        url = url + "&" + "key=" + appKey
        return url
    }
}
