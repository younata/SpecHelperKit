import Nimble
import XCTest
import NimbleHelperKit
import SpecHelperKit

final class FakeCallTests: XCTestCase {
    // Non-Nimble matchers
    func testAssertCalls() {
        let subject = FakeCall<Int>()
        subject.assertCalled(times: 0)

        subject.record(1)
        subject.assertCalled(times: 1)
    }

    func testAssertCalledWith() {
        let subject = FakeCall<(Int, String)>()

        subject.record((1, "hello"))

        subject.assertCalledWith(arguments: [
            .expect(\.0) { XCTAssertEqual($0, 1) },
            .expect(\.1) { XCTAssertEqual($0, "hello") }
        ])

        subject.record((2, "goodbye"))

        subject.assertCalledWith(arguments: [
            .expect(\.0) { XCTAssertEqual($0, 2) },
            .expect(\.1) { XCTAssertEqual($0, "goodbye") }
        ])
    }

    // Nimble matchers
    func testBeCalled() {
        let subject = FakeCall<(Int, String)>()

        subject.record((1, ""))

        let records: [AssertionRecord] = gatherExpectations(silently: true) {
            expect(subject).toNot(beCalled(times: 1))
            expect(subject).to(beCalled(times: 1))

            expect(subject).toNot(beCalled(times: 0))
            expect(subject).to(beCalled(times: 0))
        }

        expect(records).to(haveResults([
            .failed,
            .succeeded,
            .succeeded,
            .failed
        ]))
    }
}
