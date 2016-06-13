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

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITextView *mainTextField;
@property (weak, nonatomic) IBOutlet UITextField *textInputField;
@property (weak, nonatomic) IBOutlet UILabel *characterCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@end

@implementation FWGameScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textInputField.delegate = self;
    self.textInputField.enablesReturnKeyAutomatically = YES;
    
//    Might activate the keyboard on load
//    [self.textInputField becomeFirstResponder];
    
    
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:_headerView.bounds];
    _headerView.layer.masksToBounds = NO;
    _headerView.layer.shadowColor = [UIColor blackColor].CGColor;
    _headerView.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    _headerView.layer.shadowOpacity = 0.3f;
    _headerView.layer.shadowPath = shadowPath.CGPath;
    
    self.characterCountLabel.hidden = NO;
    self.characterCountLabel.text = @"2 sentences remaining.";
    
    [self.statusLabel sizeToFit];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}


- (BOOL)isPresented
{
    return [self isViewLoaded] && self.view.window;
}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (IBAction)backButtonPressed:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    
    // Reset the current match if we go back to main screen
    [FWGameCenterHelper sharedInstance].currentMatch = nil;
    
    // Reload the table view just in case?
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StateOfMatchesHasChangedNotification" object:self];
}


- (void)doneButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)presentGCTurnViewController:(id)sender
{
    [[FWGameCenterHelper sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 showExistingMatches:YES viewController:self];
    
}


- (IBAction)presentGCViewControllerForNewGame:(id)sender
{
    [[FWGameCenterHelper sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 showExistingMatches:NO viewController:self];
    
}


- (IBAction)sendTurn:(id)sender
{
    GKTurnBasedMatch *currentMatch = [[FWGameCenterHelper sharedInstance] currentMatch];
    
    NSString *newGameString;
    //newGameString = [self.textInputField.text length] > 140? [self.textInputField.text substringToIndex:139] : self.textInputField.text;
    
    newGameString = self.textInputField.text;
 
    NSString *sendString = [@[self.mainTextField.text, newGameString] componentsJoinedByString:@" "];
    
    NSData *data = [sendString dataUsingEncoding:NSUTF8StringEncoding];
    
    self.mainTextField.text = sendString;

    NSUInteger currentIndex = [currentMatch.participants indexOfObject:currentMatch.currentParticipant];
    NSMutableArray *nextParticipants = [NSMutableArray array];
    for (NSInteger i = 0; i < [currentMatch.participants count]; i++) {
        NSInteger indx = (i + currentIndex + 1) % [currentMatch.participants count];
        GKTurnBasedParticipant *participant = [currentMatch.participants objectAtIndex:indx];
        
        if (participant.matchOutcome == GKTurnBasedMatchOutcomeNone) {
            [nextParticipants addObject:participant];
        }
        
    }
    [currentMatch setLocalizableMessageWithKey:@"Yo, it's your turn to add 2 sentences!"
                                     arguments:nil];
    
    [currentMatch endTurnWithNextParticipants:nextParticipants turnTimeout:GKTurnTimeoutDefault
                                    matchData:data completionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Got error: %@", error);
            
            self.statusLabel.text = @"Oops, something went wrong. Try that again.";
        } else {
            self.statusLabel.text = @"Nice. Your turn is over for now. Let's wait for your co-writer to take turn.";
        }
    }];
        
    self.statusLabel.hidden = NO;
    
    self.textInputField.text = @"";
    self.textInputField.hidden = YES;

    self.characterCountLabel.text = @"2 sentences remaining.";
    self.characterCountLabel.hidden = YES;
    
    [self.view setNeedsDisplay];
    
    NSLog(@"Send Turn, %@, %@", data, nextParticipants);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StateOfMatchesHasChangedNotification" object:self];
}


- (IBAction)menuButtonPressed:(id)sender
{
    NSLog(@"DIS MTCH status: %ld", (long)self.match.status);
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    //FIXME: For iPad... Doesn't work?
    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect = self.view.bounds;
    
    UIAlertAction* quitAction = [UIAlertAction actionWithTitle:@"Complete Email" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self confirmQuit];
                                                          }];
    
    UIAlertAction* removeAction = [UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self confirmRemoval];
                                                         }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [alert dismissViewControllerAnimated:YES completion:nil];
                                                         }];
    
    if (self.match.status == GKTurnBasedMatchStatusEnded) {
        [alert addAction:removeAction];
    } else {
        [alert addAction:quitAction];
    }
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)confirmQuit
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Are you sure?"
                                                                    message:@"It's OK; don't let self-doubt interfere with your plans to improve your life."
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:@"Complete" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action) {
                                                           [self quitGame];
                                                       }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Um, not yet" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [alert dismissViewControllerAnimated:YES completion:nil];
                                                         }];
    [alert addAction:confirmAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)quitGame
{
    // If quitting a game where it's our turn
    if ([self.match.currentParticipant.player.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
        [[FWGameCenterHelper sharedInstance] player:self.match.currentParticipant.player wantsToQuitMatch:self.match];
    } else {
        
        // Resigns the player from the match when that player is not the current player. This action does not end the match
        [self.match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeQuit withCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Error quitting game: %@", error.localizedDescription);
                
#warning Remove before shipping
                
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error completing email:"
                                                                               message:error.localizedDescription
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                [self presentViewController:alert animated:YES completion:nil];

            }
        }];
    }
    
    // Reload the table view
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StateOfMatchesHasChangedNotification" object:self];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)confirmRemoval
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Remove this email forever?"
                                                                   message:@"It will also disappear from all your co-workers' and your boss's computers. Nice!"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self removeFinishedGame];
                                                          }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Um, not yet" style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [alert dismissViewControllerAnimated:YES completion:nil];
                                                         }];
    [alert addAction:confirmAction];
    [alert addAction:cancelAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)removeFinishedGame
{
    [self.match removeWithCompletionHandler:^(NSError *error) {
        NSLog(@"Removed match: %@", self.match);
        
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    // Reload the table view
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StateOfMatchesHasChangedNotification" object:self];
}


#pragma mark - UITextFieldDelegate Protocol methods

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([self updateCounterLabel]) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)updateCounterLabel
{
    NSInteger len = [_textInputField.text length];
    NSLog(@"LEEEEEEN: %ld", (long)len);
    
    
    NSCharacterSet *separators = [NSCharacterSet alphanumericCharacterSet];
    NSArray *words = [self.textInputField.text componentsSeparatedByCharactersInSet:separators];
    
    NSLog(@"WORDS: %@", words);
    
    NSIndexSet *separatorIndexes = [words indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ([obj isEqualToString:@". "] || [obj isEqualToString:@"."] || [obj isEqualToString:@"! "] || [obj isEqualToString:@"!"]);
    }];
    
    NSLog(@"INDEXES COUNT: %lu", (unsigned long)[separatorIndexes count]);
    
    if ([separatorIndexes count] == 1) {
            _characterCountLabel.text = @"1 sentence remaining.";
    }
    
    if ([separatorIndexes count] == 2) {
        _characterCountLabel.text = @"0 sentences remaining.";
        return NO;
    }
    
    return YES;
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

# pragma mark - FWTurnBasedMatchDelegate protocol methods

- (void)enterNewGameForMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"Inside FWGameScreenViewController --> enterNewGame");
    self.mainTextField.text = @"Dear coworkers,\n\n";
    
    NSString *statusString = [NSString stringWithFormat:@"Go shorty, it's your turn."];
    self.statusLabel.text = statusString;
    
    self.textInputField.hidden = NO;
    self.textInputField.enabled = YES;
    
    self.characterCountLabel.hidden = NO;
    self.characterCountLabel.text = @"2 sentences remaining.";
    
    [self.view setNeedsDisplay];
}


- (void)takeTurnInMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"Viewing a match where it is our turn...");
    NSLog(@"%@", NSStringFromSelector(_cmd));
    NSLog(@"SELF: %@", self);
    NSLog(@"TEXT FIELD: %@", self.mainTextField);
    
    NSString *statusString = [NSString stringWithFormat:@"Go shorty, it's your turn."];
    
    self.statusLabel.text = statusString;
    self.textInputField.hidden = NO;
    self.textInputField.enabled = YES;
    
    self.characterCountLabel.hidden = NO;
    self.characterCountLabel.text = @"2 sentences remaining.";
    
    __weak typeof(self) weakSelf = self;

    [match loadMatchDataWithCompletionHandler:^(NSData *matchData, NSError *error) {
        if ([matchData bytes]) {
            NSString *gameTextSoFar = [NSString stringWithUTF8String:[matchData bytes]];
            
            // Update the UI on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.mainTextField.text = gameTextSoFar;
            });
        } else {
            weakSelf.mainTextField.text = @"Dear co-workers,\n\n";
        }
    }];
    
    [self.view setNeedsDisplay];
}


- (void)layoutCurrentMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"Viewing a match where it's not our turn...");
    
    self.textInputField.hidden = YES;

    NSString *statusString;
    
    if (match.status == GKTurnBasedMatchStatusEnded) {
        
        NSLog(@"Match ended: %@", match.description);
        statusString = @"Match ended.";
    } else {
        NSString *playerName = match.currentParticipant.player.displayName;
        NSUInteger playerNum = [match.participants indexOfObject:match.currentParticipant] + 1;
        statusString = playerName? [NSString stringWithFormat:@"%@'s turn.", playerName] :
            [NSString stringWithFormat: @"Player %ld's turn.", playerNum];
    }
    
    self.statusLabel.text = statusString;
    self.textInputField.enabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [match loadMatchDataWithCompletionHandler:^(NSData *matchData, NSError *error) {
        if (matchData != nil) {
            NSString *gameTextSoFar = [NSString stringWithUTF8String:[matchData bytes]];
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.mainTextField.text = gameTextSoFar;
            });
        }
    }];
}


- (void)receiveEndGame:(GKTurnBasedMatch *)match
{
    [self layoutCurrentMatch:match];
}

@end
