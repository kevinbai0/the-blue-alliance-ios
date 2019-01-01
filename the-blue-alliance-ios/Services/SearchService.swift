import CoreData
import CoreSpotlight
import Crashlytics
import Foundation

/**
 SearchSerivce manages background fetching of search objects (ex: Event, Team, etc.) as well as implementing any
 NSCoreDataCoreSpotlightDelegate/Core Spotlight methods that need to be implemented to surface Core Data objects in
 our Core Spotlight search.

 This is like - by far, the most complicated part of this system
 It's worth evaluating if we could do this via a CSIndexExtensionRequestHandler
 It would require us to do batching and stuff manually, but that seems fine? I don't think Core Data
 gives us the hooks we want regarding indexing and whatnot. Also - background updates have to happen that way I think.
 */
class SearchService {

    // TODO: HEAD for each page?
    private func fetchTeams() {

    }

    private func fetchEvents() {

    }

    func addToSearchIndex(_ items: [Searchable]) {
        guard CSSearchableIndex.isIndexingAvailable() else { return }

        // These things will expire after a month... how do we make sure they don't? Or that they stay fresh?
        let searchableItems = items.map({ (item) -> CSSearchableItem in
            let attributes = item.searchAttributes
            attributes.contentURL = item.webURL
            attributes.relatedUniqueIdentifier = item.searchKey
            return CSSearchableItem(uniqueIdentifier: item.searchKey, domainIdentifier: nil, attributeSet: attributes)
        })
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { (error) in
            if let error = error {
                Crashlytics.sharedInstance().recordError(error)
            }
        }
    }

    func removeFromSearchIndex(_ item: Searchable) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [item.searchKey], completionHandler: nil)
    }

}

// CSSearchableIndexDelegate
