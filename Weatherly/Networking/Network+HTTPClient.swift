//
//  Network+HTTPClient.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 17/11/2026.
//

import Foundation

extension Network {
    enum HTTPClient {
        
        // MARK: - ServerError
        
        struct ServerError: Decodable, Sendable {
            let reason: String?
        }

        // MARK: - HTTPError

        enum HTTPError: LocalizedError, Sendable {
            case invalidURL
            case encoding(message: String)
            case downloading(message: String)
            case decoding(message: String)
            case invalidResponse
            case invalidStatusCode(statusCode: Int)
            case server(message: String, statusCode: Int)
        }

        // MARK: - Request kind

        enum RequestKind: String, Sendable {
            case get, post, put, delete
        }

        // MARK: - Methods

        static func makeURL(
            from urlString: String,
            appendingPath path: String? = nil,
            queryItems: [URLQueryItem] = []
        ) throws(HTTPError) -> URL {
            var components = URLComponents(string: urlString)
            if let path, !path.isEmpty {
                components?.path += path
            }
            if !queryItems.isEmpty {
                components?.queryItems = queryItems
            }
            guard let url = components?.url else {
                throw .invalidURL
            }
            return url
        }

        static func makeBody<Body: Encodable>(from body: Body) throws(HTTPError) -> Data {
            do {
                return try JSONEncoder().encode(body)
            } catch {
                throw .encoding(message: error.localizedDescription)
            }
        }

        static func makeRequest(
            for url: URL,
            method: RequestKind = .get,
            body: Data? = nil,
            timeout: TimeInterval = 30.0
        ) -> URLRequest {
            var request = URLRequest(
                url: url,
                cachePolicy: .useProtocolCachePolicy,
                timeoutInterval: timeout
            )
            request.httpMethod = method.rawValue.uppercased()
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            if body != nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            return request
        }
        
        static func data(
            for request: URLRequest
        ) async throws(HTTPError) -> (data: Data, response: URLResponse) {
            do {
                return try await URLSession.shared.data(for: request)
            } catch {
                throw .downloading(message: error.localizedDescription)
            }
        }
        
        static func handle(
            data: Data,
            response: URLResponse
        ) throws(HTTPError) {
            guard let httpResponse = response as? HTTPURLResponse else {
                throw .invalidResponse
            }
            if (200..<300).contains(httpResponse.statusCode) {
                return
            }
            guard let error = try? JSONDecoder().decode(ServerError.self, from: data),
                  let reason = error.reason
            else {
                throw .invalidStatusCode(statusCode: httpResponse.statusCode)
            }
            throw .server(message: reason, statusCode: httpResponse.statusCode)
        }

        static func decode<Response: Decodable>(
            _ data: Data,
            as type: Response.Type
        ) throws(HTTPError) -> Response {
            do {
                return try JSONDecoder().decode(type, from: data)
            } catch {
                throw .decoding(message: error.localizedDescription)
            }
        }
    }
}

// MARK: - Error descriptions

extension Network.HTTPClient.HTTPError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Nie udało się zbudować poprawnego adresu URL."
        case let .encoding(message):
            "Nie udało się zakodować danych żądania: \(message)."
        case let .downloading(message):
            "Nie udało się pobrać danych: \(message)."
        case let .decoding(message):
            "Nie udało się odczytać odpowiedzi serwera: \(message)."
        case .invalidResponse:
            "Serwer zwrócił nieprawidłową odpowiedź."
        case let .invalidStatusCode(statusCode):
            "Serwer zwrócił błąd HTTP: \(statusCode)."
        case let .server(message, statusCode):
            "Serwer zwrócił błąd HTTP: \(statusCode) -> \(message)."
        }
    }
}
