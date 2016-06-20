//
//  FWGamesTableViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/24/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWAppDelegate.h"
#import "FWGamesTableViewController.h"
#import "FWGameScreenViewController.h"
#import "FWMatchCellTableViewCell.h"
#import "GameSegue.h"
#import "UIImageView+Letters.h"
@import GameKit;

NSString *const kFWUserHasSeenInitialTutorialUserDefault = @"FWUserHasSeenInitialTutorialUserDefault";

typedef NS_ENUM(NSInteger, FWGamesTableViewSection) {
    FWGamesTableViewSectionMyTurn   = 0,
    FWGamesTableViewSectionTheirTurn   = 1,
    FWGamesTableViewSectionGameEnded  = 2
};

@interface FWGamesTableViewController () <UITableViewDelegate, UITableViewDataSource,
FWTurnBasedMatchDelegate, FWMatchCellTableViewCellDelegate>

@property (strong, nonatomic) FWGameScreenViewController *gameVC;

@property (assign, nonatomic) BOOL userHasSeenInitialTutorial;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

// Tutorial
@property (weak, nonatomic) IBOutlet UILabel *tutorialLabel;
@property (weak, nonatomic) IBOutlet UIButton *textLabelButton;
@property (strong, nonatomic) NSArray *textArray;
@property (nonatomic) NSUInteger textIndex;
@property (weak, nonatomic) IBOutlet UIButton *writeButton;

@property (strong, nonatomic) NSArray *allMyMatches;
@property (nonatomic) GKTurnBasedMatchOutcome myOutcome;

@end

@implementation FWGamesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    FWAppDelegate *appDelegate = (FWAppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.window.rootViewController = self;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [[FWGameCenterHelper sharedInstance] authenticateLocalUserFromController:self];
    
    [FWGameCenterHelper sharedInstance].delegate = self;
    
    self.writeButton.hidden = YES;
    [self.tutorialLabel sizeToFit];
    
    [self reloadTableView];
    
    self.headerView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.headerView.layer.shadowOffset = CGSizeMake(0.0, 5);
    self.headerView.layer.shadowRadius = 6;
    self.headerView.layer.shadowOpacity = 0.5;
    
    self.headerView.layer.masksToBounds = NO;
    
//    self.writeButton.tintColor = self.view.tintColor;
    
    self.writeButton.tintColor = [UIColor colorWithRed:255.0f/255.0f
                                                 green:8.0f/255.0f
                                                  blue:0.0f/255.0f
                                                 alpha:1.0f];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.tableView.rowHeight = 120;
    
    // Hide empty cells
    self.tableView.tableFooterView = [UIView new];
    
    // Pull to refresh
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    self.gameVC = [storyboard instantiateViewControllerWithIdentifier:@"FWGameScreenViewControllerID"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView)
                                                 name:@"StateOfMatchesHasChangedNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView)
                                                 name:@"ReceivedTurnEventNotification" object:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}


- (BOOL)hasSeenInitialTutorial
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults objectForKey:kFWUserHasSeenInitialTutorialUserDefault] boolValue];
}
- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (void)reloadTableView
{
    [GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error) {
        if (error) {
            NSLog(@"Error loading matches: %@", error.localizedDescription);
            
            
#warning Remove before shipping
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error loading matches:"
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [self presentViewController:alert animated:YES completion:nil];

        }
        if (matches) {
            _userHasSeenInitialTutorial = YES;
            self.headerView.hidden = NO;
            self.writeButton.hidden = NO;
            
            if (self.tutorialLabel) {
                [self.tutorialLabel removeFromSuperview];
            };
            
            if (self.textLabelButton) {
                [self.textLabelButton removeFromSuperview];
            };
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                
            // User has seen the initial flow, don't show again
            [defaults setObject:[NSNumber numberWithBool: YES] forKey:kFWUserHasSeenInitialTutorialUserDefault];
            [defaults synchronize];

            NSMutableArray *myMatches = [NSMutableArray array];
            NSMutableArray *otherMatches = [NSMutableArray array];
            NSMutableArray *endedMatches = [NSMutableArray array];
            
            for (GKTurnBasedMatch *m in matches) {
                for (GKTurnBasedParticipant *p in m.participants) {
                    if ([p.player.playerID isEqual:[GKLocalPlayer localPlayer].playerID]) {
                        _myOutcome = p.matchOutcome;
                    }
                }
                
                if (m.status != GKTurnBasedMatchStatusEnded && _myOutcome != GKTurnBasedMatchOutcomeQuit) {
                    if ([m.currentParticipant.player.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
                        [myMatches addObject:m];
                    } else {
                        [otherMatches addObject:m];
                    }
                } else {
                    [endedMatches addObject:m];
                }
            }
            self.allMyMatches = @[myMatches, otherMatches, endedMatches];
            for (GKTurnBasedMatch *myMatch in [self.allMyMatches objectAtIndex:0]){
                NSString *dataString = [[NSString alloc] initWithData:myMatch.matchData encoding:NSUTF8StringEncoding];
                NSLog(@"\n\nDATA: %@", dataString);
            }
            
            [self.tableView reloadData];
        } else {
            // Set up tutorial
            if (![self hasSeenInitialTutorial]) {
                self.tutorialLabel.text = @"The rules are simple.";
                [self.view bringSubviewToFront:self.tutorialLabel];
                [self.view bringSubviewToFront:self.textLabelButton];
                
                self.headerView.hidden = YES;
                self.writeButton.hidden = YES;
            } else { // Don't hide the write button is user has seen the tutorial but deleted all the matches
                self.writeButton.hidden = NO;
            }
        }
    }];
}

#pragma mark - Secondary tutorial 


- (NSArray *)textArray {
    if (!_textArray) {
        _textArray = @[@"",
                       @"You begin the email by writing the first two sentences.",
                       @"Then you pass the turn to your co-writer.",
                       @"He (or she) will add his (or her) two sentences.",
                       @"Let's get the ball rolling, yeah?",
                       @"I can only show you the button at the bottom of this screen; you are the one that has to tap it."];
    }
    
    return _textArray;
}


- (IBAction)changeText:(id)sender
{
    [UIView transitionWithView:self.tutorialLabel duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                           self.tutorialLabel.text = [self newSentence];
                       } completion:nil];
}


- (NSString *)newSentence
{
    self.writeButton.hidden = self.userHasSeenInitialTutorial? NO : YES;
    
    if (self.textIndex >= self.textArray.count - 1) {
        self.textIndex = 0;
    } else {
        self.textIndex = self.textIndex + 1;
    }
    if (self.textIndex == self.textArray.count - 1) {
        void (^initialFlowFinishedBlock)() = ^{
            self.userHasSeenInitialTutorial = YES;
            self.textLabelButton.userInteractionEnabled = NO;
        };
        
        [UIView transitionWithView: self.headerView duration:4.0
                           options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                               self.headerView.hidden = NO;
                               initialFlowFinishedBlock();
                           } completion:nil];
        
        [UIView transitionWithView:self.writeButton duration:0
                           options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                               self.writeButton.imageView.alpha = 0;
                               self.writeButton.alpha = 0;
                               
                           } completion:^ (BOOL finished){
                               [UIView animateWithDuration:1
                                                     delay:3.5
                                                   options: UIViewAnimationOptionTransitionCrossDissolve
                                                animations:^{
                                                    self.writeButton.hidden =  NO;
                                                    self.writeButton.imageView.alpha = 1;
                                                    self.writeButton.alpha = 1;}
                                                completion:nil];
                           }];
    }
    return self.textArray[self.textIndex];
}


# pragma mark - Pull-to-refresh

- (void)refresh:(UIRefreshControl *)refreshControl
{
    [self reloadTableView];
    [refreshControl endRefreshing];
}


- (void)scrolllTextViewToBottom:(UITextView *)textView
{
    if (textView.text.length > 0) {
        NSRange bottom = NSMakeRange(textView.text.length - 1, 1);
        [textView scrollRangeToVisible:bottom];
    }
}


#pragma mark - UITableViewDataSource Protocol methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
//    header.backgroundView.backgroundColor = [UIColor clearColor];

    header.textLabel.font = [UIFont fontWithName:@"AvenirNext-Bold" size:23];
    CGRect headerFrame = header.frame;
    header.textLabel.frame = headerFrame;
    header.textLabel.textAlignment = NSTextAlignmentLeft;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // Hide section header if section is empty
    if ([tableView.dataSource tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0;
    } else {
        return 44;
    }
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == FWGamesTableViewSectionMyTurn) {
        return @"My Turn";
    } else if (section == FWGamesTableViewSectionTheirTurn) {
        return @"Co-writer's Turn";
    } else {
        return @"Compeleted Emails";
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.allMyMatches objectAtIndex:section] count];
}


// Converts point of the button on every cell to indexPath. Used so that the entire cell is tappable.
- (IBAction)cellContainerButtonPressed:(id)sender
{
    CGPoint point = [self.tableView convertPoint:[sender center] fromView:sender];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    GKTurnBasedMatch *match = [[self.allMyMatches objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSLog(@"MATCH: %@", match);
    
    [[FWGameCenterHelper sharedInstance] loadAMatch:match];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FWMatchCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FWMatchCellTableViewCell" forIndexPath:indexPath];
    
    GKTurnBasedMatch *match = [[self.allMyMatches objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    cell.match = match;
    cell.delegate = self;
    
    if ([match.matchData length] > 0) {
        NSString *storyString = [NSString stringWithUTF8String:[match.matchData bytes]];
        cell.storyText.text = storyString;
        [self scrolllTextViewToBottom:cell.storyText];
        // cell.storyText.textContainer.maximumNumberOfLines = 2;
        
    } else {
        cell.storyText.text = @"Awaiting your turn!";
    }
    NSUInteger index = 0;
    for (GKTurnBasedParticipant *p in match.participants) {
            [p.player loadPhotoForSize:GKPhotoSizeSmall withCompletionHandler:^(UIImage *photo, NSError *error) {
                
                
                // If awaing an auto-matched user, no player id yet, but this will be the current
                // participant, so set a question mark image on the left
                if (match.status == GKTurnBasedParticipantStatusMatching) {
                    UIImage *questionMarkImage = [UIImage imageNamed:@"question-mark-icon.png"];
                    [cell.playerOnePhoto setImage:questionMarkImage];
                }
                
                     
                // Handle case for current participant -- photo on the left
                if ([p.player.playerID isEqual:match.currentParticipant.player.playerID]) {
                    if (photo != nil) {
                        [cell.playerOnePhoto setImage:photo];
                    } else {
                        NSString *userInitials;
                        if ([self isLocalParticipant:p]) {
                            userInitials = @"M E";
                            [cell.playerOnePhoto setImageWithString:userInitials color:[UIColor greenColor] circular:YES];
                        } else {
                            userInitials = p.player.displayName;
                            [cell.playerOnePhoto setImageWithString:userInitials color:[UIColor greenColor] circular:YES];
                        }
                    }
                    
                } else { // if not this player's turn, set photo to the right
            
                    if (photo != nil) {
                        [cell.playerTwoPhoto setImage:photo];
                    } else {
                        NSString *userInitials;
                        // If local player, set initials to "ME", since the displayName is actually "Me"
                        if ([self isLocalParticipant:p]) {
                            userInitials = @"M E";
                            [cell.playerTwoPhoto setImageWithString:userInitials color:[UIColor redColor] circular:YES];
                        } else {
                            userInitials = p.player.displayName;
                            [cell.playerTwoPhoto setImageWithString:userInitials color:[UIColor blueColor] circular:YES];
                        }
                }
                    
                // Completed Emails section
                if (match.status == GKTurnBasedMatchStatusEnded) {
                    if (photo) {
                        [[cell.playerPhotos objectAtIndex:index] setImage:photo];
                    } else {
                        NSString *userInitials;
                        if ([self isLocalParticipant:p]) {
                            userInitials = @"M E";
                            [[cell.playerPhotos objectAtIndex:index] setImageWithString:userInitials color:[UIColor lightGrayColor] circular:YES];
                        } else {
                            userInitials = p.player.displayName;
                            [[cell.playerPhotos objectAtIndex:index] setImageWithString:userInitials color:[UIColor lightGrayColor] circular:YES];
                        }
                    }
                }
            }
        }];
        index = index + 1;
    }
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GKTurnBasedMatch *match = [[self.allMyMatches objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    NSLog(@"MATCH: %@", match);
    
    [[FWGameCenterHelper sharedInstance] loadAMatch:match];
}


- (IBAction)presentGCViewControllerForNewGame:(id)sender
{
    [[FWGameCenterHelper sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 showExistingMatches:NO viewController:self];
    
}

- (BOOL)isLocalParticipant:(GKTurnBasedParticipant *)participant
{
    if ([participant.player.playerID isEqual:[GKLocalPlayer localPlayer].playerID]) {
        return YES;
    } else {
        return NO;
    }
}

# pragma mark - FWTurnBasedMatchDelegate protocol methods

- (void)enterNewGame:(GKTurnBasedMatch *)match
{
    NSLog(@"======== Entering new game ===========");

//    if ([self.gameVC isPresented] == NO) {
//        [self presentViewController:self.gameVC animated:YES completion:nil];
//    }

    // Finish with the initial tutorial
    [self.tutorialLabel removeFromSuperview];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([self hasSeenInitialTutorial] == NO) {
        
        // User has seen the initial flow, don't show again
        [defaults setObject:[NSNumber numberWithBool: YES] forKey:kFWUserHasSeenInitialTutorialUserDefault];
        [defaults synchronize];
    }
    
    [self.gameVC enterNewGameForMatch:match];
}


-(void)takeTurnInGame:(GKTurnBasedMatch *)match
{
    self.gameVC.match = match;
    
    if ([self.gameVC isPresented] == NO) {
        [self presentViewController:self.gameVC animated:YES completion:nil];
    }
    
    [self.gameVC takeTurnInMatch:match];
}


- (void)layoutMatch:(GKTurnBasedMatch *)match
{
    self.gameVC.match = match;
    if ([self.gameVC isPresented] == NO) {
        [self presentViewController:self.gameVC animated:YES completion:nil];
    }
    
    [self.gameVC layoutCurrentMatch:match];
}



- (void)sendNotice:(NSString *)notice forMatch:(GKTurnBasedMatch *)match
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Um, hello?"
                                                                   message:@"Another email requires your immediate attention."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Oh, OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
