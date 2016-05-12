//
//  FWLandingScreenViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/12/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWLandingScreenViewController.h"
#import "FWTurnBasedMatch.h"
#import "GameViewController.h"

@interface FWLandingScreenViewController () <FWTurnBasedMatchDelegate>

@property (strong, nonatomic) GameViewController *gameVC;

@end

@implementation FWLandingScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[FWTurnBasedMatch sharedInstance] authenticateLocalUserFromController:self];
    
    [FWTurnBasedMatch sharedInstance].delegate = self;
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)presentGCViewControllerForNewGame:(id)sender
{
    [[FWTurnBasedMatch sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 showExistingMatches:NO viewController:self];
    
}

- (IBAction)presentGCTurnViewControllerForAllGames:(id)sender
{
    [[FWTurnBasedMatch sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 showExistingMatches:YES viewController:self];
    
}

# pragma mark - FWTurnBasedMatchDelegate protocol methods

- (void)enterNewGame:(GKTurnBasedMatch *)match
{
    NSLog(@"======== Entering new game ===========");
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    self.gameVC = [storyboard instantiateViewControllerWithIdentifier:@"GameViewControllerID"];
    [self.gameVC setModalPresentationStyle:UIModalPresentationFullScreen];
    [self presentViewController:self.gameVC animated:YES completion:nil];
}

-(void)takeTurnInGame:(GKTurnBasedMatch *)match
{
    [self.gameVC takeTurnInGame:match];
    
    NSLog(@"Taking turn in game");
}


//
//- (void)layoutMatch:(GKTurnBasedMatch *)match
//{
//    NSLog(@"Viewing match where it's not our turn...");
//    
//    self.textInputField.hidden = NO;
//    [self.loadGamesButton setTitle: @"All Games" forState:UIControlStateNormal];
//    
//    NSString *statusString;
//    
//    if (match.status == GKTurnBasedMatchStatusEnded) {
//        statusString = @"Match ended.";
//    } else {
//        NSString *playerName = match.currentParticipant.player.displayName;
//        NSUInteger playerNum = [match.participants indexOfObject:match.currentParticipant] + 1;
//        statusString = playerName? [NSString stringWithFormat:@"%@'s turn", playerName] :
//        [NSString stringWithFormat: @"Player %ld's turn.", playerNum];
//    }
//    
//    self.statusLabel.text = statusString;
//    self.textInputField.enabled = NO;
//    
//    __weak typeof(self) weakSelf = self;
//    [match loadMatchDataWithCompletionHandler:^(NSData *matchData, NSError *error) {
//        if (matchData) {
//            NSString *gameTextSoFar = [NSString stringWithUTF8String:[matchData bytes]];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                weakSelf.mainTextView.text = gameTextSoFar;
//            });
//            
//            [self updateCharactersLeftCount:match.matchData];
//        }
//    }];
//}
//
//- (void)sendNotice:(NSString *)notice forMatch:(GKTurnBasedMatch *)match
//{
//    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Um, hello?"
//                                                                   message:@"Another email requires your immediate attention."
//                                                            preferredStyle:UIAlertControllerStyleAlert];
//    
//    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Oh, OK" style:UIAlertActionStyleDefault
//                                                          handler:^(UIAlertAction * action) {}];
//    
//    [alert addAction:defaultAction];
//    [self presentViewController:alert animated:YES completion:nil];
//}
//
//- (void)receiveEndGame:(GKTurnBasedMatch *)match
//{
//    [self layoutMatch:match];
//}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
