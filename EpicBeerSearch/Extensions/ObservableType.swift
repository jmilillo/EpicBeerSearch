import RxSwift
import RxSwiftExt

extension ObservableType {
    public func successesOnly<T, E>() -> Observable<T> where Self.Element == Result<T, E> {
        return filterMap({ (result: Result<T, E>) -> FilterMap<T> in
                switch result {
                case .success(let element):
                    return .map(element)
                default:
                    return .ignore
                }
            })
    }
}

