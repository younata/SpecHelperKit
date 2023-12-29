import Nimble

// This is really useful for writing custom nimble matchers and asserting they work correctly.
public enum AssertionResult {
    case succeeded
    case failed

    var boolValue: Bool {
        switch self {
        case .succeeded: return true
        case .failed: return false
        }
    }
}

public func haveResults(_ results: [AssertionResult]) -> Matcher<[AssertionRecord]> {
    return Matcher { (received: Expression<[AssertionRecord]>) in
        let message = ExpectationMessage.expectedActualValueTo("have results \(results)")

        guard let records = try received.evaluate() else {
            return MatcherResult(status: .fail, message: message.appendedBeNilHint())
        }

        guard results.count == records.count else {
            return MatcherResult(status: .fail, message: message.appended(details: "Number of results do not match"))
        }
        let allPassed = records.enumerated().allSatisfy { (idx, record) in
            return record.success == results[idx].boolValue
        }
        return MatcherResult(bool: allPassed, message: message)
    }
}
