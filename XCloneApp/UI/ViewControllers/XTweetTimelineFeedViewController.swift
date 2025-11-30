//
//  XTimelineFeedViewController.swift
//  XCloneApp
//
//  Created by Abhay Curam on 10/13/25.
//

import UIKit
import Foundation

private typealias XTweetTimelineFeedTableViewDiffableDataSource = UITableViewDiffableDataSource<XTweetTimelineFeedTableViewSection, XTweetModel>
private typealias XTweetTimelineFeedTableViewDataSourceSnapshot = NSDiffableDataSourceSnapshot<XTweetTimelineFeedTableViewSection, XTweetModel>

private enum XTweetTimelineFeedTableViewSection {
    case main
}

/**
 * Our TimelineFeedViewController which display's the currently logged in user's X timeline feed.
 * This VC leverages a TableView with a DiffableDataSource for display of the timeline and leverages
 * a collection of Tweets in a sliding window data structure for it's backing data model.
 * It coordinates with the TweetTimelineService to load new tweets (hits Twitters pagination endpoint).
 */
public class XTweetTimelineFeedViewController: UIViewController, UITableViewDelegate {
    
    private let userSession: XUserSession
    private let tweetTimelineService: XTweetTimelineService
    private let imageDownloader: ImageDownloadRequestManager
    private let tweetTimelineDeque: XBoundedDeque<XTweetPageModel>
    
    private let debouncer: XDebouncer
    private var isFetchingTimeline: Bool = false
    
    private lazy var tableViewDataSource = makeDiffableTableViewDataSource()
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        let cellReuseID = XTweetTimelineFeedViewControllerConstants.cellReuseIdentifier
        tableView.register(XTweetTimelineTableViewCell.self, forCellReuseIdentifier: cellReuseID)
        tableView.backgroundColor = UIColor.white
        tableView.allowsSelection = false
        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        return tableView
    }()
    
    private struct XTweetTimelineFeedViewControllerConstants {
        static let cellReuseIdentifier = "x_tweet_timeline_feed_cell"
        static let tweetTimelineCapacity = 4
        static let debounceDelay: TimeInterval = 0.75
    }
    
    // MARK: Public Init
    public init(_ userSession: XUserSession,
                _ tweetTimelineService: XTweetTimelineService,
                _ imageDownloader: ImageDownloadRequestManager) {
        self.userSession = userSession
        self.tweetTimelineService = tweetTimelineService
        self.imageDownloader = imageDownloader
        let capacity = XTweetTimelineFeedViewControllerConstants.tweetTimelineCapacity
        self.tweetTimelineDeque = XBoundedDeque<XTweetPageModel>(capacity)
        let delay = XTweetTimelineFeedViewControllerConstants.debounceDelay
        self.debouncer = XDebouncer(delay)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: VC Layout and Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = tableViewDataSource
        view.addSubview(tableView)
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // If our timeline is empty let's kick off a fetch.
        // Eventually we can write some logic to kick off a
        // fetch every ten minutes or so.
        if tweetTimelineDeque.isEmpty {
            fetchAndLoadInitialTimelineData()
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let tweetModel = tableViewDataSource.itemIdentifier(for: indexPath) else { return 0 }
        let sizingCell = XTweetTimelineTableViewCell()
        let contentViewModel = XTweetContentViewModelFactory.createViewModel(tweetModel)
        let idealSize = CGSize(width: tableView.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        let cellHeight = sizingCell.sizeThatFitsContentViewModel(contentViewModel, idealSize).height
        return cellHeight
    }
    
    // MARK: UIScrollViewDelegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /*
         * Because we have embedded our tableView in a NavigationStack and we have to
         * handle phones with safeAreaInsets, we have to take into account any applied adjustedContentInset's.
         */
        let adjustedContentOffsetY = scrollView.contentOffset.y + scrollView.adjustedContentInset.top
        let adjustedContentSizeHeight = scrollView.contentSize.height + scrollView.adjustedContentInset.top + scrollView.adjustedContentInset.bottom
        if adjustedContentOffsetY < 0 {
            debouncer.perform { [weak self] in
                guard let strongSelf = self else { return }
                let paginationToken = strongSelf.tweetTimelineDeque.front?.previousPageToken
                strongSelf.fetchRecentTimelineData(paginationToken)
            }
        } else if adjustedContentOffsetY + scrollView.bounds.height > adjustedContentSizeHeight {
            debouncer.perform { [weak self] in
                guard let strongSelf = self else { return }
                let paginationToken = strongSelf.tweetTimelineDeque.back?.nextPageToken
                strongSelf.fetchOlderTimelineData(paginationToken)
            }
        }
    }
    
    // MARK: Private Helpers
    private func makeDiffableDataSourceSnapshot() -> XTweetTimelineFeedTableViewDataSourceSnapshot {
        var snapshot = XTweetTimelineFeedTableViewDataSourceSnapshot()
        snapshot.appendSections([.main])
        return snapshot
    }
    
    private func makeDiffableTableViewDataSource() -> XTweetTimelineFeedTableViewDiffableDataSource {
        let dataSource = XTweetTimelineFeedTableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, tweetModel in
            if let strongSelf = self {
                let cellReuseID = XTweetTimelineFeedViewControllerConstants.cellReuseIdentifier
                let cellContentViewModel = XTweetContentContainerViewModelFactory.createViewModel(tweetModel)
                if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: cellReuseID, for: indexPath) as? XTweetTimelineTableViewCell {
                    if dequeuedCell.imageDownloader == nil {
                        dequeuedCell.imageDownloader = strongSelf.imageDownloader
                    }
                    dequeuedCell.viewModel = cellContentViewModel
                    return dequeuedCell
                }
            }
            return nil
        }
        return dataSource
    }
    
    private func fetchRecentTimelineData(_ paginationToken: String?) {
        if !isFetchingTimeline {
            tweetTimelineService.fetchTweetTimeline(paginationToken) { [weak self] tweets, error in
                guard let strongSelf = self else { return }
                if let tweetPageModel = tweets, error == nil {
                    var shouldReloadData = false
                    if paginationToken == nil {
                        strongSelf.tweetTimelineDeque.removeAll()
                        shouldReloadData = true
                    }
                    let removedTweetPage = strongSelf.tweetTimelineDeque.insertFront(tweetPageModel)
                    let removedTweets = removedTweetPage.first?.tweets ?? []
                    let addedTweets = tweetPageModel.tweets
                    var dataSourceSnapshot = (shouldReloadData) ? strongSelf.makeDiffableDataSourceSnapshot() : strongSelf.tableViewDataSource.snapshot()
                    dataSourceSnapshot.deleteItems(removedTweets)
                    if let firstItem = dataSourceSnapshot.itemIdentifiers.first {
                        dataSourceSnapshot.insertItems(addedTweets, beforeItem: firstItem)
                    } else {
                        dataSourceSnapshot.appendItems(addedTweets)
                    }
                    if shouldReloadData {
                        strongSelf.tableViewDataSource.applySnapshotUsingReloadData(dataSourceSnapshot)
                    } else {
                        strongSelf.tableViewDataSource.apply(dataSourceSnapshot, animatingDifferences: true)
                    }
                }
                strongSelf.isFetchingTimeline = false
            }
        }
    }
    
    private func fetchOlderTimelineData(_ paginationToken: String?) {
        if !isFetchingTimeline {
            tweetTimelineService.fetchTweetTimeline(paginationToken) { [weak self] tweets, error in
                guard let strongSelf = self else { return }
                if let tweetPageModel = tweets, error == nil {
                    let removedTweetPage = strongSelf.tweetTimelineDeque.insertBack(tweetPageModel)
                    let addedTweets = tweetPageModel.tweets
                    let removedTweets = removedTweetPage.first?.tweets ?? []
                    var dataSourceSnapshot = strongSelf.tableViewDataSource.snapshot()
                    dataSourceSnapshot.deleteItems(removedTweets)
                    dataSourceSnapshot.appendItems(addedTweets)
                    strongSelf.tableViewDataSource.apply(dataSourceSnapshot, animatingDifferences: true)
                }
                strongSelf.isFetchingTimeline = false
            }
        }
    }
    
    private func fetchAndLoadInitialTimelineData() {
        if !isFetchingTimeline {
            tweetTimelineService.fetchTweetTimeline { [weak self] tweets, error in
                guard let strongSelf = self else { return }
                if let tweetPageModel = tweets, error == nil {
                    let removedTweetPage = strongSelf.tweetTimelineDeque.insertBack(tweetPageModel)
                    let addedTweets = tweetPageModel.tweets
                    let removedTweets = removedTweetPage.first?.tweets ?? []
                    var dataSourceSnapshot = strongSelf.makeDiffableDataSourceSnapshot()
                    dataSourceSnapshot.deleteItems(removedTweets)
                    dataSourceSnapshot.appendItems(addedTweets)
                    strongSelf.tableViewDataSource.applySnapshotUsingReloadData(dataSourceSnapshot)
                }
                strongSelf.isFetchingTimeline = false
            }
        }
    }
    
}
