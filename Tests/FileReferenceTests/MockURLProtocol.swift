//
//  MockURLProtocol.swift
//  CSFileReference
//
//  Created by Charles Srstka on 11/30/24.
//

import SyncPolyfill

#if canImport(FoundationEssentials) && canImport(FoundationNetworking)
import FoundationEssentials
import FoundationNetworking
#else
import Foundation
#endif

final class MockURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

#if canImport(Darwin)
    private static let mockUUIDHeader = "com-charlessoft-csfilereference-mock-uuid"
#else
    // Unfortunately, a bug prevents URLSessionConfiguration.httpAdditionalHeaders from working properly with
    // custom URL protocols on swift-corelibs-foundation, so we need this hack instead
    private final class StubCache: URLCache, @unchecked Sendable {
        let uuid: UUID

        init(uuid: UUID) {
            self.uuid = uuid
            super.init(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
        }

        override func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
            CachedURLResponse(response: URLResponse(url: FileManager.default.temporaryDirectory, mimeType: nil, expectedContentLength: 0, textEncodingName: nil), data: self.uuid.uuidString.data(using: .utf8)!)
        }
    }

    private let uuid: String?
    required init(request: URLRequest, cachedResponse: CachedURLResponse?, client: (any URLProtocolClient)?) {
        self.uuid = cachedResponse.flatMap { String(data: $0.data, encoding: .utf8) }
        super.init(request: request, cachedResponse: cachedResponse, client: client)
    }
#endif

    private struct State {
        var handlers: [String : Handler] = [:]
    }

    private static let stateMutex = Mutex(State())

    static func setHandler(_ handler: @escaping Handler, for uuid: UUID) {
        struct Box: @unchecked Sendable { let handler: Handler }
        let box = Box(handler: handler)

        self.stateMutex.withLock { $0.handlers[uuid.uuidString] = box.handler }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let client = self.client else { return }

        Self.stateMutex.withLock { state in
            let request = self.request

#if canImport(Darwin)
            let uuid = request.value(forHTTPHeaderField: Self.mockUUIDHeader)
#else
            let uuid = self.uuid
#endif

            guard let uuid, let handler = state.handlers[uuid] else {
                assertionFailure("Received unhandled URLRequest")
                return
            }

            do {
                let (response, data) = try handler(request)
                client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client.urlProtocol(self, didLoad: data)
                client.urlProtocolDidFinishLoading(self)
            } catch {
                client.urlProtocol(self, didFailWithError: error)
            }
        }
    }

    override func stopLoading() {}

    static func makeStubConfig(_ handler: @escaping Handler) -> URLSessionConfiguration {
        let uuid = UUID()

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Self.self]
#if canImport(Darwin)
        configuration.httpAdditionalHeaders = [Self.mockUUIDHeader: uuid.uuidString]
#else
        configuration.urlCache = StubCache(uuid: uuid)
#endif

        MockURLProtocol.setHandler(handler, for: uuid)

        return configuration
    }

    static func rangeFromRequest(_ request: URLRequest) -> ClosedRange<Int>? {
        guard let rangeHeader = request.value(forHTTPHeaderField: "Range"),
              let prefixRange = rangeHeader.range(of: "bytes=", options: .anchored),
              let match = try? /(\d+)-(\d+)/.firstMatch(in: rangeHeader[prefixRange.upperBound...]),
              let lowerBound = Int(match.output.1),
              let upperBound = Int(match.output.2) else {
            return nil
        }

        return lowerBound...upperBound
    }

    static func makeSuccessResponse(request: URLRequest, data: Data) throws -> (HTTPURLResponse, Data) {
        var headerFields = ["Accept-Ranges" : "bytes"]

        let subdata: Data
        if let range = self.rangeFromRequest(request) {
            headerFields["Content-Range"] = "bytes \(range.lowerBound)-\(range.upperBound)/\(data.count)"
            subdata = data[range]
        } else {
            subdata = data
        }

        headerFields["Content-Length"] = String(subdata.count)

        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: headerFields) else {
            throw POSIXError(.EINVAL)
        }

        return (response, subdata)
    }

    static func makeErrorResponse(request: URLRequest, statusCode: Int) throws -> (HTTPURLResponse, Data) {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil) else {
            throw POSIXError(.EINVAL)
        }

        return (response, "HTTP Error \(statusCode)".data(using: .utf8)!)
    }
}
