import Foundation
import CoreData
import UIKit

class MyTBAContainerViewController: ContainerViewController, Subscribable {

    let myTBA: MyTBA

    lazy var favoriteBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "ic_star"), style: .plain, target: self, action: #selector(myTBAPreferencesTapped))
    }()

    // TODO: Move out of MyTBAContainerViewController
    lazy var matchQueryBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(named: "ic_filter"), style: .plain, target: self, action: #selector(matchQueryTapped))
    }()

    var subscribableModel: MyTBASubscribable {
        fatalError("Implement subscribableModel in subclass")
    }

    // MARK: - Init

    init(viewControllers: [ContainableViewController], navigationTitle: String? = nil, navigationSubtitle: String?  = nil, segmentedControlTitles: [String]? = nil, myTBA: MyTBA, persistentContainer: NSPersistentContainer, tbaKit: TBAKit, userDefaults: UserDefaults) {
        self.myTBA = myTBA

        super.init(viewControllers: viewControllers, navigationTitle: navigationTitle, navigationSubtitle: navigationSubtitle, segmentedControlTitles: segmentedControlTitles, persistentContainer: persistentContainer, tbaKit: tbaKit, userDefaults: userDefaults)

        updateBarButtonItems()

        myTBA.authenticationProvider.add(observer: self)

        containerDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Interface Methods

    func updateBarButtonItems(showingMatches: Bool = false) {
        var barButtonItems: [UIBarButtonItem] = []
        if myTBA.isAuthenticated {
            barButtonItems.append(favoriteBarButtonItem)
        }
        if showingMatches {
            barButtonItems.append(matchQueryBarButtonItem)
        }
        navigationItem.rightBarButtonItems = barButtonItems
    }

    @objc func myTBAPreferencesTapped() {
        presentMyTBAPreferences()
    }

    @objc func matchQueryTapped() {
        let queryViewController = MatchQueryOptionsViewController(persistentContainer: persistentContainer, tbaKit: tbaKit, userDefaults: userDefaults)
        queryViewController.delegate = self as! MatchQueryOptionsDelegate

        let nav = UINavigationController(rootViewController: queryViewController)
        nav.modalPresentationStyle = .formSheet

        navigationController?.present(nav, animated: true, completion: nil)
    }

}

extension MyTBAContainerViewController: MyTBAAuthenticationObservable {

    func authenticated() {
        updateBarButtonItems()
    }

    func unauthenticated() {
        updateBarButtonItems()
    }

}

extension MyTBAContainerViewController: ContainerDelegate {

    func changedContainedViewController(viewController: UIViewController) {
        updateBarButtonItems(showingMatches: viewController is MatchesViewController)
    }

}
