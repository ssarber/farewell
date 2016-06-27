//
//  FWGamesTableViewController.h
//  Farewell
//
//  Created by Zook Gek on 5/24/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FWGameScreenViewController.h"

@interface FWGamesTableViewController : UIViewController

- (void)layoutMatch:(GKTurnBasedMatch *)match;
- (void)receiveEndGame:(GKTurnBasedMatch *)match;

@end
