//
//  ZMJLocationManager.swift
//  ZMJWeather
//
//  Created by zhangheng on 2017/5/31.
//  Copyright © 2017年 zhangheng. All rights reserved.
//

import UIKit
import CoreLocation
import PromiseKit

@objc class LocationInfo:NSObject {
    var latitude:Double!
    var longitude:Double!
    var locality:String!
    var subLocality:String!
}

typealias AddressHandlerStart = @convention(block) () -> Void
typealias AddressHandlerSuccess = @convention(block) (LocationInfo) -> Void
typealias AddressHandlerError = @convention(block) (String) -> Void

let locationManager:ZMJLocationManager = ZMJLocationManager.init()
class ZMJLocationManager: NSObject {
    
    private var startHandlers:NSMutableArray = NSMutableArray.init()
    private var successHandlers:NSMutableArray = NSMutableArray.init()
    private var errorHandlers:NSMutableArray = NSMutableArray.init()
    
    func updateLocation() -> Promise<LocationInfo>  {
        
        return Promise.init(resolvers: { (resolve, reject) in
            CLLocationManager.promise().then { (location) -> Promise<CLPlacemark> in
                return CLGeocoder().reverseGeocode(location: location)
            }.then { (address) -> Void in
                let locationInfo:LocationInfo = LocationInfo.init()
                locationInfo.locality = address.locality!
                locationInfo.subLocality = address.subLocality!
                locationInfo.longitude = address.location?.coordinate.longitude
                locationInfo.latitude = address.location?.coordinate.latitude
                resolve(locationInfo)
            }.catch { (error) in
                reject(error)
            }
        })
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
