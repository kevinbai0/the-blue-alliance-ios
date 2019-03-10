import Foundation
import CoreData

extension EventRankingStat: Managed {

    static func insert(value: NSNumber, in context: NSManagedObjectContext) -> EventRankingStat {
        let eventRankingStat = EventRankingStat.init(entity: entity(), insertInto: context)
        eventRankingStat.value = value
        return eventRankingStat
    }

    var isOrphaned: Bool {
        return sortOrderRanking == nil && extraStatsRanking == nil
    }

    public override func willSave() {
        super.willSave()

        // Do some additional validation, since we can't do an either-or sort of validation in Core Data
        if sortOrderRanking != nil, extraStatsRanking != nil {
            fatalError("EventRankingStat must not have a relationship to both an extraStat and sortOrder")
        }
    }

}
