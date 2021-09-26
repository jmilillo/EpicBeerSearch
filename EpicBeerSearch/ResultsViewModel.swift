import UIKit
import RxCocoa
import RxSwift
import RxSwiftExt

struct ResultsViewModel {
    typealias ResultSnapshot = NSDiffableDataSourceSnapshot<Int, BeerItem>

    struct UIInputs {
        let viewAppeared: Observable<Void>
        let searchAppeared: Observable<Void>
        let filterResults: Observable<String>
        let searchEntered: Observable<(String, SearchType)>
        let searchCanceled: Observable<Void>
    }

    // MARK: - View Controller Outputs
    let snapshot: Driver<ResultSnapshot>
    let hideActivityIndicator: Driver<Bool>
    let title: Driver<String>
}

extension ResultsViewModel {
    init(with inputs: UIInputs, searchService: SearchService, backgroundScheduler: ImmediateSchedulerType) {

        let previousSearches = Observable.merge(inputs.viewAppeared, inputs.searchCanceled)
            .observe(on: backgroundScheduler)
            .flatMap({ _ in
                searchService.getPreviousSearches()
                    .map { result -> Result<SearchListResult, ServiceError> in
                        .success(result)
                    }
                    .catch { error in
                        return Observable.just(Result<SearchListResult, ServiceError>.failure(ServiceError.unknown))
                    }
            })
            .share()

        let previousSearchesSnapshot = previousSearches
            .map({ result -> ResultSnapshot in
                var snapshot = ResultSnapshot()
                snapshot.appendSections([0])
                switch result {
                case .success(let element):
                    element.previousSearches.forEach { search in
                        snapshot.appendItems([BeerItem.previousSearch(search.query, search.type)], toSection: 0)
                    }
                case .failure:
                    let message = NSLocalizedString("Something went wrong, I blame Dave.", comment: "")
                    let symbolImage = UIImage(systemName: "exclamationmark.octagon")?.withTintColor(.systemRed).withRenderingMode(.alwaysOriginal)
                    snapshot.appendItems([BeerItem.message(message, symbolImage)], toSection: 0)
                }
                return snapshot
            })

        let filteredSearchesSnapshot = inputs.filterResults
            .withLatestFrom(previousSearches.successesOnly()) { filter, searchResult -> ResultSnapshot in
                var snapshot = ResultSnapshot()
                snapshot.appendSections([0])

                if filter.isEmpty {
                    searchResult.previousSearches.forEach { search in
                        snapshot.appendItems([BeerItem.previousSearch(search.query, search.type)], toSection: 0)
                    }
                    return snapshot
                }

                let filteredResults = searchResult.previousSearches.filter { $0.query.lowercased().contains(filter.lowercased()) }

                if filteredResults.isEmpty {
                    let message = NSLocalizedString("Keep searching, I have faith in you.", comment: "")
                    let symbolImage = UIImage(systemName: "plus.magnifyingglass")?.withTintColor(.secondaryLabel).withRenderingMode(.alwaysOriginal)
                    snapshot.appendItems([BeerItem.message(message, symbolImage)], toSection: 0)
                    return snapshot
                }

                filteredResults.forEach { search in
                    snapshot.appendItems([BeerItem.previousSearch(search.query, search.type)], toSection: 0)
                }
                return snapshot
            }

        let resetSearchResultsSnapshot = Observable.merge(inputs.searchCanceled, inputs.searchAppeared)
            .withLatestFrom(previousSearchesSnapshot)

        let searchResult = inputs.searchEntered
            .observe(on: backgroundScheduler)
            .flatMap({ search in
                searchService.search(for: search.0.trimmingCharacters(in: .whitespacesAndNewlines), type: search.1)
                    .map { result -> Result<SearchResult, ServiceError> in
                        .success(result)
                    }
                    .catch { error in
                        return Observable.just(Result<SearchResult, ServiceError>.failure(ServiceError.unknown))
                    }
            })

        let searchSnapshot = searchResult
            .map({ result -> ResultSnapshot in
                var snapshot = ResultSnapshot()
                snapshot.appendSections([0])
                switch result {
                case .success(let element):
                    element.beers.forEach { beer in
                        snapshot.appendItems([BeerItem.beer(beer)], toSection: 0)
                    }
                case .failure:
                    let message = NSLocalizedString("Something went wrong, I blame Dave.", comment: "")
                    let symbolImage = UIImage(systemName: "exclamationmark.octagon")?.withTintColor(.systemRed).withRenderingMode(.alwaysOriginal)
                    snapshot.appendItems([BeerItem.message(message, symbolImage)], toSection: 0)
                }
                return snapshot
            })

        let emptySnapshot = inputs.searchEntered
            .map {_ -> ResultSnapshot in
                var snapshot = ResultSnapshot()
                snapshot.appendSections([0])
                return snapshot
            }

        snapshot = Observable.merge(previousSearchesSnapshot, filteredSearchesSnapshot, resetSearchResultsSnapshot, searchSnapshot, emptySnapshot)
            .asDriverLogError()

        let queryComplete = Observable.merge(previousSearches.mapTo(true), searchSnapshot.mapTo(true))
        let queryStarted = emptySnapshot.mapTo(false)
        hideActivityIndicator = Observable.merge(queryStarted, queryComplete)
            .asDriverLogError()

        let recentSearches = Observable.merge(previousSearchesSnapshot, resetSearchResultsSnapshot)
            .mapTo(NSLocalizedString("Recent Searches", comment: ""))
        let newSearch = emptySnapshot
            .mapTo(NSLocalizedString("Searching...", comment: ""))
        let searchResults = searchSnapshot
            .mapTo(NSLocalizedString("Search Results", comment: ""))
        title = Observable.merge(recentSearches, newSearch, searchResults)
            .startWith(NSLocalizedString("Loading...", comment: ""))
            .asDriverLogError()
    }
}

enum BeerItem: Hashable {
    case beer(Beer)
    case previousSearch(String, SearchType)
    case message(String, UIImage?)
}
