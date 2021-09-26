import XCTest
import RxCocoa
import RxSwift
import RxTest

@testable import EpicBeerSearch

class ResultsViewModelTests: XCTestCase {

    var sut: ResultsViewModel!
    var testScheduler: TestScheduler!
    var disposeBag: DisposeBag!
    var inputs: ResultsViewModel.UIInputs!
    var searchService: SearchServiceMock!

    var viewAppearedTrigger: PublishRelay<Void>!
    var searchAppearedTrigger: PublishRelay<Void>!
    var filterResultsTrigger: PublishRelay<String>!
    var searchEnteredTrigger: PublishRelay<(String, SearchType)>!
    var searchCanceledTrigger: PublishRelay<Void>!

    override func setUpWithError() throws {
        testScheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
        searchService = SearchServiceMock()

        viewAppearedTrigger = PublishRelay()
        searchAppearedTrigger = PublishRelay()
        filterResultsTrigger = PublishRelay()
        searchEnteredTrigger = PublishRelay()
        searchCanceledTrigger = PublishRelay()

        testScheduler.scheduleAt(0) { [viewAppearedTrigger] in
            viewAppearedTrigger?.accept(())
        }

        inputs = ResultsViewModel.UIInputs(viewAppeared: viewAppearedTrigger.asObservable().take(1),
                                           searchAppeared: searchAppearedTrigger.asObservable(),
                                           filterResults: filterResultsTrigger.asObservable(),
                                           searchEntered: searchEnteredTrigger.asObservable(),
                                           searchCanceled: searchCanceledTrigger.asObservable())

        sut = ResultsViewModel(with: inputs, searchService: searchService, backgroundScheduler: testScheduler)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_snapshot_emitsPreviousSearches() throws {
        let snapshotItems = sut.snapshot
            .map { $0.itemIdentifiers }
        let observer = createObserver(from: snapshotItems)

        testScheduler.start()

        let expectedEvents: [Recorded<Event<[BeerItem]>>] = [
            .next(1, [.previousSearch("Mock", .beer),
                      .previousSearch("Mack", .brewery)])
        ]
        
        XCTAssertEqual(expectedEvents, observer.events)
    }

    func test_snapshot_withServiceError_emitsErrorItem() throws {
        searchService.errorToThrow = ServiceError.unknown
        let snapshotItems = sut.snapshot
            .map { $0.itemIdentifiers }
        let observer = createObserver(from: snapshotItems)

        testScheduler.start()

        let expectedErrorImage = UIImage(systemName: "exclamationmark.octagon")?.withTintColor(.systemRed).withRenderingMode(.alwaysOriginal)
        let expectedEvents: [Recorded<Event<[BeerItem]>>] = [
            .next(1, [.message("Something went wrong, I blame Dave.", expectedErrorImage)])
        ]

        XCTAssertEqual(expectedEvents, observer.events)
    }

    func test_snapshot_withFilter_emitsPreviousSearchesSubset() throws {
        let snapshotItems = sut.snapshot
            .map { $0.itemIdentifiers }
        let observer = createObserver(from: snapshotItems)

        testScheduler.scheduleAt(100) { [filterResultsTrigger] in
            filterResultsTrigger?.accept("m")
        }

        testScheduler.scheduleAt(200) { [filterResultsTrigger] in
            filterResultsTrigger?.accept("ma")
        }

        testScheduler.scheduleAt(300) { [filterResultsTrigger] in
            filterResultsTrigger?.accept("map")
        }

        testScheduler.start()

        let emptyListImage = UIImage(systemName: "plus.magnifyingglass")?.withTintColor(.secondaryLabel).withRenderingMode(.alwaysOriginal)
        let expectedEvents: [Recorded<Event<[BeerItem]>>] = [
            .next(1, [.previousSearch("Mock", .beer),
                      .previousSearch("Mack", .brewery)]),
            .next(100, [.previousSearch("Mock", .beer),
                        .previousSearch("Mack", .brewery)]),
            .next(200, [.previousSearch("Mack", .brewery)]),
            .next(300, [.message("Keep searching, I have faith in you.", emptyListImage)])
        ]

        XCTAssertEqual(expectedEvents, observer.events)
    }

    func test_snapshot_withEmptyFilter_emitsPreviousSearches() throws {
        let snapshotItems = sut.snapshot
            .map { $0.itemIdentifiers }
        let observer = createObserver(from: snapshotItems)

        testScheduler.scheduleAt(100) { [filterResultsTrigger] in
            filterResultsTrigger?.accept("map")
        }

        testScheduler.scheduleAt(200) { [filterResultsTrigger] in
            filterResultsTrigger?.accept("")
        }

        testScheduler.start()

        let emptyListImage = UIImage(systemName: "plus.magnifyingglass")?.withTintColor(.secondaryLabel).withRenderingMode(.alwaysOriginal)
        let expectedEvents: [Recorded<Event<[BeerItem]>>] = [
            .next(1, [.previousSearch("Mock", .beer),
                      .previousSearch("Mack", .brewery)]),
            .next(100, [.message("Keep searching, I have faith in you.", emptyListImage)]),
            .next(200, [.previousSearch("Mock", .beer),
                        .previousSearch("Mack", .brewery)])
        ]

        XCTAssertEqual(expectedEvents, observer.events)
    }

    func test_snapshot_whenSearchEntered_emitsSearchResults() throws {
        let snapshotItems = sut.snapshot
            .map { $0.itemIdentifiers }
        let observer = createObserver(from: snapshotItems)

        testScheduler.scheduleAt(100) { [searchEnteredTrigger] in
            searchEnteredTrigger?.accept(("Mack", .brewery))
        }

        testScheduler.start()

        let expectedEvents: [Recorded<Event<[BeerItem]>>] = [
            .next(1, [.previousSearch("Mock", .beer),
                      .previousSearch("Mack", .brewery)]),
            .next(100, []),
            .next(101, [.beer(Beer(name: "Beer", brewery: "Mock", imageUrl: URL(string: "http://www.fake.url")!, abv: "5", style: "Porter", rating: "5"))])
        ]

        XCTAssertEqual(expectedEvents, observer.events)
    }

    func test_snapshot_whenSearchEntered_withFailure_emitsErrorItem() throws {
        let snapshotItems = sut.snapshot
            .map { $0.itemIdentifiers }
        let observer = createObserver(from: snapshotItems)

        testScheduler.scheduleAt(100) { [searchService, searchEnteredTrigger] in
            searchService?.errorToThrow = ServiceError.unknown
            searchEnteredTrigger?.accept(("Mack", .brewery))
        }

        testScheduler.start()

        let expectedErrorImage = UIImage(systemName: "exclamationmark.octagon")?.withTintColor(.systemRed).withRenderingMode(.alwaysOriginal)
        let expectedEvents: [Recorded<Event<[BeerItem]>>] = [
            .next(1, [.previousSearch("Mock", .beer),
                      .previousSearch("Mack", .brewery)]),
            .next(100, []),
            .next(101, [.message("Something went wrong, I blame Dave.", expectedErrorImage)])
        ]

        XCTAssertEqual(expectedEvents, observer.events)
    }

    func test_hideActivityIndicator_whenSearching_emits() throws {
        let observer = createObserver(from: sut.hideActivityIndicator)

        testScheduler.scheduleAt(100) { [searchEnteredTrigger] in
            searchEnteredTrigger?.accept(("Mack", .brewery))
        }

        testScheduler.start()

        let expectedEvents: [Recorded<Event<Bool>>] = [
            .next(1, true),
            .next(100, false),
            .next(101, true)
        ]

        XCTAssertEqual(expectedEvents, observer.events)
    }

    func test_title_whenSearching_emitsResultsTitle() throws {
        let observer = createObserver(from: sut.title)

        testScheduler.scheduleAt(100) { [searchEnteredTrigger] in
            searchEnteredTrigger?.accept(("Mack", .brewery))
        }

        testScheduler.start()

        let expectedEvents: [Recorded<Event<String>>] = [
            .next(0, "Loading..."),
            .next(1, "Recent Searches"),
            .next(100, "Searching..."),
            .next(101, "Search Results")
        ]

        XCTAssertEqual(expectedEvents, observer.events)
    }

    private func createObserver<T>(from driver: Driver<T>) -> TestableObserver<T> {
        let observer = testScheduler.createObserver(T.self)
        driver.drive(observer)
            .disposed(by: disposeBag)
        return observer
    }
}
