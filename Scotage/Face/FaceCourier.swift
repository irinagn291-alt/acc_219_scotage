import Foundation

/// Role: Face. Typed hop failures. This product has no remote catalog.
enum FaceHopFault: Error, Equatable, Sendable {
    case vacant
    case unreadable
    case lostHop
    case cutShort
    case notHTTP
}

/// Role: Face. Injected hop so tests never leave the process.
protocol FaceChannel: Sendable {
    func haul(_ request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Face. URLSession hop with a 15 s timeout and the app User-Agent.
struct SessionHop: FaceChannel {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": FaceCourier.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func haul(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Face. Number or numeric string; missing stays nil. Never a domain field.
struct LooseFigure: Sendable, Equatable, Decodable {
    var figure: Double?

    init(figure: Double?) {
        self.figure = figure
    }

    init(from decoder: Decoder) throws {
        let box = try decoder.singleValueContainer()
        if box.decodeNil() {
            figure = nil
            return
        }
        if let number = try? box.decode(Double.self) {
            figure = number
            return
        }
        if let whole = try? box.decode(Int.self) {
            figure = Double(whole)
            return
        }
        if let text = try? box.decode(String.self) {
            figure = Double(text)
            return
        }
        figure = nil
    }
}

struct StatusHop: Decodable, Sendable {
    var status: Int
}

/// Role: Face. Owns the session. Contact URL is opened by Settings, not decoded here.
actor FaceCourier {
    static let userAgent = "Scotage/1.0 (iOS; +https://scotage-face.pro)"
    /// Literal contact URL. Failure here is a programmer error.
    static let contactURL = URL(string: "https://scotage-face.pro/contact-us")!
    static let searchDebounceNanoseconds: UInt64 = 300_000_000

    private let channel: any FaceChannel

    init(channel: any FaceChannel) {
        self.channel = channel
    }

    init() {
        self.channel = SessionHop()
    }

    func decodeHop<DTO: Decodable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await haul(ticket(for: url))
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            return try decoder.decode(DTO.self, from: body)
        } catch is CancellationError {
            throw FaceHopFault.cutShort
        } catch {
            throw FaceHopFault.unreadable
        }
    }

    func readStatus(from url: URL) async throws -> Int {
        let hop = try await decodeHop(StatusHop.self, from: url)
        if hop.status == 0 {
            throw FaceHopFault.vacant
        }
        return hop.status
    }

    private func ticket(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func haul(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let fault as FaceHopFault {
            throw fault
        } catch is CancellationError {
            throw FaceHopFault.cutShort
        } catch {
            if Self.cutShort(error) {
                throw FaceHopFault.cutShort
            }
            guard Self.transient(error) else { throw FaceHopFault.lostHop }
            do {
                return try await send(request)
            } catch let fault as FaceHopFault {
                throw fault
            } catch is CancellationError {
                throw FaceHopFault.cutShort
            } catch {
                if Self.cutShort(error) { throw FaceHopFault.cutShort }
                throw FaceHopFault.lostHop
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (body, reply) = try await channel.haul(request)
        guard let http = reply as? HTTPURLResponse else {
            throw FaceHopFault.notHTTP
        }
        if http.statusCode == 404 {
            throw FaceHopFault.vacant
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw FaceHopFault.lostHop
        }
        return body
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cutShort(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}
