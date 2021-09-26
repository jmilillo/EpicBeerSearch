import RxCocoa
import RxSwift

extension ObservableConvertibleType {
    public func asDriverLogError(_ file: StaticString = #file, _ line: UInt = #line) -> SharedSequence<DriverSharingStrategy, Element> {
        return asDriver(onErrorRecover: { print("Error:", $0, " in file:", file, " atLine:", line); return .empty() })
    }
}
