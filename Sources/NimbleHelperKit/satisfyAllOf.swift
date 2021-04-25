import Nimble

// At the time I wrote this, satisfyAllOf with an array was still an internal predicate to Nimble.
public func satisfyAllOf<T>(_ predicates: [Predicate<T>]) -> Predicate<T> {
    return Predicate.define { actualExpression in
        var postfixMessages = [String]()
        var status: PredicateStatus = .matches
        for predicate in predicates {
            let result = try predicate.satisfies(actualExpression)
            if result.status == .fail {
                status = .fail
            } else if result.toBoolean(expectation: .toNotMatch), status != .fail {
                status = .doesNotMatch
            }
            postfixMessages.append("{\(result.message.expectedMessage)}")
        }

        var msg: ExpectationMessage
        if let actualValue = try actualExpression.evaluate() {
            msg = .expectedCustomValueTo(
                "match all of: " + postfixMessages.joined(separator: ", and "),
                actual: "\(actualValue)"
            )
        } else {
            msg = .expectedActualValueTo(
                "match all of: " + postfixMessages.joined(separator: ", and ")
            )
        }

        return PredicateResult(status: status, message: msg)
    }
}

