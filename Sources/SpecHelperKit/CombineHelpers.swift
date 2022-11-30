#if canImport(Combine)
import Combine

public final class PublisherHistory<T, E: Error> {
    public private(set) var values: [T] = []
    private var completion: Subscribers.Completion<E>? = nil

    public var isComplete: Bool { completion != nil }
    public var error: E? {
        if case .failure(let error) = completion {
            return error
        }
        return nil
    }

    private var cancellables = Set<AnyCancellable>()

    public init(publisher: AnyPublisher<T, E>) {
        publisher.sink(
            receiveCompletion: { [weak self] in self?.completion = $0 },
            receiveValue: { [weak self] in self?.values.append($0) }
        ).store(in: &cancellables)
    }
}

extension Publisher {
    public func startRecording() -> PublisherHistory<Output, Failure> {
        return PublisherHistory(publisher: self.eraseToAnyPublisher())
    }
}
#endif
