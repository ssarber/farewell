//
//  ViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/3/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWGameScreenViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface FWGameScreenViewController () <UITextViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITextView *mainTextField;

// Status label
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *statusLabelTop;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *statusLabelBottom;

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
    
    //  Might activate the keyboard on load
    //  [self.textInputField becomeFirstResponder];
    
    self.mainTextField.layer.borderWidth = 0.5;
    self.mainTextField.layer.borderColor = [UIColor colorWithRed:(84/255.0) green:(222/255.0) blue:(167/255.0) alpha:1].CGColor;
    
    self.characterCountLabel.hidden = NO;
    self.characterCountLabel.text = @"2 sentences remaining.";
    
    [self.statusLabel sizeToFit];
    
    [self.textInputField becomeFirstResponder];
       
    // Watch the keyboard frame..
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
}


// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 10, 10);
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds {
    return CGRectInset(bounds, 10, 10);
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
    
    newGameString = self.textInputField.text;
 
    NSString *sendString = [@[self.mainTextField.text, newGameString] componentsJoinedByString:@" "];
    
    NSLog(@"SEND STRING: %@", sendString);
    
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
    
    NSLog(@"CURRENT MATCH: %@", currentMatch);
    
    [currentMatch endTurnWithNextParticipants:nextParticipants turnTimeout:GKTurnTimeoutDefault
                                    matchData:data completionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Error ending turn: %@", error.localizedDescription);
            self.statusLabel.text = @"Oops, something went wrong. Try that again.";
            
        } else {
            
            NSArray *messagesArray = @[@"Hahahaha, this is hilarious. You're the George Carlin of our generation.", @"Woah, I didn't expect that...", @"You really outdid yourself with that one. Hillahrious. Clap clap clap.", @"I have a great sense of humor. When I'm provided humor, I sense it.", @"Swoosh, woosh, poosh. That's the sound of me sending this message into the abyss.", @"Seriously? That's what you came up with?", @"It's kinda funny, I guess.", @"Dude (or dudette), that was pretty funny.", @"I thought it over and I think you're alright.", @"Dayumn!", @"Cue laughter.", @"Now go look in the mirror and say, \"Damn you're sexy.\"", @"George Carlin is spinning in his grave right now.", @"You've just made everyone's day better. Hahahaha.", @"No, you deent", @"Woah, dude, you're killin' it right now.", @"I say, goddamn!", @"Hohohohoh, I daresay.", @"Well, it is what it is, you know."];
            
            NSUInteger randomIndex = arc4random() % [messagesArray count];
            NSString *randomMessage = [messagesArray objectAtIndex:randomIndex];

            AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:randomMessage];
            utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-GB"];
            utterance.pitchMultiplier = 1.3;
            // utterance.rate = 2;
            
            AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
            [synthesizer speakUtterance:utterance];
            
            self.statusLabel.alpha = 0;
            
            self.statusLabel.text = randomMessage;
            
            self.textInputFieldBottom.constant = 50;
            
            [UIView animateWithDuration:1.5 animations:^{
                self.statusLabel.alpha = 1;

                [self.view setNeedsLayout];
                [self.view layoutIfNeeded];
            }];
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
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    //FIXME: For iPad... Doesn't work?
    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect = self.view.bounds;
    
    UIAlertAction* completeAction = [UIAlertAction actionWithTitle:@"Bow Out and Leave" style:UIAlertActionStyleDefault
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
    
    
    if (![self.match.participants objectAtIndex:0].lastTurnDate) { // If no turn has been taken, only provide remove option
        [alert addAction:removeAction];
    // Provide complete option to open or matching games where user has taken a turn
    } else if (self.match.status == GKTurnBasedMatchStatusOpen || (self.match.status == GKTurnBasedMatchStatusMatching && [self.match.participants objectAtIndex:0].lastTurnDate != nil)) {
        [alert addAction:completeAction];
        [alert addAction:shareAction];
    } else if (self.match.status == GKTurnBasedMatchStatusEnded) {
        [alert addAction:shareAction];
        [alert addAction:removeAction];
    }
    
    [alert addAction:cancelAction];
    
    alert.view.tintColor = [UIColor redColor];
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (void)confirmQuit
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Complete this comedy piece?"
                                                                    message:@"This will end the game."
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
    // If quitting a game where it's our turn, just end the match for now.
    // When we add more players (3+), need to set loop over the participants
    // and pass turn.
    if ([self.match.currentParticipant.player.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
        
        for (GKTurnBasedParticipant *participant in self.match.participants) {
            participant.matchOutcome = GKTurnBasedMatchOutcomeTied;
        }
        
        [self.match endMatchInTurnWithMatchData:self.match.matchData completionHandler:^(NSError *error) {
            
            if (error) {
                NSLog(@"Error ending match (in game screen vc): %@", error);
            }
        }];
        
    } else { // If not this player's turn:
    
        // Resigns the player from the match.
        // This action does not end the match if there are more than two players remaining.
        // But since only two players are currently supported, it will end the match.
        
        for (GKTurnBasedParticipant *participant in self.match.participants) {
            participant.matchOutcome = GKTurnBasedMatchOutcomeWon;
        }
        
        [self.match participantQuitOutOfTurnWithOutcome:GKTurnBasedMatchOutcomeQuit withCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Error quitting game: %@", error.localizedDescription);
            }
        }];
    }
    
    // Notify to reload the table view
    [[NSNotificationCenter defaultCenter] postNotificationName:@"StateOfMatchesHasChangedNotification" object:self];
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


- (void)confirmRemoval
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Delete this beautiful comedy piece from existence?"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:@"Yeah" style:UIAlertActionStyleDefault
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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *prompt = [defaults objectForKey:@"FWUserPromptSelectionDefault"];
    self.mainTextField.text = prompt;
   
    self.statusLabel.text = @"Your turn.";
    
    // Shift everything up
    self.textInputFieldBottom.constant = 240;
    
    [UIView animateWithDuration:1 animations:^{
        [self.view setNeedsLayout];
    }];
    
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
    
    // Shift everything up
    self.textInputFieldBottom.constant = 240;
    
    [UIView animateWithDuration:1 animations:^{
        [self.view setNeedsLayout];
    }];
    
    NSArray *messagesArray = @[@"Ah, it's you again.", @"Yo, dawg, you back?", @"Show me the funny.", @"Funny is you.",
                               @"Don't let me down, ok?", @"Prepare to be seriously entertained.", @"Come on, the audience ain't got all day.", @"Hilarity is about to ensue.", @"I don't know if you can be funny, but you look pretty funny."
                               , @"Give it your best shot, son.", @"It's not you again, is it?", @"You. You. It's you.",@"Let's hear it.", @"Do whatchu gotta do.", @"Come on, dude, kill it."];
    
    NSUInteger randomIndex = arc4random() % [messagesArray count];
    NSString *randomMessage = [messagesArray objectAtIndex:randomIndex];
    
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:randomMessage];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-GB"];
    utterance.pitchMultiplier = .9;
    //            utterance.rate = 2;
    
    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
    [synthesizer speakUtterance:utterance];
    
    self.statusLabel.text = randomMessage;
    self.textInputField.hidden = NO;
    self.textInputField.enabled = YES;
    
    self.characterCountLabel.hidden = NO;
    self.characterCountLabel.text = @"2 sentences remaining.";
    
    __weak typeof(self) weakSelf = self;
    
    NSLog(@"Match: %@", match.description);

    [match loadMatchDataWithCompletionHandler:^(NSData *matchData, NSError *error) {
        if ([matchData bytes]) {
            
            NSString *gameTextSoFar = [[NSString alloc] initWithData:matchData encoding:NSUTF8StringEncoding];
            NSLog(@"gameTextSoFar: %@", gameTextSoFar);
            //NSString *gameTextSoFar = [NSString stringWithUTF8String:[matchData bytes]];
            
            // Update the UI on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.mainTextField.text = gameTextSoFar;
            });
        } else {
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *prompt = [defaults objectForKey:@"FWUserPromptSelectionDefault"];
            
            weakSelf.mainTextField.text = [NSString stringWithFormat:@"%@%@%@", @"Now let's talk about ", prompt, @"."];
        }
    }];
    
    [self.view setNeedsDisplay];
}


- (void)layoutCurrentMatch:(GKTurnBasedMatch *)match
{
    NSLog(@"Viewing a match where it's not our turn...");
    
    NSLog(@"MATCH: %@", match);
    
    // Shift textfield down and stretch the text view
    self.textInputFieldBottom.constant = 20;
    
    [UIView animateWithDuration:1 animations:^{
        [self.view setNeedsLayout];
    }];
    
    self.textInputField.hidden = YES;
    self.characterCountLabel.hidden = YES;
    
    NSString *statusString;
    
    if (match.status == GKTurnBasedMatchStatusEnded) {
        
        NSLog(@"Match ended: %@", match.description);
        statusString = @"One of the writers marked this comedy piece complete. Share it!";
        self.characterCountLabel.hidden = YES;
    } else {
        NSString *playerName = match.currentParticipant.player.displayName;
        //NSUInteger playerNum = [match.participants indexOfObject:match.currentParticipant] + 1;
        statusString = playerName? [NSString stringWithFormat:@"\n\n%@'s turn.", playerName] :
            [NSString stringWithFormat: @"\n\nWaiting to be matched with a random individual."];
    }
    
    AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:statusString];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-GB"];

    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
    [synthesizer speakUtterance:utterance];

    
    self.statusLabel.text = statusString;
    self.textInputField.enabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [match loadMatchDataWithCompletionHandler:^(NSData *matchData, NSError *error) {
        
        if (error) {
            NSLog(@"Error loading match data: %@", error.localizedDescription);
        }
        NSLog(@"MATCH DATA: %@", [NSString stringWithUTF8String:[matchData bytes]]);
        
        if ([matchData bytes]) {
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
