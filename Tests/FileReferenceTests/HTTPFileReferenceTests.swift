import Foundation
import Testing
@testable import HTTPFileReference

@Test func successfulRangeRequest() async throws {
    let data = "This is a test.".data(using: .utf8)!

    let configuration = MockURLProtocol.makeStubConfig { request in
        try MockURLProtocol.makeSuccessResponse(request: request, data: data)
    }

    let url = URL(string: "https://some.url.com/test")!
    let ref = try await HTTPFileReference(url: url, configuration: configuration)

    #expect(try await String(bytes: ref.getData(in: 0..<4), encoding: .utf8) == "This")
    #expect(try await String(bytes: ref.getData(in: 5..<11), encoding: .utf8) == "is a t")
}

@Test func serverLacksRangeSupport() async throws {
    let configuration = MockURLProtocol.makeStubConfig { request in
        (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data())
    }

    let url = URL(string: "https://some.url.com/test")!

    await #expect {
        try await HTTPFileReference(url: url, configuration: configuration)
    } throws: {
        switch $0 as? HTTPFileReference.Error {
        case .rangeRequestNotSupported(let response):
            response.url == url
        default:
            false
        }
    }
}

@Test func serverReturnsNonSuccessReturnCode() async throws {
    let configuration = MockURLProtocol.makeStubConfig { request in
        (HTTPURLResponse(url: request.url!, statusCode: 400, httpVersion: nil, headerFields: nil)!, Data())
    }

    let url = URL(string: "https://some.url.com/test")!

    await #expect {
        try await HTTPFileReference(url: url, configuration: configuration)
    } throws: {
        switch $0 as? HTTPFileReference.Error {
        case .httpError(let statusCode, let response):
            response.url == url && statusCode == 400
        default:
            false
        }
    }
}
