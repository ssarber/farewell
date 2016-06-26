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

// Status label
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *statusLabelTop;

@property (weak, nonatomic) IBOutlet UILabel *characterCountLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *characterCountLabelTop;

@property (weak, nonatomic) IBOutlet UITextField *textInputField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textInputFieldBottom;

@end

@implementation FWGameScreenViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textInputField.delegate = self;
    self.textInputField.enablesReturnKeyAutomatically = YES;
    
//    Might activate the keyboard on load
//    [self.textInputField becomeFirstResponder];
    
    self.headerView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.headerView.layer.shadowOffset = CGSizeMake(0.0, 5);
    self.headerView.layer.shadowRadius = 6;
    self.headerView.layer.shadowOpacity = 0.5;    
    self.headerView.layer.masksToBounds = NO;
    
    
    self.mainTextField.layer.borderWidth = 0.2;
    self.mainTextField.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    self.characterCountLabel.hidden = NO;
    self.characterCountLabel.text = @"2 sentences remaining.";
    
    [self.statusLabel sizeToFit];
    
    self.textInputField.autocorrectionType = UITextAutocorrectionTypeNo;
    [self.textInputField becomeFirstResponder];
       
    // Watch the keyboard frame..
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
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
    [self.textInputField resignFirstResponder];
    
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
//    [currentMatch setLocalizableMessageWithKey:@"Yo, it's your turn to add 2 sentences!"
//                                     arguments:nil];
    
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
//    NSLog(@"DIS MTCH status: %ld", (long)self.match.status);
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
    
    UIAlertAction* shareAction = [UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *action) {
                                                             [self shareEmail];
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
        [alert addAction:shareAction];
        [alert addAction:removeAction];
    } else {
        [alert addAction:quitAction];
    }
    [alert addAction:cancelAction];
    
    alert.view.tintColor = [UIColor redColor];
    
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

- (void)shareEmail
{
    UIActivityViewController *uiActivityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.mainTextField.text] applicationActivities:nil];
    [self presentViewController:uiActivityVC animated:YES completion:nil];
}
- (void)quitGame
{
    // If quitting a game where it's our turn
    if ([self.match.currentParticipant.player.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
        
        [[FWGameCenterHelper sharedInstance] player:self.match.currentParticipant.player wantsToQuitMatch:self.match];
        
    } else {
        
        // Resigns the player from the match when that player is not the current player.
        // This action does not end the match if there are more than two players remaining.
        // But since only two players are currently supported, it will end the match.
        [self.match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeTied withCompletionHandler:^(NSError *error) {
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
    // Enable editing of text input textfield if user hasn't typed
    // two sentences or else user taps "backspace". Otherwise disaable the textfield.
    
    // Ugh, this ugly code detects the backspace: http://lifesforlearning.com/detect-backspace-on-ios-textfield/
    const char * _char = [string cStringUsingEncoding:NSUTF8StringEncoding];
    int isBackSpace = strcmp(_char, "\b");
    if (isBackSpace == -8 || [self shouldAllowToContinueWriting] == YES) {
        return YES;
    } else {
        return NO;
    }
}


// Breaks up entered text into sentences. Updates sentence-counting label.
// Retuns NO when 2 sentences are detected so that further editing is disabled.
- (BOOL)shouldAllowToContinueWriting
{
    NSInteger len = [_textInputField.text length];
    
    NSCharacterSet *separators = [NSCharacterSet alphanumericCharacterSet];
    NSArray *words = [self.textInputField.text componentsSeparatedByCharactersInSet:separators];
    
    NSLog(@"WORDS: %@", words);
    
    NSIndexSet *separatorIndexes = [words indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
//        NSString *dotQuoteString = @"." stringByAppendingString:"
        return ([obj isEqualToString:@". "] || [obj isEqualToString:@"."] || [obj isEqualToString:@"! "] || [obj isEqualToString:@"!"] ||
                [obj isEqualToString:@"Free at last\"."]);
    }];
    
    NSLog(@"INDEXES COUNT: %lu", (unsigned long)[separatorIndexes count]);
    
    if ([separatorIndexes count] == 1) {
        _characterCountLabel.text = @"1 sentence remaining.";
    }
    
    if ([separatorIndexes count] == 2) {
        _characterCountLabel.text = @"0 sentences remaining.";
        return NO;
    }
//FIXME: hack for video recording. Fix!!
    if ([_textInputField.text hasSuffix:@"\"."]) {
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


#pragma mark - Keyboard

// TODO: make this right, as demonstrated by commented-out code below
- (void)keyboardFrameWillChange:(NSNotification *)notification
{
    CGRect keyboardEndFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardBeginFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    UIViewAnimationCurve animationCurve = [[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    NSTimeInterval animationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] integerValue];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect newFrame = self.view.frame;
    CGRect keyboardFrameEnd = [self.view convertRect:keyboardEndFrame toView:nil];
    CGRect keyboardFrameBegin = [self.view convertRect:keyboardBeginFrame toView:nil];
    
//    newFrame.origin.y -= (keyboardFrameBegin.origin.y - keyboardFrameEnd.origin.y);
//    self.view.frame = newFrame;
    
    [UIView commitAnimations];
}


//// See this link for a good summary of keyboard avoiding. With the ios8 keyboard gadgets
//// you can't hardcode sizes anymore.
//// http://stackoverflow.com/questions/26213681/ios-8-keyboard-hides-my-textview/26226732#26226732
//- (void)keyboardFrameWillChange: (NSNotification*)notif
//{
//    CGRect keyboardEndFrame = [[[notif userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
//    UIViewAnimationCurve animationCurve = (UIViewAnimationCurve)[[[notif userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
//    NSTimeInterval animationDuration = [[[notif userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
//    
//    if (_origLoginButtonBottom==0.0) {
//        _origLoginButtonBottom = _loginButton.frame.origin.y + _loginButton.frame.size.height + 8.0;
//    }
//    
//    CGFloat offsetNeeded = (_origLoginButtonBottom - keyboardEndFrame.origin.y);
//    if (offsetNeeded < 0.0) {
//        offsetNeeded = 0.0;
//    }
//    
//    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationDuration:animationDuration];
//    [UIView setAnimationCurve:animationCurve];
//    
//    _logoTop.constant = _logoTopBase - offsetNeeded;
//    
//    _glowTop.constant = -(offsetNeeded * 2.0);
//    _glowBottom.constant = (offsetNeeded * 2.0);
//    
//    
//    [self.view layoutIfNeeded];
//    [UIView commitAnimations];
//}

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
            
                NSLog(@"gameTextSoFar: %@", gameTextSoFar);
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
    
    NSLog(@"COMPLETED MATCH: %@", match);
    
    self.textInputField.hidden = YES;

    NSString *statusString;
    
    if (match.status == GKTurnBasedMatchStatusEnded) {
        
        NSLog(@"Match ended: %@", match.description);
        statusString = @"One of the writers marked this email complete. If you think it's any good, share it by tapping the \"...\" above.* \
            \n\n* Fine print: If you send it to your boss, fullfilling career and happiness may result.";
        self.characterCountLabel.hidden = YES;
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
