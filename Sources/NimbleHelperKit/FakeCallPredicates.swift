import Nimble
import SpecHelperKit

func beCalled<T>(times: Int) -> Predicate<FakeCall<T>> {
    return Predicate { (received: Expression<FakeCall<T>>) in
        let message = ExpectationMessage.expectedTo("be called \(times) time(s)")

        guard let fakeCall: FakeCall<T> = try received.evaluate() else {
            return PredicateResult(status: .fail, message: message.appendedBeNilHint())
        }
        return PredicateResult(bool: fakeCall.calls.count == times, message: message.appended(message: "but was published \(fakeCall.calls.count) time(s)"))
    }
}

func beCalled<T>(_ matchers: [Predicate<T>]) -> Predicate<FakeCall<T>> {
    return Predicate { (received: Expression<FakeCall<T>>) in
        let message = ExpectationMessage.expectedTo("have calls")

        guard let fakeCall: FakeCall<T> = try received.evaluate() else {
            return PredicateResult(status: .fail, message: message.appendedBeNilHint())
        }

        guard fakeCall.calls.count == matchers.count else {
            return PredicateResult(status: .fail, message: message.appended(message: "But number of calls did not match"))
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

        return PredicateResult(bool: matches, message: msg)
    }
}

func beCalled<T>(_ expectations: [FakeCallPredicate<T>]) -> Predicate<FakeCall<T>> {
    let predicates = expectations.map { (expectation: FakeCallPredicate<T>) -> Predicate<FakeCall<T>> in expectation.predicate }
    return satisfyAllOf(predicates)
}

// This compiles *significantly* faster than doing the same thing as a closure. No idea why.
struct FakeCallPredicate<T> {
    let predicate: Predicate<FakeCall<T>>
    private init(_ predicate: Predicate<FakeCall<T>>) {
        self.predicate = predicate
    }

    static func expect<U>(_ keyPath: KeyPath<T, U>, to matcher: Predicate<U>) -> FakeCallPredicate<T> {
        return FakeCallPredicate(Predicate { (received: Expression<FakeCall<T>>) -> PredicateResult in
            guard let fakeCall = try received.evaluate(), let value: U = fakeCall.calls.last?[keyPath: keyPath] else {
                return PredicateResult(status: .fail, message: ExpectationMessage.expectedTo("Be called").appendedBeNilHint())
            }
            let expression: Expression<U> = Expression(expression: { value }, location: received.location)
            let matcherResult = try matcher.satisfies(expression)

            let message = matcherResult.message.wrappedExpectation(before: "Have been called (\(keyPath))", after: "On the most recent call, but got \(value)")
            return PredicateResult(status: matcherResult.status, message: message)
        })
    }

    static func expect<U>(_ closure: @escaping (T) -> U?, to matcher: Predicate<U>) -> FakeCallPredicate<T> {
        return FakeCallPredicate(Predicate { (received: Expression<FakeCall<T>>) -> PredicateResult in
            guard let fakeCall = try received.evaluate(), let lastCall: T = fakeCall.calls.last, let value = closure(lastCall) else {
                return PredicateResult(status: .fail, message: ExpectationMessage.expectedTo("Be called").appendedBeNilHint())
            }
            let expression: Expression<U> = Expression(expression: { value }, location: received.location)
            let matcherResult = try matcher.satisfies(expression)

            let message = matcherResult.message.wrappedExpectation(before: "Have been called (closure)", after: "On the most recent call, but got \(String(describing: value))")
            return PredicateResult(status: matcherResult.status, message: message)
        })
    }
}

enum AssertionResult {
    case succeeded
    case failed

    var boolValue: Bool {
        switch self {
        case .succeeded: return true
        case .failed: return false
        }
    }
}

func haveResults(_ results: [AssertionResult]) -> Predicate<[AssertionRecord]> {
    return Predicate { (received: Expression<[AssertionRecord]>) in
        let message = ExpectationMessage.expectedActualValueTo("have results \(results)")

        guard let records = try received.evaluate() else {
            return PredicateResult(status: .fail, message: message.appendedBeNilHint())
        }

        guard results.count == records.count else {
            return PredicateResult(status: .fail, message: message.appended(details: "Number of results do not match"))
        }
        let allPassed = records.enumerated().allSatisfy { (idx, record) in
            return record.success == results[idx].boolValue
        }
        return PredicateResult(bool: allPassed, message: message)
    }
}
