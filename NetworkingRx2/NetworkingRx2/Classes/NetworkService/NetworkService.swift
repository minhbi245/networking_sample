//
//  NetworkService.swift
//  NetworkingRx2
//
//  Created by khanhnvm on 22/7/24.
//

import Foundation
import UIKit
import RxSwift

public protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) -> Observable<T>
    func request(_ endpoint: Endpoint) -> Completable
    func upload(_ endpoint: Endpoint, data: Data, mimeType: String) -> Observable<Data>
    func download(_ endpoint: Endpoint) -> Observable<(Data, URLResponse)>
}


public class NetworkService: NetworkServiceProtocol {
    private let urlSession: URLSession
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    
    public init(urlSession: URLSession = .shared,
         jsonEncoder: JSONEncoder = JSONEncoder(),
         jsonDecoder: JSONDecoder = JSONDecoder()) {
        self.urlSession = urlSession
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }
    
    public func request<T>(_ endpoint: any Endpoint, responseType: T.Type) -> RxSwift.Observable<T> where T : Decodable {
        return Observable.create { [weak self] observer in
            guard let `self` = self else {
                observer.onError(NetworkError.unknownError)
                return Disposables.create()
            }
            
            do {
                let request = try self.createURLRequest(from: endpoint)
                let task = self.urlSession.dataTask(with: request) { data, response, error in
                    if let error = error {
                        observer.onError(error)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        observer.onError(NetworkError.unknownError)
                        return
                    }
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        observer.onError(NetworkError.serverError(statusCode: httpResponse.statusCode, data: data))
                        return
                    }
                    
                    guard let data = data  else {
                        observer.onError(NetworkError.noData)
                        return
                    }
                    
                    do {
                        if let jsonString = String(data: data, encoding: .utf8) {
                            debugPrint("Received JSON: \(jsonString)")
                        }
                        let decodeResponse = try self.jsonDecoder.decode(T.self, from: data)
                        observer.onNext(decodeResponse)
                        observer.onCompleted()
                    } catch {
                        debugPrint("Decoding error: \(error)")
                        observer.onError(NetworkError.decodingError)
                    }
                }
                task.resume()
                return Disposables.create {
                    task.cancel()
                }
            } catch {
                observer.onError(NetworkError.invalidURL)
                return Disposables.create()
            }
        }
    }
    
    public func request(_ endpoint: any Endpoint) -> RxSwift.Completable {
        return Completable.create { [weak self] completable in
            guard let `self` = self else {
                completable(.error(NetworkError.unknownError))
                return Disposables.create()
            }
            
            do {
                let request = try self.createURLRequest(from: endpoint)
                let task = self.urlSession.dataTask(with: request) { _, response, error in
                    if let error = error {
                        completable(.error(NetworkError.unknownError))
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse  else {
                        completable(.error(NetworkError.unknownError))
                        return
                    }
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        completable(.error(NetworkError.serverError(statusCode: httpResponse.statusCode, data: nil)))
                        return
                    }
                    
                    completable(.completed)
                }
                task.resume()
                return Disposables.create {
                    task.cancel()
                }
            } catch {
                completable(.error(NetworkError.invalidURL))
                return Disposables.create()
            }
        }
    }
    
    public func upload(_ endpoint: any Endpoint, data: Data, mimeType: String) -> RxSwift.Observable<Data> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NetworkError.unknownError)
                return Disposables.create()
            }
            
            do {
                var request = try self.createURLRequest(from: endpoint)
                request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
                
                let task = self.urlSession.uploadTask(with: request, from: data) { data, response, error in
                    if let error = error {
                        observer.onError(NetworkError.unknownError)
                        return
                    }
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        observer.onError(NetworkError.unknownError)
                        return
                    }
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        observer.onError(NetworkError.serverError(statusCode: httpResponse.statusCode, data: data))
                        return
                    }
                    
                    guard let data = data else {
                        observer.onError(NetworkError.noData)
                        return
                    }
                    
                    observer.onNext(data)
                    observer.onCompleted()
                }
                task.resume()
                
                return Disposables.create {
                    task.cancel()
                }
            } catch {
                observer.onError(NetworkError.invalidURL)
                return Disposables.create()
            }
        }
    }
    
    public func download(_ endpoint: any Endpoint) -> RxSwift.Observable<(Data, URLResponse)> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NetworkError.unknownError)
                return Disposables.create()
            }
            
            do {
                let request = try self.createURLRequest(from: endpoint)
                let task = self.urlSession.dataTask(with: request) { data, response, error in
                    if let error = error {
                        observer.onError(NetworkError.unknownError)
                        return
                    }
                    
                    guard let data = data, let response = response else {
                        observer.onError(NetworkError.noData)
                        return
                    }
                    
                    observer.onNext((data, response))
                    observer.onCompleted()
                }
                task.resume()
                
                return Disposables.create {
                    task.cancel()
                }
            } catch {
                observer.onError(NetworkError.invalidURL)
                return Disposables.create()
            }
        }
    }
    
    private func createURLRequest(from endpoint: Endpoint) throws -> URLRequest {
        guard let url = URL(string: endpoint.path, relativeTo: endpoint.baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.headers
        
        switch endpoint.encoding {
        case .urlEncoding:
            request = try URLEncoding.encode(request, with: endpoint.parameters)
        case .jsonEncoding:
            request = try JSONEncoding.encode(request, with: endpoint.parameters, jsonEncoder: jsonEncoder)
        case .customEncoding(let encoder):
            request.httpBody = encoder()
        }
        return request
    }
}
