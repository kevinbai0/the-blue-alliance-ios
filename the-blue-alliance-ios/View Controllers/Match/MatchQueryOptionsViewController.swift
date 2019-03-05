import CoreData
import Foundation
import UIKit

protocol MatchQueryOptionsDelegate: AnyObject {
    func updateQuery(query: MatchQueryOptions)
}

// Backing enums to setup our table view data source
private enum QuerySections: String, CaseIterable {
    case sort = "Sort"
    case filter = "Filter"
}

private enum SortRows: String, CaseIterable {
    case reverse = "kMatchSortReverse"
}

private enum FilterRows: String, CaseIterable {
    case favorites = "kMatchFilterFavorites"
}

// Backing structs to power our data
struct MatchQueryOptions {
    var sort: MatchSortOptions
    var filter: MatchFilterOptions

    struct MatchSortOptions {
        var reverse: Bool
    }

    struct MatchFilterOptions {
        var favorites: Bool
    }
}

class MatchQueryOptionsViewController: TBATableViewController {

    private var query: MatchQueryOptions

    weak var delegate: MatchQueryOptionsDelegate?

    init(persistentContainer: NSPersistentContainer, tbaKit: TBAKit, userDefaults: UserDefaults) {
        query = MatchQueryOptions(sort: MatchQueryOptions.MatchSortOptions(reverse: false), filter: MatchQueryOptions.MatchFilterOptions(favorites: false))
        super.init(style: .plain, persistentContainer: persistentContainer, tbaKit: tbaKit, userDefaults: userDefaults)

        title = "Match Sort/Filter"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(saveMatchQuery))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return QuerySections.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let querySection = querySection(index: section) else {
            fatalError("Unsupported query section")
        }
        switch querySection {
        case .sort:
            return SortRows.allCases.count
        case .filter:
            return FilterRows.allCases.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let querySection = querySection(index: indexPath.section) else {
            fatalError("Unsupported query section")
        }
        let cell: SwitchTableViewCell = {
            switch querySection {
            case .sort:
                let switchCell = SwitchTableViewCell(switchToggled: { [weak self] (_ sender: UISwitch) in
                    self?.query.sort.reverse = sender.isOn
                })
                switchCell.textLabel?.text = "Reverse"
                switchCell.detailTextLabel?.text = "Show matches in ascending order"
                switchCell.switchView.isOn = self.query.sort.reverse
                return switchCell
            case .filter:
                // TODO: Disable this one if they don't have myTBA enabled
                let switchCell = SwitchTableViewCell(switchToggled: { [weak self] (_ sender: UISwitch) in
                    self?.query.filter.favorites = sender.isOn
                })
                switchCell.textLabel?.text = "Favorites"
                switchCell.detailTextLabel?.text = "Show only matches with myTBA favorite teams playing"
                switchCell.detailTextLabel?.numberOfLines = 0
                switchCell.switchView.isOn = self.query.filter.favorites
                return switchCell
            }
        }()
        cell.detailTextLabel?.numberOfLines = 0
        return cell
    }

    // MARK: - Table View Delegate

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let querySection = querySection(index: section) else {
            fatalError("Unsupported query section")
        }
        return querySection.rawValue
    }

    // MAKR: - Private Functions

    private func querySection(index: Int) -> QuerySections? {
        let sections = QuerySections.allCases
        return index < sections.count ? sections[index] : nil
    }

    @objc private func saveMatchQuery() {
        delegate?.updateQuery(query: query)
        navigationController?.dismiss(animated: true, completion: nil)
    }

}
