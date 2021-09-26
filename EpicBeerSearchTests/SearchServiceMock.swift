import XCTest
import RxSwift
@testable import EpicBeerSearch

public class SearchServiceMock: SearchService {
    var searchData = SearchResult(beers: [Beer(name: "Beer", brewery: "Mock", imageUrl: URL(string: "http://www.fake.url")!, abv: "5", style: "Porter", rating: "5")])
    var previousSearchesData = SearchListResult(previousSearches: [Search(query: "Mock", total: 1, type: .beer),
                                                                   Search(query: "Mack", total: 1, type: .brewery)])
    var errorToThrow: ServiceError?

    public func search(for: String, type: SearchType) -> Observable<SearchResult> {
        if let error = errorToThrow {
            return Observable.error(error)
        } else {
            return Observable.just(searchData)
        }
    }

    public func getPreviousSearches() -> Observable<SearchListResult> {
        if let error = errorToThrow {
            return Observable.error(error)
        } else {
            return Observable.just(previousSearchesData)
        }
    }

}
