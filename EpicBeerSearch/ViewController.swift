import UIKit
import RxRelay
import RxSwift

class ViewController: UIViewController {

    typealias DataSource = UITableViewDiffableDataSource<Int, BeerItem>

    var viewModelFactory: (ResultsViewModel.UIInputs) -> ResultsViewModel = { (_) in
        fatalError("Must provide factory function first.")
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    private let disposeBag = DisposeBag()
    private var dataSource: DataSource?
    private let filterRelay = PublishRelay<String>()
    private let searchRelay = PublishRelay<(String, SearchType)>()
    private let searchCanceledRelay = PublishRelay<Void>()
    private let searchControllerAppeared = PublishRelay<Void>()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureSearch()
        let inputs = ResultsViewModel.UIInputs(viewAppeared: rx.methodInvoked(#selector(viewDidAppear(_:))).map { _ in }.take(1),
                                               searchAppeared: searchControllerAppeared.asObservable(),
                                               filterResults: filterRelay.asObservable(),
                                               searchEntered: searchRelay.asObservable(),
                                               searchCanceled: searchCanceledRelay.asObservable())

        let viewModel = viewModelFactory(inputs)
        bind(to: viewModel)
    }

    private func configureSearch() {
        let searchController = UISearchController()
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.scopeButtonTitles = [NSLocalizedString("Beer", comment: ""), NSLocalizedString("Brewery", comment: "")]
        searchController.delegate = self
        searchController.searchBar.delegate = self

        navigationItem.searchController = searchController
    }

    private func bind(to viewModel: ResultsViewModel) {
        dataSource = createDataSouce()

        dataSource?.defaultRowAnimation = .fade
        tableView.dataSource = dataSource

        viewModel.snapshot
            .drive { [dataSource] snapshot in
                dataSource?.apply(snapshot)
            }
            .disposed(by: disposeBag)

        viewModel.title
            .drive(headerLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.hideActivityIndicator
            .drive(activityIndicator.rx.isHidden)
            .disposed(by: disposeBag)

        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                let item = self?.dataSource?.itemIdentifier(for: indexPath)
                switch item {
                case let .previousSearch(query, type):
                    self?.searchRelay.accept((query, type))
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    private func createDataSouce() -> DataSource {
        return DataSource(tableView: tableView, cellProvider: { (tableView, indexPath, item) -> UITableViewCell? in
            switch item {
            case .previousSearch(let query, let type):
                let cell = tableView.dequeueReusableCell(withIdentifier: "RecentSearch") as PreviousSearchCell
                cell.configure(query: query, type: type)
                return cell

            case let .message(title, image):
                let cell = tableView.dequeueReusableCell(withIdentifier: "Informational") as InformationCell
                cell.messageLabel.text = title
                cell.symbolView.image = image
                return cell

            case let .beer(info):
                let cell = tableView.dequeueReusableCell(withIdentifier: "BeerResult") as BeerCell
                cell.configure(with: info)
                return cell
            }
        })
    }
}

extension ViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        searchControllerAppeared.accept(())
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchQuery = navigationItem.searchController?.searchBar.text, let scopeIndex = navigationItem.searchController?.searchBar.selectedScopeButtonIndex else {
            return
        }
        searchRelay.accept((searchQuery, scopeIndex == 0 ? .beer : .brewery))
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchCanceledRelay.accept(())
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterRelay.accept(searchText)
    }
}
