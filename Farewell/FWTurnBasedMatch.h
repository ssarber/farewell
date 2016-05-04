//
//  FWTurnBasedMatch.h
//  Farewell
//
//  Created by Zook Gek on 5/3/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@interface FWTurnBasedMatch : NSObject <GKLocalPlayerListener>

@property (assign, nonatomic) BOOL userAuthenticated;

+ (FWTurnBasedMatch *)sharedInstance;

- (void)authenticateLocalUserFromController:(UIViewController *)controller;

@end
