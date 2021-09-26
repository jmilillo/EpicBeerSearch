import UIKit
import RxCocoa
import RxSwift

public protocol SearchService {
    func search(for: String, type: SearchType) -> Observable<SearchResult>
    func getPreviousSearches() -> Observable<SearchListResult>
}

public struct SearchServiceImpl: SearchService {
    public func getPreviousSearches() -> Observable<SearchListResult> {
        guard let url = URL(string: "http://adamsweb.asuscomm.com:8080/epicbeersearch/ebs_get_search.py?message_limit=30") else {
            return Observable.error(ServiceError.unknown)
        }
        let request = URLRequest(url: url)
        return URLSession.shared.rx.response(request: request)
            .map({ (response: HTTPURLResponse, data: Data) -> SearchListResult in
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode(SearchListResult.self, from: data)
                }
            })
    }
    public func search(for query: String, type: SearchType = .beer) -> Observable<SearchResult> {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://adamsweb.asuscomm.com:8080/epicbeersearch/ebs_untappd.py?search=\(encodedQuery)&search_type=\(type.rawValue)") else {
            return Observable.error(ServiceError.unknown)
        }
        let request = URLRequest(url: url)
        return URLSession.shared.rx.response(request: request)
            .map({ (response: HTTPURLResponse, data: Data) -> SearchResult in
                do {
                    let decoder = JSONDecoder()
                    return try decoder.decode(SearchResult.self, from: data)
                }
            })
    }
}

public struct SearchListResult: Codable {
    private enum CodingKeys: String, CodingKey {
        case previousSearches = "beer_list"
    }

    let previousSearches: [Search]
}

public struct Search: Codable {
    private enum CodingKeys: String, CodingKey {
        case query = "search"
        case total = "search_total"
        case type = "search_type"
    }
    let query: String
    let total: Int
    let type: SearchType
}

public enum SearchType: String, Codable {
    case beer
    case brewery
}

public enum ServiceError: Error, Equatable {
    case unknown
}

public struct SearchResult: Codable {
    private enum CodingKeys: String, CodingKey {
        case beers = "beer_list"
    }

    let beers: [Beer]
}

public struct Beer: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case name
        case rating
        case style
        case abv
        case imageUrl = "image_url"
        case brewery = "brewery_name"
    }

    let name: String
    let brewery: String
    let imageUrl: URL
    let abv: String
    let style: String
    let rating: String
}
