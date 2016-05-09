//
//  FWTurnBasedMatch.m
//  Farewell
//
//  Created by Zook Gek on 5/3/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWTurnBasedMatch.h"

@implementation FWTurnBasedMatch

#pragma mark Initialization

+ (FWTurnBasedMatch *)sharedInstance
{
    static FWTurnBasedMatch *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    
    return sharedInstance;
}


- (void)authenticateLocalUserFromController:(UIViewController *)authenticationPresentingVC
{
    self.presentingViewController = authenticationPresentingVC;
    
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    __weak GKLocalPlayer *weakLocalPlayer = localPlayer;
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
        if (viewController) {
            [authenticationPresentingVC presentViewController:viewController animated:YES completion:^{
                _userAuthenticated = YES;
                [weakLocalPlayer unregisterAllListeners];
                [weakLocalPlayer registerListener:self];
                
            }];
            
        } else if (weakLocalPlayer.isAuthenticated) {
            _userAuthenticated  = YES;
            [weakLocalPlayer unregisterAllListeners];
            [weakLocalPlayer registerListener:self];
            
        } else {
            _userAuthenticated = NO;
            NSLog(@"Error authenticating local user: %@", error);
            
        }
        
    };
}


- (void)findMatchWithMinPlayers:(NSUInteger)minPlayers maxPlayers:(NSUInteger)maxPlayers viewController:(UIViewController *)viewController
{
    self.presentingViewController = viewController;
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = minPlayers;
    request.maxPlayers = maxPlayers;
    
    GKTurnBasedMatchmakerViewController *matchMakerVC = [[GKTurnBasedMatchmakerViewController alloc] initWithMatchRequest:request];
    matchMakerVC.turnBasedMatchmakerDelegate = self;
    matchMakerVC.showExistingMatches = YES;
    
    [self.presentingViewController presentViewController:matchMakerVC animated:YES completion:nil];
}


- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFindMatch:(GKTurnBasedMatch *)match
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    self.currentMatch = match;
    
    GKTurnBasedParticipant *firstParticipant = [match.participants objectAtIndex:0];
    
    // If the first participant doesn't have lastTurnDate set yet, it should be
    // safe to assume we have a brand new match
    if (firstParticipant.lastTurnDate) {
        if ([match.currentParticipant.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
            [self.delegate takeTurnInGame:match];
        } else {
            [self.delegate layoutMatch:match];
        }
    } else {
        [self.delegate enterNewGame:match];
    }
}


- (void)turnBasedMatchmakerViewControllerWasCancelled:(GKTurnBasedMatchmakerViewController *)viewController
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{ 
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController playerQuitForMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"Aww, player %@ quit from match %@", match.currentParticipant, match);
    
    NSUInteger currentIndex = [match.participants indexOfObject:match.currentParticipant];
    
    GKTurnBasedParticipant *participant;
    
    NSMutableArray *nextParticipants = [NSMutableArray array];
    for (participant in match.participants) {
        NSUInteger index = [match.participants indexOfObject:participant];
        participant = [match.participants objectAtIndex:(currentIndex + 1 + index) % match.participants.count];
        
        if (participant.matchOutcome == GKTurnBasedMatchOutcomeNone) {
            [nextParticipants addObject:participant];
        }
    }
    
    [match loadMatchDataWithCompletionHandler:^(NSData *matchData, NSError *error) {
        [match participantQuitInTurnWithOutcome:GKTurnBasedMatchOutcomeQuit
                               nextParticipants:nextParticipants turnTimeout:600
                                      matchData:matchData completionHandler:nil];
    }];
    
    NSLog(@"Player quit form match");
    
}

@end
