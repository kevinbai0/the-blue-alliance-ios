import Foundation
import UIKit
import CoreData

protocol TeamSummaryViewControllerDelegate: AnyObject {
    func awardsSelected()
    func matchSelected(_ match: Match)
}

private enum TeamSummarySections: Int, CaseIterable {
    case info
    case nextMatch
    case lastMatch
}

private enum TeamSummaryInfoRow {
    case rank(rank: Int)
    case awards(count: Int)
    case pit // only during CMP, and if they exist
    case record(wlt: WLT) // don't show record for 2015, because no wins
    case alliance(allianceStatus: String)
    case status(overallStatus: String)
    case breakdown(tiebreakerInfo: String)
}

class TeamSummaryViewController: TBATableViewController {

    private let teamKey: TeamKey
    private let event: Event

    weak var delegate: TeamSummaryViewControllerDelegate?

    var teamAwards: Set<Award> {
        guard let awards = event.awards else {
            return []
        }
        return awards.filtered(using: NSPredicate(format: "%K == %@ AND (ANY recipients.teamKey.key == %@)",
                                                  #keyPath(Award.event), event,
                                                  teamKey.key!)) as? Set<Award> ?? []
    }

    private var eventStatus: EventStatus? {
        didSet {
            if let eventStatus = eventStatus {
                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                }

                contextObserver.observeObject(object: eventStatus, state: .updated) { (_, _) in
                    DispatchQueue.main.async { [weak self] in
                        self?.tableView.reloadData()
                    }
                }
            } else {
                contextObserver.observeInsertions { [unowned self] (eventStatuses) in
                    self.eventStatus = eventStatuses.first
                }
            }
        }
    }

//    func matchForSection(section: Int) -> (String, Match?) {
//        var section = section
//        if eventStatus?.nextMatchKey == nil, section >= TeamSummarySections.nextMatch.rawValue {
//            section += 1
//        }
//    }

    var nextMatch: Match? {
        if let nextMatchKey = eventStatus?.nextMatchKey, let match = Match.forKey(nextMatchKey, in: persistentContainer.viewContext) {
            return match
        }
        return nil
    }

    var lastMatch: Match? {
        if let lastMatchKey = eventStatus?.lastMatchKey, let match = Match.forKey(lastMatchKey, in: persistentContainer.viewContext) {
            return match
        }
        return nil
    }

    fileprivate var summaryInfoRows: [TeamSummaryInfoRow] {
        var infoRows: [TeamSummaryInfoRow] = []

        // Rank
        if let rank = eventStatus?.qual?.ranking?.rank {
            infoRows.append(TeamSummaryInfoRow.rank(rank: rank.intValue))
        }

        // Awards
        if teamAwards.count > 0 {
            infoRows.append(TeamSummaryInfoRow.awards(count: teamAwards.count))
        }

        // TODO: Add support for Pits
        // https://github.com/the-blue-alliance/the-blue-alliance-ios/issues/163

        // Record
        if let record = eventStatus?.qual?.ranking?.record, event.year != 2015 {
            infoRows.append(TeamSummaryInfoRow.record(wlt: record))
        }

        // Alliance
        if let allianceStatus = eventStatus?.allianceStatus {
            infoRows.append(TeamSummaryInfoRow.alliance(allianceStatus: allianceStatus))
        }

        // Team Status
        if let overallStatus = eventStatus?.overallStatus {
            infoRows.append(TeamSummaryInfoRow.status(overallStatus: overallStatus))
        }

        // Breakdown
        if let tiebreakerInfo = eventStatus?.qual?.ranking?.tiebreakerInfoString {
            infoRows.append(TeamSummaryInfoRow.breakdown(tiebreakerInfo: tiebreakerInfo))
        }

        return infoRows
    }

    // MARK: - Observable

    typealias ManagedType = EventStatus
    lazy var contextObserver: CoreDataContextObserver<EventStatus> = {
        return CoreDataContextObserver(context: persistentContainer.viewContext)
    }()
    lazy var observerPredicate: NSPredicate = {
        return NSPredicate(format: "%K == %@ AND %K == %@",
                           #keyPath(EventStatus.event), event, #keyPath(EventStatus.teamKey), teamKey)
    }()

    private var backgroundFetchKeys: Set<String> = []

    init(teamKey: TeamKey, event: Event, persistentContainer: NSPersistentContainer, tbaKit: TBAKit, userDefaults: UserDefaults) {
        self.teamKey = teamKey
        self.event = event

        super.init(persistentContainer: persistentContainer, tbaKit: tbaKit, userDefaults: userDefaults)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Since we leverage didSet, we need to do this *after* initilization
        eventStatus = EventStatus.findOrFetch(in: persistentContainer.viewContext, matching: observerPredicate)

        tableView.registerReusableCell(ReverseSubtitleTableViewCell.self)
        tableView.registerReusableCell(LoadingTableViewCell.self)
        tableView.registerReusableCell(MatchTableViewCell.self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Only show next match/previous match if the event is currently being played
        guard event.isHappeningNow else {
            return 1
        }
        var sections = TeamSummarySections.allCases.count
        if eventStatus?.nextMatchKey == nil {
            sections = sections - 1
        }
        if eventStatus?.lastMatchKey == nil {
            sections = sections - 1
        }
        return sections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            let rows: Int = summaryInfoRows.count
            if rows == 0 {
                showNoDataView()
            } else {
                removeNoDataView()
            }
            return rows
        }
        return 1 // 1 cell for next/last match
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let row = summaryInfoRows[indexPath.row]
            let cell: UITableViewCell = {
                switch row {
                case .rank(let rank):
                    return self.tableView(tableView, cellForRank: rank, at: indexPath)
                case .awards(let count):
                    return self.tableView(tableView, cellForAwardCount: count, at: indexPath)
                case .record(let record):
                    return self.tableView(tableView, cellForRecord: record, at: indexPath)
                case .alliance(let allianceStatus):
                    return self.tableView(tableView, cellForAllianceStatus: allianceStatus, at: indexPath)
                case .status(let status):
                    return self.tableView(tableView, cellForStatus: status, at: indexPath)
                case .breakdown(let breakdown):
                    return self.tableView(tableView, cellForBreakdown: breakdown, at: indexPath)
                default:
                    return UITableViewCell()
                }
            }()
            return cell
        } else if indexPath.row == 1, let nexMatchKey = eventStatus?.nextMatchKey {
            if let match = nextMatch {
                return self.tableView(tableView, cellForMatch: match, at: indexPath)
            } else {
                return self.tableView(tableView, loadingCellForKey: nexMatchKey, at: indexPath)
            }
        } else if (indexPath.row == 2 || (indexPath.section == 1 && eventStatus?.nextMatchKey == nil)), let lastMatchKey = eventStatus?.lastMatchKey {
            if let match = lastMatch {
                return self.tableView(tableView, cellForMatch: match, at: indexPath)
            } else {
                return self.tableView(tableView, loadingCellForKey: lastMatchKey, at: indexPath)
            }
        } else {
            // fatalError("Unsupported team summary section")
            return UITableViewCell()
        }
    }

    private func tableView(_ tableView: UITableView, cellForRank rank: Int, at indexPath: IndexPath) -> UITableViewCell {
        return self.tableView(tableView, reverseSubtitleCellWithTitle: "Rank", subtitle: "\(rank)\(rank.suffix)", at: indexPath)
    }

    private func tableView(_ tableView: UITableView, cellForAwardCount awardCount: Int, at indexPath: IndexPath) -> UITableViewCell {
        let recordString = "Won \(awardCount) award\(awardCount > 1 ? "s" : "")"
        let cell = self.tableView(tableView, reverseSubtitleCellWithTitle: "Awards", subtitle: recordString, at: indexPath)
        // Allow us to push to what awards the team won
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        return cell
    }

    private func tableView(_ tableView: UITableView, cellForRecord record: WLT, at indexPath: IndexPath) -> UITableViewCell {
        return self.tableView(tableView, reverseSubtitleCellWithTitle: "Qual Record", subtitle: record.displayString(), at: indexPath)
    }

    private func tableView(_ tableView: UITableView, cellForAllianceStatus allianceStatus: String, at indexPath: IndexPath) -> UITableViewCell {
        return self.tableView(tableView, reverseSubtitleCellWithTitle: "Alliance", subtitle: allianceStatus, at: indexPath)
    }

    private func tableView(_ tableView: UITableView, cellForStatus status: String, at indexPath: IndexPath) -> UITableViewCell {
        return self.tableView(tableView, reverseSubtitleCellWithTitle: "Team Status", subtitle: status, at: indexPath)
    }

    private func tableView(_ tableView: UITableView, cellForBreakdown breakdown: String, at indexPath: IndexPath) -> UITableViewCell {
        return self.tableView(tableView, reverseSubtitleCellWithTitle: "Ranking Breakdown", subtitle: breakdown, at: indexPath)
    }

    private func tableView(_ tableView: UITableView, reverseSubtitleCellWithTitle title: String, subtitle: String, at indexPath: IndexPath) -> ReverseSubtitleTableViewCell {
        let cell = tableView.dequeueReusableCell(indexPath: indexPath) as ReverseSubtitleTableViewCell
        cell.titleLabel.text = title
        cell.setHTMLSubtitle(text: subtitle)
        cell.accessoryType = .none
        cell.selectionStyle = .none
        return cell
    }

    private func tableView(_ tableView: UITableView, loadingCellForKey key: String, at indexPath: IndexPath) -> LoadingTableViewCell {
        let cell = tableView.dequeueReusableCell(indexPath: indexPath) as LoadingTableViewCell
        cell.keyLabel.text = key
        cell.backgroundFetchActivityIndicator.isHidden = false
        return cell
    }

    private func tableView(_ tableView: UITableView, cellForMatch match: Match, at indexPath: IndexPath) -> MatchTableViewCell {
        let cell = tableView.dequeueReusableCell(indexPath: indexPath) as MatchTableViewCell
        cell.viewModel = MatchViewModel(match: match, teamKey: teamKey)
        return cell
    }

    // MARK: - Table View Delegate

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == TeamSummarySections.nextMatch.rawValue {
            return "Next Match"
        } else if section == TeamSummarySections.lastMatch.rawValue {
            return "Most Recent Match"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let rowType = summaryInfoRows[indexPath.row]
            switch rowType {
            case .awards:
                delegate?.awardsSelected()
            default:
                break
            }
        } else if indexPath.section == 1 {
            // delegate?.matchSelected(match)
        } else if indexPath.section == 2 {
            // delegate?.matchSelected(match)
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return UITableView.automaticDimension
        } else {
            return 44.0
        }
    }

}

extension TeamSummaryViewController: Refreshable {

    var refreshKey: String? {
        return "\(teamKey.key!)@\(event.key!)_status"
    }

    var automaticRefreshInterval: DateComponents? {
        return DateComponents(hour: 1)
    }

    var automaticRefreshEndDate: Date? {
        // Automatically refresh team summary until the event is over
        return event.endDate?.endOfDay()
    }

    var isDataSourceEmpty: Bool {
        return eventStatus == nil || teamAwards.count == 0
    }

    @objc func refresh() {
        removeNoDataView()

        // Refresh team status
        var teamStatusRequest: URLSessionDataTask?
        teamStatusRequest = tbaKit.fetchTeamStatus(key: teamKey.key!, eventKey: event.key!, completion: { (status, error) in
            let context = self.persistentContainer.newBackgroundContext()
            context.performChangesAndWait({
                // TODO: We can never remove an Status
                if let status = status {
                    let event = context.object(with: self.event.objectID) as! Event
                    event.insert(status)
                }
            }, saved: {
                self.markTBARefreshSuccessful(self.tbaKit, request: teamStatusRequest!)
            })
            self.removeRequest(request: teamStatusRequest!)
        })
        addRequest(request: teamStatusRequest!)

        // Refresh awards
        var awardsRequest: URLSessionDataTask?
        awardsRequest = tbaKit.fetchTeamAwards(key: teamKey.key!, eventKey: event.key!, completion: { (awards, error) in
            let context = self.persistentContainer.newBackgroundContext()
            context.performChangesAndWait({
                if let awards = awards {
                    let event = context.object(with: self.event.objectID) as! Event
                    event.insert(awards, teamKey: self.teamKey.key!)
                }
            }, saved: {
                self.markTBARefreshSuccessful(self.tbaKit, request: awardsRequest!)
            })
            self.removeRequest(request: awardsRequest!)
        })
        addRequest(request: awardsRequest!)
    }

    func fetchMatch(_ key: String) {
        // Already fetching match key
        guard !backgroundFetchKeys.contains(key) else {
            return
        }

        var request: URLSessionDataTask?
        request = tbaKit.fetchMatch(key: key) { (match, error) in
            let context = self.persistentContainer.newBackgroundContext()
            context.performChangesAndWait({
                if let match = match {
                    Match.insert(match, in: context)
                }
            }, saved: {
                self.tbaKit.setLastModified(request!)
            })

            self.backgroundFetchKeys.remove(key)

            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
        backgroundFetchKeys.insert(key)
    }

}

extension TeamSummaryViewController: Stateful {

    var noDataText: String {
        return "No status for team at event"
    }

}
