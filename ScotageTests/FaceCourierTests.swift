import XCTest
@testable import Scotage

private struct ProbeDTO: Decodable {
    var mass: LooseFigure
}

private actor ScriptedHop: FaceChannel {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func haul(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class FaceCourierTests: XCTestCase {
    private let url = URL(string: "https://scotage-face.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let channel = ScriptedHop(results: [
            .success((Data("{\"mass\":1}".utf8), http(200))),
        ])
        let courier = FaceCourier(channel: channel)
        _ = try await courier.decodeHop(ProbeDTO.self, from: url)
        let request = await channel.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), FaceCourier.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(FaceCourier.userAgent, "Scotage/1.0 (iOS; +https://scotage-face.pro)")
        XCTAssertEqual(FaceCourier.contactURL.absoluteString, "https://scotage-face.pro/contact-us")
        XCTAssertEqual(FaceCourier.searchDebounceNanoseconds, 300_000_000)
    }

    func test_retriesTransientTransportOnce() async throws {
        let channel = ScriptedHop(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"mass\":\"4.5\"}".utf8), http(200))),
        ])
        let courier = FaceCourier(channel: channel)
        let dto = try await courier.decodeHop(ProbeDTO.self, from: url)
        XCTAssertEqual(dto.mass.figure, 4.5)
        let count = await channel.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async {
        let channel = ScriptedHop(results: [
            .success((Data(), http(404))),
            .success((Data("{\"mass\":1}".utf8), http(200))),
        ])
        let courier = FaceCourier(channel: channel)
        do {
            _ = try await courier.decodeHop(ProbeDTO.self, from: url)
            XCTFail("expected vacant")
        } catch {
            XCTAssertEqual(error as? FaceHopFault, .vacant)
        }
        let count = await channel.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsUnreadable() async {
        let channel = ScriptedHop(results: [
            .success((Data("{".utf8), http(200))),
        ])
        let courier = FaceCourier(channel: channel)
        do {
            _ = try await courier.decodeHop(ProbeDTO.self, from: url)
            XCTFail("expected unreadable")
        } catch {
            XCTAssertEqual(error as? FaceHopFault, .unreadable)
        }
    }

    func test_statusZeroMapsToVacant() async {
        let channel = ScriptedHop(results: [
            .success((Data("{\"status\":0}".utf8), http(200))),
        ])
        let courier = FaceCourier(channel: channel)
        do {
            _ = try await courier.readStatus(from: url)
            XCTFail("expected vacant")
        } catch {
            XCTAssertEqual(error as? FaceHopFault, .vacant)
        }
    }

    func test_looseFigureAcceptsNumberAndString() throws {
        let number = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"mass\":12.5}".utf8))
        let string = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"mass\":\"12.5\"}".utf8))
        let missing = try JSONDecoder().decode(ProbeDTO.self, from: Data("{\"mass\":null}".utf8))
        XCTAssertEqual(number.mass.figure, 12.5)
        XCTAssertEqual(string.mass.figure, 12.5)
        XCTAssertNil(missing.mass.figure)
    }

    private func http(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
    }
}
