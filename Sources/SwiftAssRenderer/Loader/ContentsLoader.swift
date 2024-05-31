import Foundation
import Combine
import CombineExt
import CombineSchedulers

protocol ContentsLoaderType {
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
        AnyPublisher<String?, Error>.create { subscriber in
            do {
                subscriber.send(try String(contentsOf: url))
                subscriber.send(completion: .finished)
            } catch {
                subscriber.send(completion: .failure(error))
            }

            return AnyCancellable {}
        }
    }

    private func loadRemoveContents(from url: URL) -> AnyPublisher<String?, Error> {
        URLSession
            .shared
            .dataTaskPublisher(for: url)
            .map { String(decoding: $0.data, as: UTF8.self) }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
