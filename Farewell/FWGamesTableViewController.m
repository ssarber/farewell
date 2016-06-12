//
//  FWGamesTableViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/24/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWGamesTableViewController.h"
#import "FWGameScreenViewController.h"
#import "FWMatchCellTableViewCell.h"
#import "GameSegue.h"
#import "UIImageView+Letters.h"
@import GameKit;

typedef NS_ENUM(NSInteger, FWGamesTableViewSection) {
    FWGamesTableViewSectionMyTurn   = 0,
    FWGamesTableViewSectionTheirTurn   = 1,
    FWGamesTableViewSectionGameEnded  = 2
};

@interface FWGamesTableViewController () <UITableViewDelegate, UITableViewDataSource,
FWTurnBasedMatchDelegate, FWMatchCellTableViewCellDelegate>

@property (strong, nonatomic) FWGameScreenViewController *gameVC;

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *allMyMatches;
@property (nonatomic) GKTurnBasedMatchOutcome myOutcome;

@end

@implementation FWGamesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:_headerView.bounds];
    _headerView.layer.masksToBounds = NO;
    _headerView.layer.shadowColor = [UIColor blackColor].CGColor;
    _headerView.layer.shadowOffset = CGSizeMake(0.0f, 5.0f);
    _headerView.layer.shadowOpacity = 0.3f;
    _headerView.layer.shadowPath = shadowPath.CGPath;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [[FWGameCenterHelper sharedInstance] authenticateLocalUserFromController:self];
    
    [FWGameCenterHelper sharedInstance].delegate = self;
    
    self.tableView.rowHeight = 120;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    self.gameVC = [storyboard instantiateViewControllerWithIdentifier:@"FWGameScreenViewControllerID"];

    [self reloadTableView];
    
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
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource Protocol methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
//    header.backgroundView.backgroundColor = [UIColor clearColor];
//    header.textLabel.textColor = [UIColor grayColor];
    header.textLabel.font = [UIFont boldSystemFontOfSize:18];
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


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FWMatchCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FWMatchCellTableViewCell" forIndexPath:indexPath];
    
    GKTurnBasedMatch *match = [[self.allMyMatches objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    cell.match = match;
    cell.delegate = self;
    
    if ([match.matchData length] > 0) {
        NSString *storyString = [NSString stringWithUTF8String:[match.matchData bytes]];
        cell.storyText.text = storyString;
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


- (BOOL)isLocalParticipant:(GKTurnBasedParticipant *)participant
{
    if ([participant.player.playerID isEqual:[GKLocalPlayer localPlayer].playerID]) {
        return YES;
    } else {
        return NO;
    }
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


# pragma mark - FWTurnBasedMatchDelegate protocol methods

- (void)enterNewGame:(GKTurnBasedMatch *)match
{
    NSLog(@"======== Entering new game ===========");
//
//    if ([self.gameVC isPresented] == NO) {
//        [self presentViewController:self.gameVC animated:YES completion:nil];
//    }

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
    [self presentViewController:self.gameVC animated:YES completion:nil];
    
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
