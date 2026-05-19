import XCTest
@testable import PalmAura

final class PalmPhotoStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        PalmPhotoStore.clearAll()
    }

    override func tearDown() {
        PalmPhotoStore.clearAll()
        super.tearDown()
    }

    func testPendingKeysAreUniquePerReviewAttempt() {
        let first = PalmPhotoStore.makePendingKey()
        let second = PalmPhotoStore.makePendingKey()

        XCTAssertNotEqual(first, second)
        XCTAssertTrue(first.hasPrefix("pending-"))
        XCTAssertTrue(second.hasPrefix("pending-"))
    }

    func testBindMovesSpecificPendingPhotoWithoutTouchingOtherPendingPhotos() throws {
        let firstKey = PalmPhotoStore.makePendingKey()
        let secondKey = PalmPhotoStore.makePendingKey()
        let firstData = Data([0x01, 0x02, 0x03])
        let secondData = Data([0x04, 0x05, 0x06])

        let firstPendingURL = try XCTUnwrap(PalmPhotoStore.save(firstData, key: firstKey))
        let secondPendingURL = try XCTUnwrap(PalmPhotoStore.save(secondData, key: secondKey))

        let boundURL = try XCTUnwrap(PalmPhotoStore.bind(pendingKey: firstKey, to: "reading-123"))

        XCTAssertFalse(FileManager.default.fileExists(atPath: firstPendingURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: secondPendingURL.path))
        XCTAssertEqual(try Data(contentsOf: boundURL), firstData)
        XCTAssertEqual(try Data(contentsOf: secondPendingURL), secondData)
    }
}
