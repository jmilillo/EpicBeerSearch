import UIKit

extension UITableView {
    public func dequeueReusableCell<T>(withIdentifier identifier: String) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: identifier) as? T else {
            fatalError("Could not dequeue \(identifier)")
        }

        return cell
    }
}
