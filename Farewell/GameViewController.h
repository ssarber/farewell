//
//  ViewController.h
//  Farewell
//
//  Created by Zook Gek on 5/3/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FWTurnBasedMatch.h"

@interface GameViewController : UIViewController

-(void)takeTurnInGame:(GKTurnBasedMatch *)match;

@end

