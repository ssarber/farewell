//
//  ViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/3/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "ViewController.h"
#import "FWTurnBasedMatch.h"

@interface ViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *mainTextView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[FWTurnBasedMatch sharedInstance] authenticateLocalUserFromController:self];
    [FWTurnBasedMatch sharedInstance].delegate = self;
}


- (IBAction)presentGCTurnViewController:(id)sender
{
    [[FWTurnBasedMatch sharedInstance] findMatchWithMinPlayers:2 maxPlayers:4 viewController:self];
    
}



@end
