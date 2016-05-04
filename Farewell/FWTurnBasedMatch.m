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
@end
