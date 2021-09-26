import UIKit

public class InformationCell: UITableViewCell {
    @IBOutlet weak var symbolView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!

    public override func awakeFromNib() {
        separatorInset.right = .greatestFiniteMagnitude
    }
}
