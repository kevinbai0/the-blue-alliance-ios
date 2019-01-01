import Foundation
import CoreSpotlight

/**
 Identifies a Core Data class as being Searchable in-app and via Spotlight. Values are used by CoreSpotlight index and
 NSUserActivity to ensure that we don't duplicate search results.
 */
protocol Searchable {

    /// Identifier to use for this object - usually should be the `key` for a Core Data model
    var searchKey: String { get }

    /// Search attributes for this object
    var searchAttributes: CSSearchableItemAttributeSet { get }

    /// URL where we can access the object online - import to prevent duplication of search results from the web + local index
    var webURL: URL { get }

}
