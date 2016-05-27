//
//  ViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/3/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWGameScreenViewController.h"

NSUInteger const kMaxAllowedCharacters = 100;

@interface FWGameScreenViewController () <UITextViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextView *mainTextView;
@property (weak, nonatomic) IBOutlet UITextField *textInputField;
@property (weak, nonatomic) IBOutlet UILabel *characterCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

@end

@implementation FWGameScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textInputField.delegate = self;
    self.textInputField.enablesReturnKeyAutomatically = YES;
    [self.textInputField becomeFirstResponder];
    
    self.characterCountLabel.hidden = YES;
    
    [self.statusLabel sizeToFit];
}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (IBAction)backButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)doneButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)presentGCTurnViewController:(id)sender
{
    [[FWTurnBasedMatch sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 showExistingMatches:YES viewController:self];
    
}


- (IBAction)presentGCViewControllerForNewGame:(id)sender
{
    [[FWTurnBasedMatch sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 showExistingMatches:NO viewController:self];
    
}


- (IBAction)sendTurn:(id)sender
{
    GKTurnBasedMatch *currentMatch = [[FWTurnBasedMatch sharedInstance] currentMatch];
    
    NSString *newGameString;
    newGameString = [self.textInputField.text length] > 140? [self.textInputField.text substringToIndex:139] : self.textInputField.text;
    
//    NSString *sendString = [self.mainTextView.text stringByAppendingString:newGameString];
//    
    NSString *sendString = [@[self.mainTextView.text, newGameString] componentsJoinedByString:@" "];
    
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
                self.statusLabel.text = @"Nice. Your turn is over for now. Let's wait for your co-writer to take turn.";
                self.textInputField.hidden = YES;
            }
        }];
    }

    NSLog(@"Send Turn, %@, %@", data, nextParticipants);
    
    self.textInputField.text = @"";
    self.characterCountLabel.text = @"140";
    self.characterCountLabel.textColor = [UIColor blackColor];
}


- (IBAction)menuButtonPressed:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* quitAction = [UIAlertAction actionWithTitle:@"Quit Game..." style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self quitGame];
    }];
    
    [alert addAction:quitAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)quitGame
{
    // If quitting a game where it's our turn
    if ([self.match.currentParticipant.player.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
        [[FWTurnBasedMatch sharedInstance] player:self.match.currentParticipant.player wantsToQuitMatch:self.match];
    } else {
        
        // Resigns the player from the match when that player is not the current player. This action does not end the match
        [self.match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeQuit withCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Error quitting game: %@", error.localizedDescription);
            }
        }];
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITextFieldDelegate Protocol methods

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

# pragma mark - Updating characters left counter

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
    NSLog(@"Inside FWGameScreenViewController -- enterNewGame:(GKTurnBasedMatch *)match");
    self.mainTextView.text = @"Dear coworkers,\n\n";
}


- (void)takeTurnInMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"Viewing a match where it is our turn...");
    
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


- (void)layoutCurrentMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"Viewing a match where it's not our turn...");
    
    self.textInputField.hidden = YES;

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
    [self layoutCurrentMatch:match];
}

@end
