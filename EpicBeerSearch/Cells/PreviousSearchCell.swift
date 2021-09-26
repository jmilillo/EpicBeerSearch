import UIKit

class PreviousSearchCell: UITableViewCell {
    @IBOutlet weak var queryLabel: UILabel!
    @IBOutlet weak var resultTypeLabel: UILabel!

    public func configure(query: String, type: SearchType) {
        queryLabel.text = query.capitalized
        resultTypeLabel.text = type == .beer ? "🍺" : "🏢"
    }
}
