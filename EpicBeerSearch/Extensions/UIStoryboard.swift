import UIKit

extension UIStoryboard {
    public func instantiateViewController<T>(withIdentifier identifier: String) -> T {
        guard let viewController = instantiateViewController(withIdentifier: identifier) as? T else {
            fatalError("Could not instantiate view controller: \(identifier)")
        }

        return viewController
    }
}
