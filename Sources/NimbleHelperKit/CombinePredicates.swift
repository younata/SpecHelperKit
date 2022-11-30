import Nimble
import SpecHelperKit
#if canImport(Combine)
import Combine

public func haveMostRecentlyReceived<T: Equatable, E: Error>(value: T) -> Predicate<PublisherHistory<T, E>> {
    return Predicate { (actualExpression: Expression<PublisherHistory<T, E>>) throws -> PredicateResult in

        guard let receivedValue = try actualExpression.evaluate() else {
            return PredicateResult(status: .fail, message: ExpectationMessage.expectedTo("have received value \(value) most recently").appendedBeNilHint())
        }
        let  message = ExpectationMessage.expectedCustomValueTo("have received value \(value) most recently", actual: "but received \(String(describing: receivedValue.values.last))")

        return PredicateResult(bool: receivedValue.values.last == value, message: message)
    }
}

public func haveReceived<T: Equatable, E: Error>(value: T) -> Predicate<PublisherHistory<T, E>> {
    return Predicate { (actualExpression: Expression<PublisherHistory<T, E>>) throws -> PredicateResult in

        guard let receivedValue = try actualExpression.evaluate() else {
            return PredicateResult(status: .fail, message: ExpectationMessage.expectedTo("have received value \(value) at some point").appendedBeNilHint())
        }
        let  message = ExpectationMessage.expectedCustomValueTo("have received value \(value) at some point", actual: "but received \(receivedValue.values)")

        return PredicateResult(bool: receivedValue.values.contains(value), message: message)
    }
}

public func haveReceived<T, E: Error>(_ expectations: [PublisherHistoryPredicate<T, E>]) -> Predicate<PublisherHistory<T, E>> {
    let predicates = expectations.map { (expectation: PublisherHistoryPredicate<T, E>) -> Predicate<PublisherHistory<T, E>> in expectation.predicate }
    return satisfyAllOf(predicates)
}

// This compiles *significantly* faster than doing the same thing as a closure. No idea why.
public struct PublisherHistoryPredicate<T, E: Error> {
    public let predicate: Predicate<PublisherHistory<T, E>>
    private init(_ predicate: Predicate<PublisherHistory<T, E>>) {
        self.predicate = predicate
    }

    public static func expect<U>(_ keyPath: KeyPath<T, U>, to matcher: Predicate<U>) -> PublisherHistoryPredicate<T, E> {
        return PublisherHistoryPredicate(Predicate { (received: Expression<PublisherHistory<T, E>>) -> PredicateResult in
            guard let publisherHistory = try received.evaluate(),
                  let value: U = publisherHistory.values.last?[keyPath: keyPath] else {
                return PredicateResult(status: .fail, message: ExpectationMessage.expectedTo("have received have received").appendedBeNilHint())
            }
            let expression: Expression<U> = Expression(expression: { value }, location: received.location)
            let matcherResult = try matcher.satisfies(expression)

            let message = matcherResult.message.wrappedExpectation(before: "Have been called with \(keyPath)", after: ", On the most recent call")
            return PredicateResult(status: matcherResult.status, message: message)
        })
    }

    public static func expect<U>(_ closure: @escaping (T) -> U?, to matcher: Predicate<U>) -> PublisherHistoryPredicate<T, E> {
        return PublisherHistoryPredicate(Predicate { (received: Expression<PublisherHistory<T, E>>) -> PredicateResult in
            guard let publisherHistory = try received.evaluate(), let value: T = publisherHistory.values.last else {
                return PredicateResult(status: .fail, message: ExpectationMessage.expectedTo("Be called").appendedBeNilHint())
            }
            let expression: Expression<U> = Expression(expression: { closure(value) }, location: received.location)
            let matcherResult = try matcher.satisfies(expression)

            let message = matcherResult.message.wrappedExpectation(before: "Have been called (closure)", after: "On the most recent call")
            return PredicateResult(status: matcherResult.status, message: message)
        })
    }

    public static func expect(to matcher: Predicate<T>) -> PublisherHistoryPredicate<T, E> {
        return PublisherHistoryPredicate(Predicate { (received: Expression<PublisherHistory<T, E>>) -> PredicateResult in
            guard let publisherHistory = try received.evaluate(), let value: T = publisherHistory.values.last else {
                return PredicateResult(status: .fail, message: ExpectationMessage.expectedTo("Be called").appendedBeNilHint())
            }
            let expression: Expression<T> = Expression(expression: { value }, location: received.location)
            let matcherResult = try matcher.satisfies(expression)

            let message = matcherResult.message.wrappedExpectation(before: "Have been called (value)", after: "On the most recent call")
            return PredicateResult(status: matcherResult.status, message: message)
        })
    }
}

public func haveReceived<T, E: Error>(error: E) -> Predicate<PublisherHistory<T, E>> {
    return Predicate { (actualExpression: Expression<PublisherHistory<T, E>>) throws -> PredicateResult in
        let message = ExpectationMessage.expectedTo("have completed with error \(error)")

        guard let receivedValue = try actualExpression.evaluate() else {
            return PredicateResult(status: .fail, message: message.appendedBeNilHint())
        }

        guard receivedValue.isComplete == true else {
            return PredicateResult(status: .fail, message: message.appended(message: "But did not finish yet"))
        }

        return try matchError(error).satisfies(Expression(expression: { receivedValue.error }, location: actualExpression.location))
    }
}

public func beSuccessfullyCompleted<T, E: Error>() -> Predicate<PublisherHistory<T, E>> {
    return Predicate { (actualExpression: Expression<PublisherHistory<T, E>>) throws -> PredicateResult in
        let message = ExpectationMessage.expectedTo("have successfully completed")

        guard let receivedValue = try actualExpression.evaluate() else {
            return PredicateResult(status: .fail, message: message.appendedBeNilHint())
        }

        guard receivedValue.isComplete else {
            return PredicateResult(bool: false, message: message.appended(message: "But was not completed at all"))
        }
        if let error = receivedValue.error {
            return PredicateResult(bool: false, message: message.appended(message: "But completed with error \(error)"))
        }

        return PredicateResult(bool: true, message: message)
    }
}

extension Future {
    public typealias PendingTuple = (future: Future<Output, Failure>, promise: Future<Output, Failure>.Promise)
    public static func pending() -> PendingTuple {
        var promise: Future<Output, Failure>.Promise! = nil
        let future = Future<Output, Failure> { prom in
            promise = prom
        }
        return (future, promise)
    }
}

#endif
