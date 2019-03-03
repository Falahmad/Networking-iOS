//
//  APIRouter.swift
//  NetworkingLayer
//
//  Copyright © 2018 Fahed Alahmad. All rights reserved.
//

import Foundation
import UIKit

protocol APIConfigurationProtocol: AnyObject {
    var serverAuth: ServerAuth?{get set}
    var devURL:String{get}
    var proURL:String{get}
    var email:String{get}
    var password:String{get}
    
    func initRequest(APIRequests: APIRequests) throws -> URLRequest
    func decodingTask<T: Decodable>(with APIRequests: APIRequests, decodingType: T.Type, from: String?, completionHandler completion: @escaping (T?, Any? ,String?)->Void) -> URLSessionDataTask
    func createBodyWithParameters(parameters: [String: Any]!, boundary: String) -> NSData
}

protocol APIClient {
    func requestJSONResponse<T: Decodable>(request: APIRequests, model: T.Type, from: String?, completion: @escaping (Result<T, APIErrorObjc>) -> Void)
    func loadImageUsingCacheWithUrlString(APIRequests: APIRequests, imagePath: String, completion: @escaping (UIImage, NSError?)->())
}

class APIRoute: APIConfigurationProtocol
{
  
    
    // Our singletone
    static let shared:APIRoute = APIRoute()
    private init(){}
    
    // Development,Production URL
    internal final var devURL:String{ return "http://alfareekkw.com/ozone/admin/index.php/Webservice_App" }
    internal final var proURL:String{ return "" }
    
    // Server Authentication
    internal final var email:String{ return "" }
    internal final var password:String{ return "" }
    
    internal var serverAuth: ServerAuth?
    
    internal func initRequest(APIRequests: APIRequests) throws -> URLRequest
    {
        var request:URLRequest
        // Check if authentication has provided
        if self.serverAuth != nil  {
            // URL
            let url = URL(string: devURL)
            //            let url = try proURL.asURL()
            request = URLRequest(url: url!.appendingPathComponent(APIRequests.path))
            
            // HTTP Method
            request.httpMethod = APIRequests.method.rawValue
            
            // MARK: Headers
            
            // Accept type
//            request.setValue(ContentType.json.rawValue,forHTTPHeaderField: HTTPHeaderField.acceptType.rawValue)
            
            // Accept Encoding
//            request.setValue(ContentType.json.rawValue,forHTTPHeaderField: HTTPHeaderField.acceptEncoding.rawValue)
            
            
            request.setValue(HTTPHeaderField.APIKey.rawValue,forHTTPHeaderField:HTTPHeaderField.APIKeyHeader.rawValue)
            request.setValue(self.serverAuth!.language,forHTTPHeaderField:HTTPHeaderField.language.rawValue)
            request.setValue(self.serverAuth!.auth,forHTTPHeaderField:HTTPHeaderField.authentication.rawValue)
            
            // Device Info
//            request.setValue(self.serverAuth!.language,forHTTPHeaderField:HTTPHeaderField.language.rawValue)
            
//            request.setValue(self.serverAuth!.deviceName,forHTTPHeaderField:HTTPHeaderField.deviceName.rawValue)
//            request.setValue(self.serverAuth!.deviceType,forHTTPHeaderField:HTTPHeaderField.deviceType.rawValue)
//            request.setValue(self.serverAuth!.deviceUUID,forHTTPHeaderField:HTTPHeaderField.deviceUUID.rawValue)
//            request.setValue(self.serverAuth!.deviceToken,forHTTPHeaderField:HTTPHeaderField.deviceToken.rawValue)
            
            // Parameters
            if APIRequests.method == .post
            {
                let params:[String : Any] = APIRequests.parameters
                switch APIRequests.contentType
                {
                case .json:
                    // ContentType
                    request.setValue(APIRequests.contentType.getType(boundary: nil),forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
                    request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
                case .multiPartForm:
                    let boundary = "".generateBoundaryString()
                    // ContentType
                    request.setValue(APIRequests.contentType.getType(boundary: boundary),forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
                    request.httpBody = createBodyWithParameters(parameters: params, boundary: boundary) as Data
                case.form:
                    // ContentType
                    request.setValue(APIRequests.contentType.getType(boundary: nil),forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
                    request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions())
                }
            }
        } else {
            throw URLError(.userAuthenticationRequired)
        }
        return request
    }
    
    internal func createBodyWithParameters(parameters: [String: Any]!, boundary: String) -> NSData {
        let body = NSMutableData();
        
        for (key, value) in parameters
        {
            if let file = value as? FileRequest
            {
                let filename = file.url
                let mimetype = file.url.mimeType()

                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n")
                body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
                body.append(file.fileData)
                body.appendString(string: "\r\n")
                
            }
            else if let files = value as? [FileRequest]
            {
                files.forEach { (file) in
                    let filename = file.url
                    let mimetype = file.url.mimeType()
                    
                    body.appendString(string: "--\(boundary)\r\n")
                    body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(filename)\"\r\n")
                    body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
                    body.append(file.fileData)
                    body.appendString(string: "\r\n")
                }
            }
            else
            {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString(string: "\(value)\r\n")
            }
        }
        
        body.appendString(string: "--\(boundary)--\r\n")
        
        return body
    }
    
    internal func decodingTask<T: Decodable>(with APIRequests: APIRequests, decodingType: T.Type, from: String?, completionHandler completion: @escaping (T?,Any?, String?)->Void) -> URLSessionDataTask {
        
        var request:URLRequest!
        do {
            request = try initRequest(APIRequests: APIRequests)
        } catch {
            completion(nil,nil, APIError.apiRequest.localizedDescription)
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let data = data, error == nil else {
                // check for fundamental networking error
                completion(nil,nil, APIError.invalidData.localizedDescription)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil,nil, APIError.requestFailed.localizedDescription)
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            
            /* Fail to convert data to utf8 */
            guard let json = responseString!.data(using: String.Encoding.utf8) else{
                completion(nil,nil ,APIError.responseUnsuccessful.localizedDescription)
                return
            }
            
            var anyObject:Any!
    
            /* Fail to decode json */
            /* Response may be dictionary or array of dictionaries */
            do {
                
                /* Response is dictionary */
                if let any
                    = try JSONSerialization.jsonObject(with: json, options : .allowFragments) as? Dictionary<String,Any>{
                    anyObject = any
                }else if let any
                    = try JSONSerialization.jsonObject(with: json, options : .allowFragments) as? [[String: Any]]{
                    /* Response is array of dictionaries */
                    completion(nil,any, nil)
                    return
                }else{
                    completion(nil,nil, APIError.jsonConversionFailure.localizedDescription)
                    return
                }
                
            } catch {
                completion(nil,nil, APIError.jsonConversionFailure.localizedDescription)
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                
                guard let jsonArray = anyObject as? [String: Any] else{return}
                /* Could not found status, just model directly */
                guard  let callBackResponse = jsonArray["status"] as? String else {
                    
                    guard from != nil else{
                        completion(nil,jsonArray, nil)
                        return
                    }
                    
                    do {
                        let jsonDataUser = try JSONSerialization.data(withJSONObject: jsonArray)
                        let genericModel = try? JSONDecoder().decode(decodingType, from: jsonDataUser)
                        completion(genericModel,nil, nil)
                    } catch {
                        completion(nil,nil, APIError.jsonParsingFailure.localizedDescription)
                    }
                    
                    return
                }
                
                
                switch callBackResponse{
                case "success":
                    guard let from = from else{
                        completion(nil,jsonArray, nil)
                        return
                    }
                    
                    do {
                        let jsonDataUser = try JSONSerialization.data(withJSONObject: jsonArray[from]!)
                        let genericModel = try? JSONDecoder().decode(decodingType, from: jsonDataUser)
                        completion(genericModel,nil, nil)
                    } catch {
                        completion(nil,nil, APIError.jsonParsingFailure.localizedDescription)
                    }
                case "failure":
                    var errorMessage = ""
                    
                    if let err = jsonArray["message"] as? String{
                        errorMessage = err
                    } else if let errArray = jsonArray["message"] as? [String]{
                        for error in errArray{
                            errorMessage.append(error)
                            errorMessage.append("\n")
                        }
                    }
                    completion(nil,nil, errorMessage)
                default:
                    break
                }
            case 409:
                completion(nil,nil, "\(APIError.statusCode.localizedDescription): \(httpResponse.statusCode)")
            default:
                completion(nil,nil, "\(APIError.statusCode.localizedDescription): \(httpResponse.statusCode)")
            }
        }
        return task
    
    }
}

// MARK:- Requests
extension APIRoute: APIClient {
    
    func requestJSONResponse<T: Decodable>(request: APIRequests, model: T.Type, from: String? = nil, completion: @escaping (Result<T, APIErrorObjc>) -> Void) {
        
        if !Reachability.isConnectedToNetwork(){
            completion(.failure(APIErrorObjc(error:APIError.internetConnection.localizedDescription)))
            return
        }
        
        Spinner.shared.startAnimating()
        let task = decodingTask(with: request, decodingType: T.self, from: from) { (model, json, error) in
            DispatchQueue.main.async {
                Spinner.shared.stopAnimating()
                
                if let error = error {
                    completion(.failure(APIErrorObjc(error: error)))
                    return
                }
                
                if let model = model{
                    completion(.success(model))
                    return
                }
                
                if let json = json{
                    completion(.successJSON(json))
                    return
                }
            }
        }
        task.resume()
    }
    
    func loadImageUsingCacheWithUrlString(APIRequests: APIRequests, imagePath: String, completion: @escaping (UIImage, NSError?)->())
    {
        var img = UIImage()
        if !Reachability.isConnectedToNetwork() {
            completion(img, nil)
            return
        }
        
        var request:URLRequest!
        do
        {
            request = try initRequest(APIRequests: APIRequests)
            if !imagePath.isEmpty
            {
                request.url = request.url?.appendingPathComponent("/\(imagePath)")
            }
        }
        catch let error as NSError
        {
            completion(img, error)
        }
        
        let imageCache = NSCache<AnyObject, AnyObject>()
        let te = NSMutableDictionary()
        te.removeAllObjects()
        
        if let cachedImage = imageCache.object(forKey: request.url as AnyObject) as? UIImage
        {
            img = cachedImage
            completion(img, nil)
        }
        URLCache.shared.removeAllCachedResponses()
        URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if error != nil {
                completion(img, error! as NSError)
                return
            }
            DispatchQueue.main.async(execute: {
                
                if let downloadedImage = UIImage(data: data!) {
//                    imageCache.setObject(downloadedImage, forKey: request.url as AnyObject)
                    img = downloadedImage
                    completion(img, nil)
                }
            })
        }).resume()
    }
    
    //new download image method
//    func downloaded(from url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
//        contentMode = mode
//        URLSession.shared.dataTask(with: url) { data, response, error in
//            guard
//                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
//                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
//                let data = data, error == nil,
//                let image = UIImage(data: data)
//                else { return }
//            DispatchQueue.main.async() {
//                self.image = image
//            }
//            }.resume()
//    }
//    func downloaded(from link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
//        guard let url = URL(string: link) else { return }
//        downloaded(from: url, contentMode: mode)
//    }
}
