//
//  FWLandingScreenViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/12/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWMainScreenViewController.h"
#import "FWTurnBasedMatch.h"
#import "FWGameScreenViewController.h"
#import "FWGamesTableViewController.h"

@interface FWMainScreenViewController () <FWTurnBasedMatchDelegate>

@property (strong, nonatomic) FWGameScreenViewController *gameVC;

@end

@implementation FWMainScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[FWTurnBasedMatch sharedInstance] authenticateLocalUserFromController:self];
    
    [FWTurnBasedMatch sharedInstance].delegate = self;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    self.gameVC = [storyboard instantiateViewControllerWithIdentifier:@"FWGameScreenViewControllerID"];
}


- (BOOL)prefersStatusBarHidden
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
    
//    [self.navigationController pushViewController:self.gameVC animated:NO];
    
    [self.gameVC enterNewGame:match];
}


-(void)takeTurnInGame:(GKTurnBasedMatch *)match
{
    self.gameVC.match = match;
    
    if (!self.gameVC.isViewLoaded || !self.gameVC.view.window) {
        // viewController is visible
        [self presentViewController:self.gameVC animated:YES completion:nil];
    } else {
        [self.navigationController pushViewController:self.gameVC animated:YES];
    }
//
//    [self presentViewController:self.gameVC animated:YES completion:nil];
    
    [self.gameVC takeTurnInMatch:match];
}


- (void)layoutMatch:(GKTurnBasedMatch *)match
{
    self.gameVC.match = match;
    [self presentViewController:self.gameVC animated:YES completion:nil];
    
    [self.gameVC layoutCurrentMatch:match];
}

//-(void)loadAMatch:(GKTurnBasedMatch *)match {
//    [self.vc dismissViewControllerAnimated:YES completion:nil];
// [[GCTurnBasedMatchHelper sharedInstance] turnBasedMatchmakerViewController:nil didFindMatch:match];
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"PresentGamesTableViewController"]) {
        UINavigationController *nc = (UINavigationController *) segue.destinationViewController;
        
        FWGamesTableViewController *gamesTableVC = (FWGamesTableViewController *)nc.viewControllers[0];
        gamesTableVC.mainVC = self;
    }
}

@end
