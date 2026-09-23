import XCTest
@testable import Scotage

final class FaceReviewTests: XCTestCase {
    func test_readsTodayLogGoalsOnceAfterOnboarding() {
        var consumed = false
        XCTAssertEqual(
            FaceReview.consume(
                arguments: ["-ReviewScreen", "today"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .today
        )
        XCTAssertTrue(consumed)
        XCTAssertNil(
            FaceReview.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )

        consumed = false
        XCTAssertEqual(
            FaceReview.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .log
        )

        consumed = false
        XCTAssertEqual(
            FaceReview.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .goals
        )
    }

    func test_skipsWhenOnboardingIncomplete() {
        var consumed = false
        XCTAssertNil(
            FaceReview.consume(
                arguments: ["-ReviewScreen", "today"],
                onboardingComplete: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)
    }

    func test_missingOrUnknownIsNil() {
        var consumed = false
        XCTAssertNil(
            FaceReview.consume(arguments: [], onboardingComplete: true, consumed: &consumed)
        )
        consumed = false
        XCTAssertNil(
            FaceReview.consume(
                arguments: ["-ReviewScreen"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
        consumed = false
        XCTAssertNil(
            FaceReview.consume(
                arguments: ["-ReviewScreen", "charts"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
        XCTAssertEqual(FaceReview(slug: "today"), .today)
        XCTAssertEqual(FaceReview(slug: "log"), .log)
        XCTAssertEqual(FaceReview(slug: "goals"), .goals)
        XCTAssertNil(FaceReview(slug: "insights"))
    }

    func test_extraCoverSlugsMapOntoSheets() {
        XCTAssertTrue(FaceReview.isLedgerSlug("today"))
        XCTAssertTrue(FaceReview.isLedgerSlug("ledger"))
        XCTAssertFalse(FaceReview.isLedgerSlug("insights"))
        XCTAssertEqual(FaceReview.sheet(forSlug: "insights"), .insights)
        XCTAssertEqual(FaceReview.sheet(forSlug: "log"), .insights)
        XCTAssertEqual(FaceReview.sheet(forSlug: "settings"), .settings)
        XCTAssertEqual(FaceReview.sheet(forSlug: "settingssheet"), .settings)
        XCTAssertEqual(FaceReview.sheet(forSlug: "goals"), .settings)
        XCTAssertEqual(FaceReview.extraLaunch(forSlug: "onboarding"), .onboarding)
        XCTAssertEqual(FaceReview.extraLaunch(forSlug: "insights"), .insights)
        XCTAssertEqual(FaceReview.extraLaunch(forSlug: "twist"), .twist)
        XCTAssertEqual(FaceReview.extraLaunch(forSlug: "twistsheet"), .twist)
        XCTAssertNil(FaceReview.sheet(forSlug: "charts"))
    }
}
