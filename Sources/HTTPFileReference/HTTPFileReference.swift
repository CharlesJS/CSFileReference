//
//  HTTPFileReference.swift
//  CSFileReference
//
//  Created by Charles Srstka on 11/28/24.
//

import FileReference

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

public struct HTTPFileReference: FileReference {
    public enum Error: Swift.Error {
        case httpError(Int, URLResponse)
        case rangeRequestNotSupported(URLResponse)
        case unknown
    }

    public let url: URL
    public let size: UInt64

    private let session: URLSession
    private var isClosed: Bool = false

    public init(url: URL, configuration: URLSessionConfiguration = .default) async throws {
        let session = URLSession(configuration: configuration)

        self.session = session
        self.url = url
        self.size = try await Self.getSize(session: session, url: url)
    }

    private static func getSize(session: URLSession, url: URL) async throws -> UInt64 {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")

        let (_, response) = try await self.sendRequest(session: session, request: request)

        guard response.value(forHTTPHeaderField: "Accept-Ranges") == "bytes" else {
            throw Error.rangeRequestNotSupported(response)
        }

        return response.value(forHTTPHeaderField: "Content-Length").flatMap { UInt64($0) } ?? 0
    }

    private static func sendRequest(session: URLSession, request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else { throw Error.unknown }
        guard httpResponse.statusCode / 100 == 2 else { throw Error.httpError(httpResponse.statusCode, response) }

        return (data, httpResponse)
    }

    public func getBytes(_ buffer: UnsafeMutableRawBufferPointer, in range: Range<UInt64>) async throws -> Int {
        if self.isClosed { throw FileReferenceError.closed }

        let upperBound = min(range.upperBound, self.size) - 1
        guard upperBound >= range.lowerBound else { return 0 }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "GET"
        request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("bytes=\(range.lowerBound)-\(upperBound)", forHTTPHeaderField: "Range")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let (data, _) = try await Self.sendRequest(session: session, request: request)

        return data.copyBytes(to: buffer)
    }

    public mutating func close() { self.isClosed = true }
}
