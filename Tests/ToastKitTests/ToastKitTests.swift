import XCTest
@testable import ToastKit

final class ToastKitTests: XCTestCase {

    // MARK: - ToastStyle defaults

    func test_toastStyle_defaultValues() {
        let style = ToastStyle()

        XCTAssertEqual(style.duration, 2.5)
        XCTAssertEqual(style.cornerRadius, 10)
        XCTAssertEqual(style.horizontalPadding, 24)
        XCTAssertEqual(style.edgeOffset, 48)
    }

    func test_toastStyle_customValues() {
        let style = ToastStyle(
            duration: 5.0,
            position: .top,
            type: .success,
            cornerRadius: 20,
            horizontalPadding: 16,
            edgeOffset: 60
        )

        XCTAssertEqual(style.duration, 5.0)
        XCTAssertEqual(style.cornerRadius, 20)
        XCTAssertEqual(style.horizontalPadding, 16)
        XCTAssertEqual(style.edgeOffset, 60)
        if case .top = style.position {} else {
            XCTFail("Expected position .top")
        }
    }

    // MARK: - ToastPosition

    func test_toastPosition_allCases() {
        let positions: [ToastPosition] = [.top, .center, .bottom]
        XCTAssertEqual(positions.count, 3)
    }

    // MARK: - ToastType colors

    func test_toastType_success_hasWhiteText() {
        let type = ToastType.success
        XCTAssertEqual(type.textColor, .white)
    }

    func test_toastType_error_hasWhiteText() {
        let type = ToastType.error
        XCTAssertEqual(type.textColor, .white)
    }

    func test_toastType_warning_hasWhiteText() {
        let type = ToastType.warning
        XCTAssertEqual(type.textColor, .white)
    }

    func test_toastType_info_hasWhiteText() {
        let type = ToastType.info
        XCTAssertEqual(type.textColor, .white)
    }

    func test_toastType_custom_backgroundAndTextColors() {
        let bg = UIColor.purple
        let text = UIColor.yellow
        let type = ToastType.custom(backgroundColor: bg, textColor: text)

        XCTAssertEqual(type.backgroundColor, bg)
        XCTAssertEqual(type.textColor, text)
    }

    // MARK: - ToastManager singleton

    func test_toastManager_sharedIsSingleton() {
        let first = ToastManager.shared
        let second = ToastManager.shared
        XCTAssertTrue(first === second)
    }

    func test_toastManager_dismissDoesNotCrashWhenNothingIsShown() {
        // Should not crash or throw even if no toast is currently displayed.
        ToastManager.shared.dismiss(animated: false)
        ToastManager.shared.dismiss(animated: true)
    }
}
