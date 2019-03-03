//
//  Constants.swift
//  NetworkingLayer
//
//  Created by Vavisa - iMac 2 on 4/8/18.
//  Copyright © 2018 Omar basaleh. All rights reserved.
//

import Foundation

struct ServerAuth
{
    var auth: String?
    let deviceName: String
    var deviceToken: String?
    let deviceUUID: String
    let deviceType: String
    var language: String?
    
    init(authType: AuthorizationTypes, authToken: String?, deviceName: String, deviceUUID: String, deviceToken: String?, deviceType: DeviceTypes, language: HeaderLanguages?)
    {
        if authToken == nil
        {
            self.auth = nil
        }
        else
        {
            self.auth = "\(authType.rawValue) \(authToken!)"
        }
        self.deviceName = deviceName
        self.deviceUUID = deviceUUID
        self.deviceToken = deviceToken
        self.deviceType = deviceType.rawValue
        self.language = language?.rawValue != nil ? language!.rawValue : nil
    }
    
    mutating func setAuth(authType: AuthorizationTypes, authToken: String)
    {
        self.auth = "\(authType.rawValue) \(authToken)"
    }
}

enum HTTPHeaderField: String
{
    case authentication = "Authorization"
    case contentType = "Content-Type"
    case acceptType = "Accept"
    case acceptEncoding = "Accept-Encoding"
    
    case secretKey = "Secret-Key"
    case APIKeyHeader = "X-API-KEY"
    case APIKey = "C1CDB2F6E7A948A80E802877980A309B"
   
    case language = "Accept-Language"
    case deviceName = "device-name"
    case deviceToken = "device-token"
    case deviceUUID = "device-uuid"
    case deviceType = "device-type"
}

enum DeviceTypes: String
{
    case ios = "iOS"
    case android = "Android"
}

enum HeaderLanguages: String
{
    case english = "en"
    case arabic = "ar"
}

enum ContentType
{
    case json
    case multiPartForm
    case form
    
    func getType(boundary:String?)->String
    {
        switch self {
        
        case .json:
            return "application/json";
        case .multiPartForm:
            return "multipart/form-data; boundary=\(boundary!)";
        case .form:
            return "application/x-www-form-urlencoded";
        }
    }
}

enum AuthorizationTypes:String
{
    case bearer = "Bearer "
    case key = ""
}

enum HTTPMethods:String
{
    case post = "POST"
    case get = "GET"
}

struct FileRequest
{
    let fileData:Data
    let url:URL
}


enum APIError: Error {
    case apiRequest
    case requestFailed
    case responseNotFound
    case internetConnection
    case jsonConversionFailure
    case statusCode
    case invalidData
    case responseUnsuccessful
    case jsonParsingFailure
    
    var localizedDescription: String {
        switch self {
        case .apiRequest: return "API Request"
        case .requestFailed: return "Request Failed"
        case .responseNotFound: return "Response not found"
        case .internetConnection: return "No internet connection"
        case .statusCode: return "status Code"
        case .invalidData: return "Invalid Data"
        case .responseUnsuccessful: return "Response Unsuccessful"
        case .jsonParsingFailure: return "JSON Parsing Failure"
        case .jsonConversionFailure: return "JSON Conversion Failure"
        }
    }
}

struct ResponseMessage: Decodable {
    let message:String
}

struct APIErrorObjc: Error {
    private let error:String
    
    init(error:String) {
        self.error = error
    }
    
    func getError()->String
    {
        return error
    }
}

enum Result<T, U> where U: Error  {
    case success(T)
    case successJSON(Any)
    case failure(U)
}


// MARK:- Extentions
extension NSMutableData {
    func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}

extension String{
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}
