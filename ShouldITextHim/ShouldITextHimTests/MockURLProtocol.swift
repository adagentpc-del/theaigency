import Foundation

/// A `URLProtocol` stub that intercepts every request made through a
/// session configured with it, so `RemoteAIJudgmentProvider` can be tested
/// against scripted HTTP responses (or simulated network failures)
/// without touching the real network or a real API key.
final class MockURLProtocol: URLProtocol {
    /// Set by each test before making a request. Return `(HTTPURLResponse, Data)`
    /// for a normal response, or throw to simulate a network failure.
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    /// Incremented every time a request is actually sent through this
    /// protocol — lets tests assert a network call was (or wasn't) made,
    /// e.g. to prove safety/mechanical short-circuits never hit the network.
    private(set) static var requestCount = 0

    static func reset() {
        requestHandler = nil
        requestCount = 0
    }

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        MockURLProtocol.requestCount += 1
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
