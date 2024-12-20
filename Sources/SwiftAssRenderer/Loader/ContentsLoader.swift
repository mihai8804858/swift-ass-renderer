import Foundation
import Combine
import CombineSchedulers

protocol ContentsLoaderType: Sendable {
    func loadContents(from url: URL) -> AnyPublisher<String?, Error>
}

struct ContentsLoader: ContentsLoaderType {
    private let subscribeScheduler: AnySchedulerOf<DispatchQueue>
    private let receiveScheduler: AnySchedulerOf<DispatchQueue>

    init(
        subscribeScheduler: AnySchedulerOf<DispatchQueue> = .global(),
        receiveScheduler: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.subscribeScheduler = subscribeScheduler
        self.receiveScheduler = receiveScheduler
    }

    func loadContents(from url: URL) -> AnyPublisher<String?, Error> {
        let pub = url.isFileURL ?
            loadLocalContents(from: url) :
            loadRemoveContents(from: url)

        return pub
            .subscribe(on: subscribeScheduler)
            .receive(on: receiveScheduler)
            .eraseToAnyPublisher()
    }

    private func loadLocalContents(from url: URL) -> AnyPublisher<String?, Error> {
        Deferred {
            Future { promise in
                do {
                    promise(.success(try String(contentsOf: url)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func loadRemoveContents(from url: URL) -> AnyPublisher<String?, Error> {
        URLSession
            .shared
            .dataTaskPublisher(for: url)
            .map { String(data: $0.data, encoding: .utf8) }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
