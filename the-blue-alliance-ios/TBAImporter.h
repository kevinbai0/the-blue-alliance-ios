//
//  DatabaseImporter.h
//  the-blue-alliance-ios
//
//  Created by Donald Pinckney on 5/23/14.
//  Copyright (c) 2014 The Blue Alliance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Event.h"

/** `TBAImporter` is a utility class used to encapsulate the various downloading
 * logic for importing data from TBA API.
 */
@interface TBAImporter : NSObject

/** Downloads a list of all the events from TBA and saves to Core Data as necesasry
 * 
 * @param context The context of the database used for importing
 */
+ (void)importEventsUsingManagedObjectContext:(NSManagedObjectContext *)context;

/** Downloads a list of all the teams from TBA and saves to Core Data as necesasry
 *
 * @param context The context of the database used for importing
 */
+ (void)importTeamsUsingManagedObjectContext:(NSManagedObjectContext *)context;

/** Downloads a list of all the teams for a specific event and associate
 *  them to the Event
 *
 * @param event The event to download teams for
 * @param context The context of the database used for importing
 */
+ (void)linkTeamsToEvent:(Event *)event usingManagedObjectContext:(NSManagedObjectContext *)context;

/** Downloads a list of rankings at an event and saves it on the event object
 *
 * @param event The event to download rankings for
 * @param context The context of the database used for importing
 * @param callback A block invoked with the rankings string once it has been downloaded
 */
+ (void)importRankingsForEvent:(Event *)event usingManagedObjectContext:(NSManagedObjectContext *)context callback:(void (^)(NSString *rankingsString))callback;

@end
