//
//  Endpoint.swift
//  NetworkingRx2
//
//  Created by khanhnvm on 22/7/24.
//

import Foundation
import UIKit

// MARK: - Endpoint
public protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: HTTPHeaders? { get }
    var parameters: Encodable? { get }
    var encoding: ParameterEncoding { get }
}

// MARK: - ParameterEncoding
public enum ParameterEncoding {
    case urlEncoding
    case jsonEncoding
    case customEncoding(() -> Data?)
}
