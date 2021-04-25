class FakeCall<T>: CustomStringConvertible {
    private(set) var calls = [T]()

    func record(_ arguments: T) {
        calls.append(arguments)
    }

    func reset() {
        calls = []
    }

    func lastCall<U>(_ keyPath: KeyPath<T, U>) -> U? {
        guard let lastCall = calls.last else { return nil }
        return lastCall[keyPath: keyPath]
    }

    var description: String {
        return "AstroGraphTests.FakeCall<\(String(describing: T.self))>(values: \(calls))"
    }
}

extension FakeCall where T == Void {
    func record() {
        record(())
    }
}

public struct FakeCallAssertion<T> {
    private let closure: (T) -> Void
    init(_ closure: @escaping (T) -> Void) {
        self.closure = closure
    }

    public static func expect<U>(_ keyPath: KeyPath<T, U>, closure: @escaping (U) -> Void) -> FakeCallAssertion<T> {
        return FakeCallAssertion { (received: T) in
            let value = received[keyPath: keyPath]
            closure(value)
        }
    }

    func execute(_ value: T) {
        closure(value)
    }
}

class StubbedFakeCall<T, U>: FakeCall<T> {
    private let factory: (T) -> U
    private(set) var instances = [U]()

    var lastInstance: U? { instances.last }

    init(_ factory: @escaping () -> U) {
        self.factory = { _ in factory() }
        super.init()
    }

    init(_ factory: @escaping (T) -> U) {
        self.factory = factory
        super.init()
    }

    override func reset() {
        super.reset()
        instances = []
    }

    func stub(_ arguments: T) -> U {
        self.record(arguments)
        let instance = factory(arguments)
        instances.append(instance)
        return instance
    }

    override var description: String {
        return "AstroGraphTests.StubbedFakeCall<\(String(describing: T.self)), \(String(describing: U.self))>(values: \(calls))"
    }
}

extension StubbedFakeCall where T == Void {
    func stub() -> U {
        return stub(())
    }
}

#if canImport(Combine)
import Combine

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
class StubbedCombineFakeCall<T, U, E: Error>: FakeCall<T> {
    private(set) var instances = [PassthroughSubject<U, E>]()

    var lastInstance: PassthroughSubject<U, E>? { instances.last }

    override func reset() {
        super.reset()
        instances = []
    }

    func stub(_ arguments: T) -> AnyPublisher<U, E> {
        self.record(arguments)
        let instance = PassthroughSubject<U, E>()
        instances.append(instance)
        return instance.eraseToAnyPublisher()
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension StubbedCombineFakeCall where T == Void {
    func stub() -> AnyPublisher<U, E> {
        return stub(())
    }
}
#endif

#if canImport(XCTest)
import XCTest

extension FakeCall {
    public func assertCalled(times: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(self.calls.count, times, "Expected to be called \(times) times, got \(self.calls.count)", file: file, line: line)
    }

    public func assertCalledWith(arguments: [FakeCallAssertion<T>], file: StaticString = #file, line: UInt = #line) {
        guard let lastCall = self.calls.last else {
            XCTFail("No calls made to FakeCall \(self)", file: file, line: line)
            return
        }

        for argument in arguments {
            argument.execute(lastCall)
        }
    }
}
#endif
