//
//  FWGamesTableViewController.h
//  Farewell
//
//  Created by Zook Gek on 5/24/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FWMainScreenViewController.h"
#import "FWGameScreenViewController.h"

@interface FWGamesTableViewController : UITableViewController

@property (weak, nonatomic) FWMainScreenViewController *mainVC;
@property (weak, nonatomic) FWGameScreenViewController *gameVC;

@end
