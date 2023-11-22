//
//  StickerPackMakerTests.swift
//  StickerPackMakerTests
//
//  Created by Stef Kors on 22/11/2023.
//

import XCTest
@testable import StickerPackMaker
import MediaCore
import Photos

final class StickerPackMakerTests: XCTestCase {
    func testImageProcessing() async throws {
        let image = UIImage(resource: .performanceNemo)
        let result = await ImagePipeline.parse(fetched: FetchedImage(image: image, photo: Photo(phAsset: PHAsset())))
        XCTAssert(result != nil)
        XCTAssert(result?.image != nil)
        XCTAssert(result?.image?.size != .zero)
    }

    func testPerformanceExample() async throws {
        // This is an example of a performance test case.
        measureAsync(for: {
            let image = UIImage(resource: .performanceNemo)
            let result = await ImagePipeline.parse(fetched: FetchedImage(image: image, photo: Photo(phAsset: PHAsset())))
            XCTAssert(result != nil)
            XCTAssert(result?.image != nil)
            XCTAssert(result?.image?.size != .zero)
            // Put the code you want to measure the time of here.
        })
    }

}

extension XCTestCase {
    func measureAsync(
        timeout: TimeInterval = 2.0,
        for block: @escaping () async throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        measureMetrics(
            [.wallClockTime],
            automaticallyStartMeasuring: true
        ) {
            let expectation = expectation(description: "finished")
            Task { @MainActor in
                do {
                    try await block()
                    expectation.fulfill()
                } catch {
                    XCTFail(error.localizedDescription, file: file, line: line)
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: timeout)
        }
    }
}
