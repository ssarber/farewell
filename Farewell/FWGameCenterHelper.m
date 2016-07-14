//
//  FWTurnBasedMatch.m
//  Farewell
//
//  Created by Zook Gek on 5/3/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWGameCenterHelper.h"

@implementation FWGameCenterHelper

#pragma mark Initialization

+ (FWGameCenterHelper *)sharedInstance
{
    static FWGameCenterHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    
    return sharedInstance;
}


- (void)authenticateLocalUserFromController:(UIViewController *)authenticationPresentingVC
{
    self.presentingVC = authenticationPresentingVC;
    
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    __weak GKLocalPlayer *weakLocalPlayer = localPlayer;
    localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
        if (viewController != nil) {
            [authenticationPresentingVC presentViewController:viewController animated:YES completion:^{
                _userAuthenticated = YES;
                [weakLocalPlayer unregisterAllListeners];
                [weakLocalPlayer registerListener:self];
                
            }];
            
        } else if (weakLocalPlayer.isAuthenticated) {
            _userAuthenticated  = YES;
            [weakLocalPlayer unregisterAllListeners];
            [weakLocalPlayer registerListener:self];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UnblockUI" object:self];
            
        } else {
            _userAuthenticated = NO;
            NSLog(@"Error authenticating local user: %@", error);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BlockUI" object:self];
            
        }
        
    };
}


- (void)findMatchWithMinPlayers:(NSUInteger)minPlayers maxPlayers:(NSUInteger)maxPlayers showExistingMatches:(BOOL)show viewController:(UIViewController *)viewController
{
    self.presentingVC = viewController;
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = minPlayers;
    request.maxPlayers = maxPlayers;
    
    GKTurnBasedMatchmakerViewController *matchMakerVC = [[GKTurnBasedMatchmakerViewController alloc] initWithMatchRequest:request];
    matchMakerVC.turnBasedMatchmakerDelegate = self;
    matchMakerVC.showExistingMatches = show? YES : NO;
    
    [self.presentingVC presentViewController:matchMakerVC animated:YES completion:nil];
}

#pragma mark - GKTurnBasedMatchmakerViewControllerDelegate methods

- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFindMatch:(GKTurnBasedMatch *)match
{
    [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
    
        self.currentMatch = match;
    
        GKTurnBasedParticipant *firstParticipant = [match.participants objectAtIndex:0];
    
        // If the first participant doesn't have lastTurnDate set yet, it should be
        // safe to assume we have a brand new match
        if (firstParticipant.lastTurnDate) {
    
            if ([match.currentParticipant.player.playerID isEqual:[GKLocalPlayer localPlayer].playerID]) {
                // It's our turn to take a turn
                [self.delegate takeTurnInGame:match];
            } else {
                [self.delegate layoutMatch:match];
            }
        } else {
            _newMatch = YES;
    
            // We're in a new game
            [self.delegate enterNewGame:match];
        }

}

- (void)loadAMatch:(GKTurnBasedMatch *)match;
{
    
    NSLog(@"did find match");
    
    [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
    
    NSMutableArray *stillPlaying = [NSMutableArray array];
    
    for (GKTurnBasedParticipant *p in match.participants) {
        if (p.matchOutcome == GKTurnBasedMatchOutcomeNone) {
            [stillPlaying addObject:p];
        }
    }
    
    if ([stillPlaying count] < 2 && [match.participants count] >= 2) {
        // There's only one player left
        for (GKTurnBasedParticipant *part in stillPlaying) {
            part.matchOutcome = GKTurnBasedMatchOutcomeTied;
        }
        [match endMatchInTurnWithMatchData:match.matchData completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Error ending match (in GC helper: loadAMatch) %@", error);
            }
            [self.delegate layoutMatch:match];
        }];
        return;
    }
    
    self.currentMatch = match;
    
    GKTurnBasedParticipant *firstParticipant = [match.participants objectAtIndex:0];
    GKTurnBasedParticipant *secondParticipant = [match.participants objectAtIndex:1];
    
    // If the first participant doesn't have lastTurnDate set yet, it should be
    // safe to assume we have a brand new match
    if (firstParticipant.lastTurnDate) {
        if ([match.currentParticipant.player.playerID isEqual:[GKLocalPlayer localPlayer].playerID]) {
            // It's our turn to take a turn
            [self.delegate takeTurnInGame:match];
        } else {
            [self.delegate layoutMatch:match];
        }
        
    // We have a match, but this player has not taken a turn yet
    } else if (secondParticipant.status == GKTurnBasedParticipantStatusInvited || secondParticipant.status == GKTurnBasedParticipantStatusMatching) {
        
        [self.delegate takeTurnInGame:match];
        
    } else {
        // We're in a new game
        [self.delegate enterNewGame:match];
    }
}


- (void)turnBasedMatchmakerViewControllerWasCancelled:(GKTurnBasedMatchmakerViewController *)viewController
{
    [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
}


- (void)turnBasedMatchmakerViewController:(GKTurnBasedMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{ 
    [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
}


- (void)player:(GKPlayer *)player wantsToQuitMatch:(GKTurnBasedMatch *)match
{
    for (GKTurnBasedParticipant *participant in match.participants) {
        participant.matchOutcome = GKTurnBasedMatchOutcomeTied;
    }

    [match endMatchInTurnWithMatchData:match.matchData completionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Error ending match (in GC helper) wantsToQuitMatch: %@", error);
        }
    }];
    
    NSLog(@"Player quit from match.");
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

#pragma mark - GKTurnBasedEventListener methods

- (void)player:(GKPlayer *)player receivedTurnEventForMatch:(GKTurnBasedMatch *)match didBecomeActive:(BOOL)didBecomeActive
{
 
    if ([match.matchID isEqualToString:self.currentMatch.matchID]) {
        if ([match.currentParticipant.player.playerID isEqual:[GKLocalPlayer localPlayer].playerID]) {
            self.currentMatch = match;
            [self.delegate takeTurnInGame:match];
        } else {
            self.currentMatch = match;
            [self.delegate layoutMatch:match];
        }
    }
    
    // To refresh the table view
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StateOfMatchesHasChangedNotification" object:self];
}

- (void)player:(GKPlayer *)player matchEnded:(GKTurnBasedMatch *)match
{
    if ([match.matchID isEqualToString:self.currentMatch.matchID]) {
        [self.delegate receiveEndGame:match];
    } else {
        [self.delegate sendNotice:@"Another game ended!" forMatch:match];
    }
}

-(void)player:(GKPlayer *)player didRequestMatchWithOtherPlayers:(NSArray *)playersToInvite
{
    [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    
    request.recipients = playersToInvite;
    request.maxPlayers = 2;
    request.minPlayers = 2;
    
    GKTurnBasedMatchmakerViewController *matchMakerVC = [[GKTurnBasedMatchmakerViewController alloc] initWithMatchRequest:request];
    
    matchMakerVC.showExistingMatches = NO;
    
    matchMakerVC.turnBasedMatchmakerDelegate = self;
    
    [self.presentingVC presentViewController:matchMakerVC animated:YES completion:nil];
}



@end
