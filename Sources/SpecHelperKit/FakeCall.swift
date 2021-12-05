public class FakeCall<T>: CustomStringConvertible {
    public private(set) var calls = [T]()

    public init() {}

    public func record(_ arguments: T) {
        calls.append(arguments)
    }

    public func reset() {
        calls = []
    }

    public func lastCall<U>(_ keyPath: KeyPath<T, U>) -> U? {
        guard let lastCall = calls.last else { return nil }
        return lastCall[keyPath: keyPath]
    }

    public var description: String {
        return "AstroGraphTests.FakeCall<\(String(describing: T.self))>(values: \(calls))"
    }
}

public extension FakeCall where T == Void {
    func record() {
        record(())
    }
}

public struct FakeCallAssertion<T> {
    private let closure: (T) -> Void
    public init(_ closure: @escaping (T) -> Void) {
        self.closure = closure
    }

    public static func expect<U>(_ keyPath: KeyPath<T, U>, closure: @escaping (U) -> Void) -> FakeCallAssertion<T> {
        return FakeCallAssertion { (received: T) in
            let value = received[keyPath: keyPath]
            closure(value)
        }
    }

    public func execute(_ value: T) {
        closure(value)
    }
}

public class StubbedFakeCall<T, U>: FakeCall<T> {
    private let factory: (T) -> U
    public private(set) var instances = [U]()

    public var lastInstance: U? { instances.last }

    public init(_ factory: @escaping () -> U) {
        self.factory = { _ in factory() }
        super.init()
    }

    public init(_ factory: @escaping (T) -> U) {
        self.factory = factory
        super.init()
    }

    public override func reset() {
        super.reset()
        instances = []
    }

    public func stub(_ arguments: T) -> U {
        self.record(arguments)
        let instance = factory(arguments)
        instances.append(instance)
        return instance
    }

    public override var description: String {
        return "AstroGraphTests.StubbedFakeCall<\(String(describing: T.self)), \(String(describing: U.self))>(values: \(calls))"
    }
}

public extension StubbedFakeCall where T == Void {
    func stub() -> U {
        return stub(())
    }
}

#if canImport(Combine)
import Combine

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public class StubbedCombineFakeCall<T, U, E: Error>: FakeCall<T> {
    public private(set) var instances = [PassthroughSubject<U, E>]()

    public var lastInstance: PassthroughSubject<U, E>? { instances.last }

    public override func reset() {
        super.reset()
        instances = []
    }

    public func stub(_ arguments: T) -> AnyPublisher<U, E> {
        self.record(arguments)
        let instance = PassthroughSubject<U, E>()
        instances.append(instance)
        return instance.eraseToAnyPublisher()
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension StubbedCombineFakeCall where T == Void {
    func stub() -> AnyPublisher<U, E> {
        return stub(())
    }
}
#endif

#if canImport(XCTest)
import XCTest

public extension FakeCall {
    func assertCalled(times: Int, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(self.calls.count, times, "Expected to be called \(times) times, got \(self.calls.count)", file: file, line: line)
    }

    func assertCalledWith(arguments: [FakeCallAssertion<T>], file: StaticString = #file, line: UInt = #line) {
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
