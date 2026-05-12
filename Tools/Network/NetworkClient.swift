import Foundation

enum NetworkError: Error {
    case networkDisabled
    case invalidURL
    case requestFailed(String)
    case invalidResponse
    case decodingError
}

class NetworkClient {
    static let shared = NetworkClient()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }
    
    func request(
        url: String,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Any? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        guard NetworkSettings.shared.isNetworkEnabled else {
            throw NetworkError.networkDisabled
        }
        
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            if let jsonBody = body as? [String: Any] {
                request.httpBody = try? JSONSerialization.data(withJSONObject: jsonBody)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            } else if let stringBody = body as? String {
                request.httpBody = stringBody.data(using: .utf8)
            }
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NetworkError.requestFailed("HTTP \(httpResponse.statusCode): \(message)")
        }
        
        return (data, httpResponse)
    }
    
    func getJSON<T: Decodable>(
        url: String,
        headers: [String: String] = [:]
    ) async throws -> T {
        let (data, _) = try await request(url: url, method: "GET", headers: headers)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
    
    func postJSON<T: Decodable>(
        url: String,
        body: [String: Any],
        headers: [String: String] = [:]
    ) async throws -> T {
        var allHeaders = headers
        allHeaders["Content-Type"] = "application/json"
        let (data, _) = try await request(url: url, method: "POST", headers: allHeaders, body: body)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}
