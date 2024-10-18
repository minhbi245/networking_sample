//
//  NetworkError.swift
//  NetworkingRx2
//
//  Created by khanhnvm on 22/7/24.
//

import Foundation
import UIKit

public enum NetworkError: Error {
    case invalidURL
    case noData
    case encodingError
    case decodingError
    case serverError(statusCode: Int, data: Data?)
    case unknownError
}
