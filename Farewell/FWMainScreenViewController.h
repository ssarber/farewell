//
//  FWLandingScreenViewController.h
//  Farewell
//
//  Created by Zook Gek on 5/12/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FWTurnBasedMatch.h"

@interface FWMainScreenViewController : UIViewController

- (void)layoutMatch:(GKTurnBasedMatch *)match;

@end
