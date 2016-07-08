//
//  ViewController.h
//  Farewell
//
//  Created by Zook Gek on 5/3/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FWGameCenterHelper.h"

@interface FWGameScreenViewController : UIViewController

@property (strong, nonatomic) GKTurnBasedMatch *match;
@property (strong, nonatomic) NSString *prompt;

- (void)enterNewGameForMatch:(GKTurnBasedMatch *)match;
- (void)takeTurnInMatch:(GKTurnBasedMatch *)match;
- (void)layoutCurrentMatch:(GKTurnBasedMatch *)match;

- (BOOL)isPresented;

@end

