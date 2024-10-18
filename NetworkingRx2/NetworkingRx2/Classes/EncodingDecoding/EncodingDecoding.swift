//
//  EncodingDecoding.swift
//  NetworkingRx2
//
//  Created by khanhnvm on 22/7/24.
//

import Foundation

struct URLEncoding {
    static func encode(_ request: URLRequest, with parameters: Encodable?) throws -> URLRequest {
        guard let parameters = parameters else { return request }
        
        var encodedURLRequest = request
        
        guard let url = encodedURLRequest.url else {
            throw NetworkError.invalidURL
        }
        
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            urlComponents.queryItems = try URLEncoding.queryItems(from: parameters)
            encodedURLRequest.url = urlComponents.url
        }
        
        return encodedURLRequest
    }
    
    private static func queryItems(from parameters: Encodable) throws -> [URLQueryItem] {
        let data = try JSONEncoder().encode(parameters)
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        
        return queryItems(from: jsonObject)
    }
    
    private static func queryItems(from jsonObject: Any) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        if let dictionary = jsonObject as? [String: Any] {
            for (key, value) in dictionary {
                items.append(contentsOf: queryItems(fromKey: key, value: value))
            }
        }
        
        return items
    }
    
    private static func queryItems(fromKey key: String, value: Any) -> [URLQueryItem] {
        var items: [URLQueryItem] = []
        
        if let dictionary = value as? [String: Any] {
            for (nestedKey, nestedValue) in dictionary {
                items.append(contentsOf: queryItems(fromKey: "\(key)[\(nestedKey)]", value: nestedValue))
            }
        } else if let array = value as? [Any] {
            for nestedValue in array {
                items.append(contentsOf: queryItems(fromKey: "\(key)[]", value: nestedValue))
            }
        } else {
            items.append(URLQueryItem(name: key, value: "\(value)"))
        }
        
        return items
    }
}

// MARK: - JSONEncoding
struct JSONEncoding {
    static func encode(_ request: URLRequest, with parameters: Encodable?, jsonEncoder: JSONEncoder) throws -> URLRequest {
        guard let parameters = parameters else { return request }
        
        var encodedURLRequest = request
        
        do {
            let data = try jsonEncoder.encode(parameters)
            encodedURLRequest.httpBody = data
            encodedURLRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
            throw NetworkError.encodingError
        }
        
        return encodedURLRequest
    }
}
