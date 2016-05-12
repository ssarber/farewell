//
//  ViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/3/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "ViewController.h"
#import "FWTurnBasedMatch.h"

NSUInteger const kMaxAllowedCharacters = 100;

@interface ViewController () <UITextViewDelegate, UITextFieldDelegate, FWTurnBasedMatchDelegate>

@property (weak, nonatomic) IBOutlet UITextView *mainTextView;
@property (weak, nonatomic) IBOutlet UITextField *textInputField;
@property (weak, nonatomic) IBOutlet UILabel *characterCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *loadGamesButton;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[FWTurnBasedMatch sharedInstance] authenticateLocalUserFromController:self];
    
    [self.textInputField setReturnKeyType:UIReturnKeyDone];
    
    self.textInputField.hidden = YES;
    self.textInputField.delegate = self;
    
    [self.loadGamesButton setTitle:@"Begin" forState:UIControlStateNormal];
    
    self.characterCountLabel.hidden = YES;
    
    self.statusLabel.text = @"Welcome. Press Begin to get started";
    
    [FWTurnBasedMatch sharedInstance].delegate = self;
}

- (IBAction)presentGCTurnViewController:(id)sender
{
    [[FWTurnBasedMatch sharedInstance] findMatchWithMinPlayers:2 maxPlayers:4 viewController:self];
    
}

- (IBAction)sendTurn:(id)sender
{
    GKTurnBasedMatch *currentMatch = [[FWTurnBasedMatch sharedInstance] currentMatch];
    
    NSString *newGameString;
    newGameString = [self.textInputField.text length] > 140? [self.textInputField.text substringToIndex:139] : self.textInputField.text;
    
    NSString *sendString = [self.mainTextView.text stringByAppendingString:newGameString];
    
    NSData *data = [sendString dataUsingEncoding:NSUTF8StringEncoding];
    
    self.mainTextView.text = sendString;

    NSUInteger currentIndex = [currentMatch.participants indexOfObject:currentMatch.currentParticipant];
    NSMutableArray *nextParticipants = [NSMutableArray array];
    for (NSInteger i = 0; i < [currentMatch.participants count]; i++) {
        NSInteger indx = (i + currentIndex + 1) % [currentMatch.participants count];
        GKTurnBasedParticipant *participant = [currentMatch.participants objectAtIndex:indx];
        
        if (participant.matchOutcome == GKTurnBasedMatchOutcomeNone) {
            [nextParticipants addObject:participant];
        }
        
    }
    
    if ([data length] > kMaxAllowedCharacters) {
        for (GKTurnBasedParticipant *participant in currentMatch.participants) {
            participant.matchOutcome = GKTurnBasedMatchOutcomeTied;
        }
        [currentMatch endMatchInTurnWithMatchData:data completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Um, got this error: %@", error);
            }
        }];
        self.statusLabel.text = @"Game Over.";
    } else {
        [currentMatch endTurnWithNextParticipants:nextParticipants turnTimeout:GKTurnTimeoutDefault matchData:data completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Got error: %@", error);
                
                self.statusLabel.text = @"Oops, something went wrong. Try that again.";
            } else {
                self.statusLabel.text = @"Your turn is over.";
                self.textInputField.enabled = NO;
            }
        }];
    }

    NSLog(@"Send Turn, %@, %@", data, nextParticipants);
    
    self.textInputField.text = @"";
    self.characterCountLabel.text = @"140";
    self.characterCountLabel.textColor = [UIColor blackColor];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.textInputField) {
        [textField resignFirstResponder];
        [self sendTurn:nil];
        return NO;
    }
    return YES;
}


- (void)updateCharactersLeftCount:(NSData *)matchData
{
    if ([matchData length]) {
        self.statusLabel.text = [NSString stringWithFormat:@"%@, %lu characters left.",
                                 self.statusLabel.text,  kMaxAllowedCharacters - [matchData length]];
    }
}

# pragma mark - FWTurnBasedMatchDelegate protocol methods

- (void)enterNewGame:(GKTurnBasedMatch *)match
{
    NSLog(@"Entering new game");
    self.mainTextView.text = @"Dear coworkers,\n";
}

-(void)takeTurnInGame:(GKTurnBasedMatch *)match
{
    [self.loadGamesButton setTitle: @"All Games" forState:UIControlStateNormal];
    
    NSString *statusString = [NSString stringWithFormat:@"Your turn."];
    
    self.statusLabel.text = statusString;
    self.textInputField.hidden = NO;
    self.textInputField.enabled = YES;
    
    __weak typeof(self) weakSelf = self;
    
    [match loadMatchDataWithCompletionHandler:^(NSData *matchData, NSError *error) {
        if ([matchData bytes]) {
            NSString *gameTextSoFar = [NSString stringWithUTF8String:[matchData bytes]];
            
            // Update the UI on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.mainTextView.text = gameTextSoFar;
            });
            
            [self updateCharactersLeftCount:match.matchData];
        }
    }];
}

- (void)layoutMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"Viewing match where it's not our turn...");
    
    self.textInputField.hidden = NO;
    [self.loadGamesButton setTitle: @"All Games" forState:UIControlStateNormal];
    
    NSString *statusString;
    
    if (match.status == GKTurnBasedMatchStatusEnded) {
        statusString = @"Match ended.";
    } else {
        NSString *playerName = match.currentParticipant.player.displayName;
        NSUInteger playerNum = [match.participants indexOfObject:match.currentParticipant] + 1;
        statusString = playerName? [NSString stringWithFormat:@"%@'s turn", playerName] :
            [NSString stringWithFormat: @"Player %ld's turn.", playerNum];
    }
    
    self.statusLabel.text = statusString;
    self.textInputField.enabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [match loadMatchDataWithCompletionHandler:^(NSData *matchData, NSError *error) {
        if (matchData) {
            NSString *gameTextSoFar = [NSString stringWithUTF8String:[matchData bytes]];
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.mainTextView.text = gameTextSoFar;
            });
            
            [self updateCharactersLeftCount:match.matchData];
        }
    }];
}

- (void)sendNotice:(NSString *)notice forMatch:(GKTurnBasedMatch *)match
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Um, hello?"
                                                                   message:@"Another email requires your immediate attention."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Oh, OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)receiveEndGame:(GKTurnBasedMatch *)match
{
    [self layoutMatch:match];
}

@end
