import UIKit

public class BeerCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var breweryLabel: UILabel!
    @IBOutlet weak var styleLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var abvLabel: UILabel!
    @IBOutlet weak var beerImageView: UIImageView!

    public override func awakeFromNib() {
        beerImageView.image = nil
    }

    public func configure(with beer: Beer) {
        nameLabel.text = beer.name
        breweryLabel.text = beer.brewery
        styleLabel.text = beer.style
        ratingLabel.text = beer.rating
        abvLabel.text = "\(beer.abv)% ABV"
        beerImageView.downloaded(from: beer.imageUrl)
    }
}
