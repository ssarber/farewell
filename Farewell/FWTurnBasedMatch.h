//
//  FWTurnBasedMatch.h
//  Farewell
//
//  Created by Zook Gek on 5/3/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@protocol TurnBasedMatchDelegate <NSObject>

@end

@interface FWTurnBasedMatch : NSObject <GKLocalPlayerListener, GKTurnBasedMatchmakerViewControllerDelegate>

@property (assign, nonatomic) BOOL userAuthenticated;

@property (strong, nonatomic) UIViewController *presentingViewController;

@property (nonatomic, weak) id <TurnBasedMatchDelegate> delegate;

+ (FWTurnBasedMatch *)sharedInstance;

- (void)authenticateLocalUserFromController:(UIViewController *)controller;

- (void)findMatchWithMinPlayers:(NSUInteger)minPlayers
                     maxPlayers:(NSUInteger)maxPlayers
                 viewController:(UIViewController *)viewController;

@end
