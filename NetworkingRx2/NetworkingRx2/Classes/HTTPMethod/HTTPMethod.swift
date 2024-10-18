//
//  HTTPMethod.swift
//  NetworkingRx2
//
//  Created by khanhnvm on 22/7/24.
//

import Foundation
import UIKit

// MARK: - HTTP Methods
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - HTTPHeaders
public typealias HTTPHeaders = [String: String]
