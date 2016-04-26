//
//  EventTeamViewController.h
//  the-blue-alliance
//
//  Created by Zach Orr on 4/25/16.
//  Copyright © 2016 The Blue Alliance. All rights reserved.
//

#import "TBAViewController.h"

@class Event, Team;

@interface EventTeamViewController : TBAViewController

@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) Team *team;

@end
