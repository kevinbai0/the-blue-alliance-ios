import CoreData
import CoreSpotlight
import Foundation
import UIKit

protocol SearchViewControllerDelegate: AnyObject {
    func selectedEvent(_ event: Event)
    func selectedTeam(_ team: Team)
}

class SearchViewController: TBATableViewController {

    lazy private var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search Events and Teams"
        return searchController
    }()

    weak var delegate: SearchViewControllerDelegate?

    // MARK - Init

    init(persistentContainer: NSPersistentContainer, tbaKit: TBAKit, userDefaults: UserDefaults) {
        // Use the default init?
        super.init(persistentContainer: persistentContainer, tbaKit: tbaKit, userDefaults: userDefaults)

        title = "Search"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerReusableCell(EventTableViewCell.self)
        tableView.registerReusableCell(TeamTableViewCell.self)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal(_:)))
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            if indexPath.section == 0 {
                return tableView.dequeueReusableCell(indexPath: indexPath) as EventTableViewCell
            } else {
                return tableView.dequeueReusableCell(indexPath: indexPath) as TeamTableViewCell
            }
        }()
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .automatic)

        // Push to Team or Event
        if indexPath.section == 0 {
            delegate?.selectedEvent(Event())
        } else {
            delegate?.selectedTeam(Team())
        }
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Events"
        } else {
            return "Teams"
        }
    }

    // MARK: - UI Methods

    @objc private func dismissModal(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

}

extension SearchViewController: UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {

    }

}
