//
//  File.swift
//
//
//  Created by Brian Anglin on 2/3/21.
//
import UIKit
import Foundation

internal class Network {
    internal var userId:String?
    internal static let shared = Network()
    
    internal let baseURL: URL
    internal let analyticsBaseURL: URL
    internal let urlSession: URLSession
    
    
    public init(
        urlSession: URLSession = URLSession(configuration: .ephemeral),
//        baseURL: URL = URL(string: "https://paywall-next.herokuapp.com/api/v1/")!,
        baseURL: URL = URL(string: "https://api.superwall.dev/api/v1/")!,
//         baseURL: URL = URL(string: "https://3000-scarlet-guppy-4bhnibfc.ws-us13.gitpod.io/api/v1/")!,
        analyticsBaseURL: URL = URL(string: "https://collector.superwall.dev/v1/")!) {
        
        self.urlSession = (urlSession)
        self.baseURL = baseURL
        self.analyticsBaseURL = analyticsBaseURL
    }
}



extension Network {
    enum Error: LocalizedError {
        case unknown
        case notAuthenticated
        case decoding
        
        var errorDescription: String? {
            switch self {
                case .unknown: return NSLocalizedString("An unknown error occurred.", comment: "")
                case .notAuthenticated: return NSLocalizedString("Unauthorized.", comment: "")
                case .decoding: return NSLocalizedString("Decoding error.", comment: "")
            }
        }
    }
}

// MARK: Private extension for actually making requests
extension Network {
    func send<ResponseType: Decodable>(_ request: URLRequest, completion: @escaping (Result<ResponseType, Swift.Error>) -> Void) {
        var request = request

        request.setValue("Bearer " + (Store.shared.apiKey ?? ""), forHTTPHeaderField:  "Authorization")
        request.setValue("iOS", forHTTPHeaderField: "X-Platform")
        request.setValue("SDK", forHTTPHeaderField: "X-Platform-Environment")
        request.setValue(Store.shared.appUserId ?? "", forHTTPHeaderField: "X-App-User-ID")
        request.setValue(Store.shared.aliasId ?? "", forHTTPHeaderField: "X-Alias-ID")
        request.setValue(DeviceHelper.shared.vendorId, forHTTPHeaderField: "X-Vendor-ID")
        request.setValue(DeviceHelper.shared.appVersion, forHTTPHeaderField: "X-App-Version")
        request.setValue(DeviceHelper.shared.osVersion, forHTTPHeaderField: "X-OS-Version")
        request.setValue(DeviceHelper.shared.model, forHTTPHeaderField: "X-Device-Model")
        request.setValue(DeviceHelper.shared.locale, forHTTPHeaderField: "X-Device-Locale") // en_US, en_GB
        request.setValue(DeviceHelper.shared.languageCode, forHTTPHeaderField: "X-Device-Language-Code") // en
        request.setValue(DeviceHelper.shared.currencyCode, forHTTPHeaderField: "X-Device-Currency-Code") // USD
        request.setValue(DeviceHelper.shared.currencySymbol, forHTTPHeaderField: "X-Device-Currency-Symbol") // $
        
        let task = self.urlSession.dataTask(with: request) { (data, response, error) in
            do {
                guard let unWrappedData = data else { return completion(.failure(error ?? Error.unknown))}
                
                if let response = response as? HTTPURLResponse, response.statusCode == 401 {
                    Logger.superwallDebug(string: "Unable to authenticate, please make sure your Superwall API KEY is correct.")
                    return completion(.failure(Error.notAuthenticated))
                }
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let response = try decoder.decode(ResponseType.self, from: unWrappedData)
                completion(.success(response))
            } catch let error {
                Logger.superwallDebug(string: "Error requesting: \(request.url?.absoluteString ?? "unknown absolute string")")
                Logger.superwallDebug(string: "Unable to decode response to type \(ResponseType.self)", error: error)
                Logger.superwallDebug(string: String(decoding: data ?? Data(), as: UTF8.self))
                completion(.failure(Error.decoding))
            }
        }
        task.resume()
        
        
    }
}



extension Network {
    func events(events: EventsRequest, completion: @escaping (Result<EventsResponse, Swift.Error>) -> Void) {
        let components = URLComponents(string: "events")!
        let requestURL = components.url(relativeTo: analyticsBaseURL)!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        // Bail if we can't encode
        do {
            request.httpBody = try encoder.encode(events)
        } catch {
            return completion(.failure(Error.unknown))
        }

        print(String(data: request.httpBody ?? Data(), encoding: .utf8)!)

        send(request, completion: { (result: Result<EventsResponse, Swift.Error>)  in
            switch result {
                case .failure(let error):
                    Logger.superwallDebug(string: "[network POST /events] - failure")
                    completion(.failure(error))
                case .success(let response):
                    completion(.success(response))
            }

        })
    }
}

extension Network {
    func identify(identifyRequest: IdentifyRequest, completion: @escaping (Result<IdentifyResponse, Swift.Error>) -> Void) {
        let components = URLComponents(string: "identify")!
        let requestURL = components.url(relativeTo: baseURL)!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        // Bail if we can't encode
        do {
            request.httpBody = try encoder.encode(identifyRequest)
        } catch {
            return completion(.failure(Error.unknown))
        }

        print(String(data: request.httpBody ?? Data(), encoding: .utf8)!)

        send(request, completion: { (result: Result<IdentifyResponse, Swift.Error>)  in
            switch result {
                case .failure(let error):
                    Logger.superwallDebug(string: "[network POST /identify] - failure")
                    completion(.failure(error))
                case .success(let response):
                    completion(.success(response))
            }

        })
    }
}



extension Network {
    func paywall(completion: @escaping (Result<PaywallResponse, Swift.Error>) -> Void) {
        
        let paywallRequest = PaywallRequest(appUserId: Store.shared.userId ?? "")
        
        let components = URLComponents(string: "paywall")!
        let requestURL = components.url(relativeTo: baseURL)!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        // Bail if we can't encode
        do {
            request.httpBody = try encoder.encode(paywallRequest)
        } catch {
            return completion(.failure(Error.unknown))
        }
        
        print(String(data: request.httpBody ?? Data(), encoding: .utf8)!)
        
        send(request, completion: { (result: Result<PaywallResponse, Swift.Error>)  in
            switch result {
                case .failure(let error):
                    Logger.superwallDebug(string: "[network POST /paywall] - failure")
                    completion(.failure(error))
                case .success(let response):
                    completion(.success(response))
            }
            
        })

    }
}