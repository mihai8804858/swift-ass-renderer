/// Log level.
public enum LogLevel: Int, Sendable {
    /// Only fatal errors that result in subtitles not being rendered.
    case fatal = 0

    /// Fatal errors and additional useful information.
    case `default` = 5

    /// All messages
    case verbose = 7

    public init?(rawValue: Int) {
        switch rawValue {
        case ...0: self = .fatal
        case 1...5: self = .default
        case 6...7: self = .verbose
        default: return nil
        }
    }
}

/// Log output message and level.
public struct LogMessage: Sendable {
    /// Output message.
    public let message: String

    /// Output message level.
    public let level: LogLevel
}

/// Where the messages should be send to.
public enum LogOutput: Sendable {
    /// Print messages to console based on the provided log level.
    case console(LogLevel)

    /// Send all messages to custom handler.
    case custom(@Sendable (LogMessage) -> Void)
}

protocol LoggerType: Sendable {
    func configureLibrary(_ wrapper: LibraryWrapperType.Type, library: OpaquePointer)
    func log(message: LogMessage)
}

struct Logger: LoggerType {
    let prefix: String
    let output: LogOutput
    /// The library's messages go here. Held by the logger, and so by its renderer, which outlives
    /// the library it frees in `deinit`.
    private let librarySink: LibraryLogSink

    init(prefix: String = "swift-ass", output: LogOutput? = nil) {
        let output = output ?? .console({
            #if DEBUG
            .default
            #else
            .fatal
            #endif
        }())
        self.prefix = prefix
        self.output = output
        self.librarySink = LibraryLogSink { messageLevel, message in
            guard let level = LogLevel(rawValue: messageLevel) else { return }
            Self.log(message: LogMessage(message: message, level: level), prefix: prefix, output: output)
        }
    }

    func configureLibrary(_ wrapper: LibraryWrapperType.Type, library: OpaquePointer) {
        wrapper.setLogCallback(library, sink: librarySink)
    }

    func log(message: LogMessage) {
        Self.log(message: message, prefix: prefix, output: output)
    }

    private static func log(message: LogMessage, prefix: String, output: LogOutput) {
        let prefixedMessage = "[\(prefix)] \(message.message)"
        switch output {
        case .console(let level):
            guard level.rawValue >= message.level.rawValue else { return }
            print(prefixedMessage)
        case .custom(let log):
            log(LogMessage(message: prefixedMessage, level: message.level))
        }
    }
}
