//
//  APIRequests.swift
//  Spark
//
//  Created by Fahed Al-Ahmad on 2/25/19.
//  Copyright © 2019 alahmadfahed. All rights reserved.
//

import Foundation

enum APIRequests
{
    // All API Requests
    case signUp(firstname: String, email_id: String, phone_no: String,
        password: String, confirm_password: String, country: String)
    case getTimes()
    
    // All API Paths
    var path: String
    {
        switch self
        {
            
        case .signUp:
            return "/signUp"
        case .getTimes:
            return "/times"
            
        }
    }
    
    // All API methods
    var method: HTTPMethods
    {
        switch self
        {
            
        case .signUp:
            return .post
        case .getTimes:
            return .get
        }
    }
    
    var contentType:ContentType
    {
        switch self
        {
            
        case .signUp, .getTimes:
            return .json
        }
    }
    
    // API Params to dictionary
    var parameters: [String : Any]!
    {
        switch self
        {
            
        case .signUp(let firstname, let email_id, let phone_no,
                     let password, let confirm_password, let country):
            return ["firstname": firstname, "email_id": email_id, "phone_no": phone_no,
                    "password": password, "confirm_password": confirm_password, "country": country]
        case .getTimes:
            return nil
        }
    }
}
