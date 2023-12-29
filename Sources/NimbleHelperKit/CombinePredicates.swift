import Nimble
import SpecHelperKit
#if canImport(Combine)
import Combine

public func haveMostRecentlyReceived<T: Equatable, E: Error>(value: T) -> Matcher<PublisherHistory<T, E>> {
    return Matcher { (actualExpression: Expression<PublisherHistory<T, E>>) throws -> MatcherResult in

        guard let receivedValue = try actualExpression.evaluate() else {
            return MatcherResult(status: .fail, message: ExpectationMessage.expectedTo("have received value \(value) most recently").appendedBeNilHint())
        }
        let  message = ExpectationMessage.expectedCustomValueTo("have received value \(value) most recently", actual: "but received \(String(describing: receivedValue.values.last))")

        return MatcherResult(bool: receivedValue.values.last == value, message: message)
    }
}

public func haveReceived<T: Equatable, E: Error>(value: T) -> Matcher<PublisherHistory<T, E>> {
    return Matcher { (actualExpression: Expression<PublisherHistory<T, E>>) throws -> MatcherResult in

        guard let receivedValue = try actualExpression.evaluate() else {
            return MatcherResult(status: .fail, message: ExpectationMessage.expectedTo("have received value \(value) at some point").appendedBeNilHint())
        }
        let  message = ExpectationMessage.expectedCustomValueTo("have received value \(value) at some point", actual: "but received \(receivedValue.values)")

        return MatcherResult(bool: receivedValue.values.contains(value), message: message)
    }
}

public func haveReceived<T, E: Error>(_ expectations: [PublisherHistoryMatcher<T, E>]) -> Matcher<PublisherHistory<T, E>> {
    let matchers = expectations.map { (expectation: PublisherHistoryMatcher<T, E>) -> Matcher<PublisherHistory<T, E>> in expectation.matcher }
    return satisfyAllOf(matchers)
}

// This compiles *significantly* faster than doing the same thing as a closure. No idea why.
public struct PublisherHistoryMatcher<T, E: Error> {
    public let matcher: Matcher<PublisherHistory<T, E>>
    private init(_ matcher: Matcher<PublisherHistory<T, E>>) {
        self.matcher = matcher
    }

    public static func expect<U>(_ keyPath: KeyPath<T, U>, to matcher: Matcher<U>) -> PublisherHistoryMatcher<T, E> {
        return PublisherHistoryMatcher(Matcher { (received: Expression<PublisherHistory<T, E>>) -> MatcherResult in
            guard let publisherHistory = try received.evaluate(),
                  let value: U = publisherHistory.values.last?[keyPath: keyPath] else {
                return MatcherResult(status: .fail, message: ExpectationMessage.expectedTo("have received have received").appendedBeNilHint())
            }
            let expression: Expression<U> = Expression(expression: { value }, location: received.location)
            let matcherResult = try matcher.satisfies(expression)

            let message = matcherResult.message.wrappedExpectation(before: "Have been called with \(keyPath)", after: ", On the most recent call")
            return MatcherResult(status: matcherResult.status, message: message)
        })
    }

    public static func expect<U>(_ closure: @escaping (T) -> U?, to matcher: Matcher<U>) -> PublisherHistoryMatcher<T, E> {
        return PublisherHistoryMatcher(Matcher { (received: Expression<PublisherHistory<T, E>>) -> MatcherResult in
            guard let publisherHistory = try received.evaluate(), let value: T = publisherHistory.values.last else {
                return MatcherResult(status: .fail, message: ExpectationMessage.expectedTo("Be called").appendedBeNilHint())
            }
            let expression: Expression<U> = Expression(expression: { closure(value) }, location: received.location)
            let matcherResult = try matcher.satisfies(expression)

            let message = matcherResult.message.wrappedExpectation(before: "Have been called (closure)", after: "On the most recent call")
            return MatcherResult(status: matcherResult.status, message: message)
        })
    }

    public static func expect(to matcher: Matcher<T>) -> PublisherHistoryMatcher<T, E> {
        return PublisherHistoryMatcher(Matcher { (received: Expression<PublisherHistory<T, E>>) -> MatcherResult in
            guard let publisherHistory = try received.evaluate(), let value: T = publisherHistory.values.last else {
                return MatcherResult(status: .fail, message: ExpectationMessage.expectedTo("Be called").appendedBeNilHint())
            }
            let expression: Expression<T> = Expression(expression: { value }, location: received.location)
            let matcherResult = try matcher.satisfies(expression)

            let message = matcherResult.message.wrappedExpectation(before: "Have been called (value)", after: "On the most recent call")
            return MatcherResult(status: matcherResult.status, message: message)
        })
    }
}

public func haveReceived<T, E: Error>(error: E) -> Matcher<PublisherHistory<T, E>> {
    return Matcher { (actualExpression: Expression<PublisherHistory<T, E>>) throws -> MatcherResult in
        let message = ExpectationMessage.expectedTo("have completed with error \(error)")

        guard let receivedValue = try actualExpression.evaluate() else {
            return MatcherResult(status: .fail, message: message.appendedBeNilHint())
        }

        guard receivedValue.isComplete == true else {
            return MatcherResult(status: .fail, message: message.appended(message: "But did not finish yet"))
        }

        return try matchError(error).satisfies(Expression(expression: { receivedValue.error }, location: actualExpression.location))
    }
}

public func beSuccessfullyCompleted<T, E: Error>() -> Matcher<PublisherHistory<T, E>> {
    return Matcher { (actualExpression: Expression<PublisherHistory<T, E>>) throws -> MatcherResult in
        let message = ExpectationMessage.expectedTo("have successfully completed")

        guard let receivedValue = try actualExpression.evaluate() else {
            return MatcherResult(status: .fail, message: message.appendedBeNilHint())
        }

        guard receivedValue.isComplete else {
            return MatcherResult(bool: false, message: message.appended(message: "But was not completed at all"))
        }
        if let error = receivedValue.error {
            return MatcherResult(bool: false, message: message.appended(message: "But completed with error \(error)"))
        }

        return MatcherResult(bool: true, message: message)
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
