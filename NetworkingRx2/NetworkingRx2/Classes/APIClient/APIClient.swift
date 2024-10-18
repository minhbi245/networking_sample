//
//  APIClient.swift
//  NetworkingRx2
//
//  Created by khanhnvm on 22/7/24.
//

import Foundation
import UIKit
import RxSwift

public protocol APIClientProtocol {
    func performRequest<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) -> Observable<T>
    func performRequest(_ endpoint: Endpoint) -> Completable
    func upload(_ endpoint: Endpoint, data: Data, mimeType: String) -> Observable<Data>
    func download(_ endpoint: Endpoint) -> Observable<(Data, URLResponse)>
}

public class APIClient: APIClientProtocol {
    private let networkService: NetworkServiceProtocol
    
    public init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    public func performRequest<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) -> Observable<T> {
        return networkService.request<T>(endpoint, responseType: responseType)
    }
    
    public func performRequest(_ endpoint: Endpoint) -> Completable {
        return networkService.request(endpoint)
    }
    
    public func upload(_ endpoint: Endpoint, data: Data, mimeType: String) -> Observable<Data> {
        return networkService.upload(endpoint, data: data, mimeType: mimeType)
    }
    
    public func download(_ endpoint: Endpoint) -> Observable<(Data, URLResponse)> {
        return networkService.download(endpoint)
    }
}
