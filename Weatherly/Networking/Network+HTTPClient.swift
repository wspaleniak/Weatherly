//
//  Network+HTTPClient.swift
//  Weatherly
//
//  Created by Wojciech Spaleniak on 17/11/2026.
//

import Foundation

extension Network {
    /// Builds HTTP requests, executes them with a supplied session or `URLSession.shared`,
    /// and converts responses into typed values.
    ///
    /// Use the helper methods to construct a URL and request, fetch response data,
    /// validate the HTTP status, and decode a successful response.
    enum HTTPClient {
        
        // MARK: - ServerError
        
        /// Represents the error payload returned by an API server.
        struct ServerError: Decodable, Sendable {
            /// A human-readable explanation supplied by the server, when available.
            let reason: String?
        }

        // MARK: - HTTPError

        /// Describes failures that can occur while preparing or processing an HTTP request.
        enum HTTPError: LocalizedError, Sendable {
            /// The supplied URL string could not be converted to a URL.
            case invalidURL
            /// The request body could not be encoded as JSON.
            case encoding(message: String)
            /// The request failed while communicating with the server.
            case downloading(message: String)
            /// The response body could not be decoded into the requested type.
            case decoding(message: String)
            /// The response was not an HTTP response.
            case invalidResponse
            /// The server returned a non-success HTTP status without a decodable error payload.
            case invalidStatusCode(statusCode: Int)
            /// The server returned a non-success HTTP status and an error message.
            case server(message: String, statusCode: Int)
        }

        // MARK: - Request kind

        /// The HTTP method used to create a request.
        enum RequestKind: String, Sendable {
            /// Retrieves a resource.
            case get
            /// Submits data to create or process a resource.
            case post
            /// Replaces a resource with the supplied data.
            case put
            /// Removes a resource.
            case delete
        }

        // MARK: - Methods

        /// Creates a URL from a base string, an optional path, and query items.
        ///
        /// Existing query items in the base URL are replaced when `queryItems`
        /// is non-empty.
        /// - Parameters:
        ///   - urlString: The base URL string.
        ///   - path: An optional path to append to the base URL.
        ///   - queryItems: Query parameters to include in the URL.
        /// - Returns: A fully constructed URL.
        /// - Throws: `HTTPError.invalidURL` if the URL cannot be constructed.
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

        /// Encodes an `Encodable` value as JSON for use as an HTTP request body.
        /// - Parameter body: The value to encode.
        /// - Returns: The encoded JSON data.
        /// - Throws: `HTTPError.encoding` if JSON encoding fails.
        static func makeBody<Body: Encodable>(from body: Body) throws(HTTPError) -> Data {
            do {
                return try JSONEncoder().encode(body)
            } catch {
                throw .encoding(message: error.localizedDescription)
            }
        }

        /// Creates a JSON-oriented URL request.
        ///
        /// The request accepts JSON responses. When a body is provided, its
        /// content type is set to `application/json`.
        /// - Parameters:
        ///   - url: The destination URL.
        ///   - method: The HTTP method. Defaults to `GET`.
        ///   - body: Optional request body data.
        ///   - timeout: The request timeout interval in seconds. Defaults to 30 seconds.
        /// - Returns: A configured `URLRequest`.
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
        
        /// Executes a request using the supplied URL session.
        ///
        /// If no session is supplied, this method uses `URLSession.shared`.
        /// - Parameter request: The request to execute.
        /// - Parameter session: The session used to execute the request. Defaults to the shared session.
        /// - Returns: The response body and the corresponding URL response.
        /// - Throws: `HTTPError.downloading` if the request fails.
        static func data(
            for request: URLRequest,
            using session: URLSession = .shared
        ) async throws(HTTPError) -> (data: Data, response: URLResponse) {
            do {
                return try await session.data(for: request)
            } catch {
                throw .downloading(message: error.localizedDescription)
            }
        }
        
        /// Validates that a response is an HTTP success response.
        ///
        /// For non-success status codes, this method attempts to decode a server
        /// error payload containing a `reason` field.
        /// - Parameters:
        ///   - data: The response body.
        ///   - response: The response returned by the URL session.
        /// - Throws: `HTTPError.invalidResponse`, `HTTPError.invalidStatusCode`, or
        ///   `HTTPError.server` when the response is invalid or unsuccessful.
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

        /// Decodes response data into the requested `Decodable` type.
        /// - Parameters:
        ///   - data: The response body to decode.
        ///   - type: The type to decode.
        /// - Returns: A decoded value of the requested type.
        /// - Throws: `HTTPError.decoding` if decoding fails.
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
    /// A user-facing description of the error in Polish.
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
