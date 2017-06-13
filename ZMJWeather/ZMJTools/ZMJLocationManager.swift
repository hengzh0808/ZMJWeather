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

@objc class LocationInfo:NSObject {
    var latitude:Double!
    var longitude:Double!
    var province:String! // 省
    var city:String! // 市
    var district:String! // 区
}

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
                // 地理位置表
                try db.executeUpdate("create table if not exists location(latitude float, longitude float, province text, city text, district text)", values: nil)
            } catch {}
            
            do {
                // 天气信息
                try db.executeUpdate("create table if not exists weather(weather text)", values: nil)
            } catch {}
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
                    locationInfo.province = (geocode.province != nil && (geocode.province as NSString).length > 0) ? geocode.province : nil
                    locationInfo.city = (geocode.city != nil && (geocode.city as NSString).length > 0) ? geocode.city : nil
                    locationInfo.district = (geocode.district != nil && (geocode.district as NSString).length > 0) ? geocode.district : nil
                    locationInfo.latitude = Double(geocode.location.latitude)
                    locationInfo.longitude = Double(geocode.location.longitude)
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
    
    func save(location:LocationInfo) -> Promise<Bool> {
        let (promise, fulfill, reject) = Promise<Bool>.pending()
        DispatchQueue.global(qos: .userInitiated).async {
            self.dbQueue.inDatabase { (db) in
                do {
                    try db.executeUpdate("insert into location values(?,?,?,?,?)", values: [location.latitude ?? "", location.longitude ?? 0.0, location.province ?? 0.0, location.city ?? "", location.district ?? ""])
                    fulfill(true)
                } catch {
                    reject(error)
                }
            }
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
