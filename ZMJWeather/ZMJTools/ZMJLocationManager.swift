//
//  ZMJLocationManager.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/5/31.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit
import PromiseKit
import FMDB
import SwiftyJSON

enum LocationType:String {
    case Auto = "auto"
    case Manual = "manual"
}

@objc class LocationInfo:NSObject {
    var latitude:Double!
    var longitude:Double!
    var adcode:String! // 区域编码
    var province:String! // 省
    var city:String! // 市
    var district:String! // 区
    var type:LocationType = LocationType.Manual
}

let LocationUpdate:Notification = Notification.init(name: Notification.Name(rawValue: "LocationUpdate"))
let WeatherUpdate:Notification = Notification.init(name: Notification.Name(rawValue: "WeatherUpdate"))

typealias AddressHandlerStart = @convention(block) () -> Void
typealias AddressHandlerSuccess = @convention(block) (LocationInfo) -> Void
typealias AddressHandlerError = @convention(block) (String) -> Void

let locationManager:ZMJLocationManager = ZMJLocationManager.init()
class ZMJLocationManager: NSObject, AMapSearchDelegate {
    
    private var startHandlers:NSMutableArray = NSMutableArray.init()
    private var successHandlers:NSMutableArray = NSMutableArray.init()
    private var errorHandlers:NSMutableArray = NSMutableArray.init()
    
    private let locationTool:AMapLocationManager = AMapLocationManager.init()
    private let searchTool:AMapSearchAPI = AMapSearchAPI.init()
    private var locationRequset: Dictionary<AMapGeocodeSearchRequest, (fulfill: (Array<LocationInfo>) -> Void, reject: (Error) -> Void)> = Dictionary.init()
    private var dbQueue:FMDatabaseQueue!
    
    override init() {
        super.init()
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        dbQueue = FMDatabaseQueue.init(path: path?.appending("/weather.sqlite"))
        dbQueue.inDatabase { (db) in
            do {
                // 手动位置表
                try db.executeUpdate("create table if not exists autoLocation(adcode text, latitude float, longitude float, province text, city text, district text, primary key(adcode))", values: nil)
                // 自动地理位置
                try db.executeUpdate("create table if not exists manualLocation(adcode text, latitude float, longitude float, province text, city text, district text, primary key(adcode))", values: nil)
                // 天气信息
                try db.executeUpdate("create table if not exists weather(weather text, adcode text primary key)", values: nil)
            } catch {
                print("创建表失败")
            }
        }
    }
    
    func updateLocation() -> Promise<LocationInfo>  {
        locationTool.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationTool.locationTimeout = 5
        locationTool.reGeocodeTimeout = 5
        
        let (promise, fulfill, reject) = Promise<LocationInfo>.pending()
        
        locationTool.requestLocation(withReGeocode: true) { (location, reGeocode, error) in
            if let error = error {
                reject(error as NSError)
            }
            let locationInfo:LocationInfo = LocationInfo.init()
            if let location = location {
                locationInfo.latitude = location.coordinate.latitude
                locationInfo.longitude = location.coordinate.longitude
            }
            if let reGeocode = reGeocode {
                locationInfo.city = reGeocode.city
                locationInfo.district = reGeocode.district
                locationInfo.adcode = reGeocode.adcode
            }
            fulfill(locationInfo)
        }
        return promise
    }
    
    func search(address:String) -> Promise<Array<LocationInfo>> {
        searchTool.delegate = self
        let (promise, fulfill, reject) = Promise<Array<LocationInfo>>.pending()
        let request = AMapGeocodeSearchRequest()
        request.address = address
        searchTool.aMapGeocodeSearch(request)
        locationRequset.updateValue((fulfill, reject), forKey: request)
        return promise
    }
    
    func onGeocodeSearchDone(_ request: AMapGeocodeSearchRequest!, response: AMapGeocodeSearchResponse!) {
        if locationRequset[request] != nil {
            let (fulfill, reject) = locationRequset[request]!
            if response.count > 0 {
                var locations:Array<LocationInfo> = []
                for geocode in response.geocodes {
                    let locationInfo = LocationInfo.init()
                    locationInfo.province = geocode.province ?? nil
                    locationInfo.city = geocode.city ?? nil
                    locationInfo.district = geocode.district ?? nil
                    locationInfo.latitude = Double(geocode.location.latitude)
                    locationInfo.longitude = Double(geocode.location.longitude)
                    locationInfo.adcode = geocode.adcode ?? nil
                    locations.append(locationInfo)
                }
                if locations.count > 0 {
                    fulfill(locations)
                } else {
                    reject(NSError.init(domain: "没有搜索结果", code: 9999, userInfo: nil))
                }
            } else {
                reject(NSError.init(domain: "没有搜索结果", code: 9999, userInfo: nil))
            }
            locationRequset.removeValue(forKey: request)
        }
    }
    
    // MARK:数据库操作
    func saveLocation(location:LocationInfo, type:LocationType) -> Promise<Bool> {
        let (promise, fulfill, reject) = Promise<Bool>.pending()
        DispatchQueue.global(qos: .userInitiated).async {
            self.dbQueue.inDatabase { (db) in
                do {
                    if type == LocationType.Auto {
                        try db.executeUpdate("delete from autoLocation", values: [])
                        try db.executeUpdate("insert into autoLocation (adcode, latitude, longitude, province, city, district) values (?, ?, ?, ?, ?, ?)", values: [location.adcode, location.latitude ?? 0.0, location.longitude ?? 0.0, location.province ?? "", location.city ?? "", location.district ?? ""])
                    } else {
                        try db.executeUpdate("delete from manualLocation where adcode = ?", values: [location.adcode])
                        try db.executeUpdate("insert into manualLocation (adcode, latitude, longitude, province, city, district) values (?, ?, ?, ?, ?, ?)", values: [location.adcode, location.latitude ?? 0.0, location.longitude ?? 0.0, location.province ?? "", location.city ?? "", location.district ?? ""])
                    }
                    fulfill(true)
                    NotificationCenter.default.post(LocationUpdate)
                } catch {
                    reject(error)
                }
            }
        }
        return promise
    }
    
    func saveWeather(weatherInfo:NSDictionary!, adcode:String!) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.dbQueue.inDatabase({ (db) in
                do {
                    try db.executeUpdate("delete from weather where adcode = ?", values: [adcode])
                    try db.executeUpdate("insert into weather (adcode, weather) values (?, ?)", values: [adcode ?? "", JSON.init(rawValue: weatherInfo)?.rawString()! ?? ""])
                    NotificationCenter.default.post(WeatherUpdate)
                } catch {
                    do {
                        try db.executeUpdate("update weather set weather = ? where adcode = ?", values: [JSON.init(rawValue: weatherInfo)?.rawString()! ?? "", adcode ?? ""])
                        NotificationCenter.default.post(WeatherUpdate)
                    } catch {}
                }
            })
        }
    }
    
    func queryWeather(adcode:String!) -> Promise<NSDictionary?> {
        let (promise, fulfill, reject) = Promise<NSDictionary?>.pending()
        DispatchQueue.global(qos: .userInitiated).async {
            if (adcode == nil) {
                
            }
            self.dbQueue.inDatabase({ (db) in
                do {
                    let result:FMResultSet = try db.executeQuery("select * from weather where adcode = ?", values: [adcode])
                    var weatherInfo:NSDictionary?
                    while result.next() {
                        let value = result.string(forColumn: "weather")
                        weatherInfo = JSON.init(parseJSON: value!).dictionaryObject as NSDictionary?
                    }
                    fulfill(weatherInfo)
                } catch {
                    reject(error)
                }
            })
        }
        return promise
    }
    
    func queryManualLocations(queue:DispatchQueue = DispatchQueue.global(qos: .userInitiated)) -> Promise<Array<LocationInfo>?> {
        let (promise, fulfill, _) = Promise<Array<LocationInfo>?>.pending()
        queue.async {
            self.dbQueue.inDatabase({ (db) in
                do {
                    let result:FMResultSet = try db.executeQuery("select * from manualLocation", values: nil)
                    var locations:Array<LocationInfo> = []
                    while result.next() {
                        let location = LocationInfo.init()
                        location.adcode = result.string(forColumn: "adcode")!
                        location.latitude = result.double(forColumn: "latitude")
                        location.longitude = result.double(forColumn: "longitude")
                        location.province = result.string(forColumn: "province")!
                        location.city = result.string(forColumn: "city")!
                        location.district = result.string(forColumn: "district")!
                        location.type = LocationType.Manual
                        locations.append(location)
                    }
                    fulfill(locations)
                } catch {
                    fulfill(nil)
                }
            })
        }
        return promise
    }
    
    func queryAutoLocation(queue:DispatchQueue = DispatchQueue.global(qos: .userInitiated), update:Bool = true) -> Promise<LocationInfo?> {
        let (promise, fulfill, _) = Promise<LocationInfo?>.pending()
        queue.async {
            self.dbQueue.inDatabase({ (db) in
                do {
                    let result:FMResultSet = try db.executeQuery("select * from autoLocation", values: nil)
                    var autoLocation:LocationInfo?
                    while result.next() {
                        let location = LocationInfo.init()
                        location.adcode = result.string(forColumn: "adcode")!
                        location.latitude = result.double(forColumn: "latitude")
                        location.longitude = result.double(forColumn: "longitude")
                        location.province = result.string(forColumn: "province")!
                        location.city = result.string(forColumn: "city")!
                        location.district = result.string(forColumn: "district")!
                        location.type = LocationType.Auto
                        autoLocation = location
                    }
                    if update && autoLocation == nil {
                        _ = self.updateLocation().then(execute: { (location) -> Void in
                            fulfill(location)
                        })
                    } else {
                        fulfill(autoLocation)
                    }
                } catch {
                    fulfill(nil)
                }
            })
        }
        return promise
    }
    
    func addObserver(start:@escaping AddressHandlerStart, success:@escaping AddressHandlerSuccess, error:@escaping AddressHandlerError) -> Void {
        startHandlers.add(start)
        successHandlers.add(success)
        errorHandlers.add(error)
    }
    
    func removeObserver(start:@escaping AddressHandlerStart, success:@escaping AddressHandlerSuccess, error:@escaping AddressHandlerError) -> Void {
        startHandlers.remove(start)
        successHandlers.remove(success)
        errorHandlers.remove(error)
    }
}
