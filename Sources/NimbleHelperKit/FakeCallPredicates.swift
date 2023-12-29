import Nimble
import SpecHelperKit

public func beCalled<T>(times: Int) -> Matcher<FakeCall<T>> {
    return Matcher { (received: Expression<FakeCall<T>>) in
        let message = ExpectationMessage.expectedTo("be called \(times) time(s)")

        guard let fakeCall: FakeCall<T> = try received.evaluate() else {
            return MatcherResult(status: .fail, message: message.appendedBeNilHint())
        }
        return MatcherResult(bool: fakeCall.calls.count == times, message: message.appended(message: "but was published \(fakeCall.calls.count) time(s)"))
    }
}

public func beCalled<T>(_ matchers: [Matcher<T>]) -> Matcher<FakeCall<T>> {
    return Matcher { (received: Expression<FakeCall<T>>) in
        let message = ExpectationMessage.expectedTo("have calls")

        guard let fakeCall: FakeCall<T> = try received.evaluate() else {
            return MatcherResult(status: .fail, message: message.appendedBeNilHint())
        }

        guard fakeCall.calls.count == matchers.count else {
            return MatcherResult(status: .fail, message: message.appended(message: "But number of calls did not match"))
        }

        var postfixMessages = [String]()
        var matches = true
        for (call, matcher) in zip(fakeCall.calls, matchers) {
            let expression = Expression<T>(expression: { call }, location: received.location)
            let result = try matcher.satisfies(expression)
            if result.toBoolean(expectation: .toNotMatch) {
                matches = false
            }
            postfixMessages.append("{\(result.message.expectedMessage)}")
        }

        var msg: ExpectationMessage
        if let actualValue = try received.evaluate() {
            msg = .expectedCustomValueTo(
                "have calls: " + postfixMessages.joined(separator: ", and "),
                actual: "\(actualValue)"
            )
        } else {
            msg = .expectedActualValueTo(
                "have calls: " + postfixMessages.joined(separator: ", and ")
            )
        }

        return MatcherResult(bool: matches, message: msg)
    }
}

public func beCalled<T>(_ expectations: [FakeCallMatcher<T>]) -> Matcher<FakeCall<T>> {
    let matchers = expectations.map { (expectation: FakeCallMatcher<T>) -> Matcher<FakeCall<T>> in expectation.matcher }
    return satisfyAllOf(matchers)
}

// This compiles *significantly* faster than doing the same thing as a closure. No idea why.
public struct FakeCallMatcher<T> {
    let matcher: Matcher<FakeCall<T>>
    private init(_ matcher: Matcher<FakeCall<T>>) {
        self.matcher = matcher
    }

    public static func expect<U>(_ keyPath: KeyPath<T, U>, to matcher: Matcher<U>) -> FakeCallMatcher<T> {
        return FakeCallMatcher(Matcher { (received: Expression<FakeCall<T>>) -> MatcherResult in
            guard let fakeCall = try received.evaluate(), let value: U = fakeCall.calls.last?[keyPath: keyPath] else {
                return MatcherResult(status: .fail, message: ExpectationMessage.expectedTo("Be called").appendedBeNilHint())
            }
            let expression: Expression<U> = Expression(expression: { value }, location: received.location)
            let matcherResult = try matcher.satisfies(expression)

            let message = matcherResult.message.wrappedExpectation(before: "Have been called (\(keyPath))", after: "On the most recent call, but got \(value)")
            return MatcherResult(status: matcherResult.status, message: message)
        })
    }

    public static func expect<U>(_ closure: @escaping (T) -> U?, to matcher: Matcher<U>) -> FakeCallMatcher<T> {
        return FakeCallMatcher(Matcher { (received: Expression<FakeCall<T>>) -> MatcherResult in
            guard let fakeCall = try received.evaluate(), let lastCall: T = fakeCall.calls.last, let value = closure(lastCall) else {
                return MatcherResult(status: .fail, message: ExpectationMessage.expectedTo("Be called").appendedBeNilHint())
            }
            let expression: Expression<U> = Expression(expression: { value }, location: received.location)
            let matcherResult = try matcher.satisfies(expression)

            let message = matcherResult.message.wrappedExpectation(before: "Have been called (closure)", after: "On the most recent call, but got \(String(describing: value))")
            return MatcherResult(status: matcherResult.status, message: message)
        })
    }
}
