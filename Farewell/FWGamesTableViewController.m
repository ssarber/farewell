//
//  FWGamesTableViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/24/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWGamesTableViewController.h"
#import "FWMatchCellTableViewCell.h"
@import GameKit;

typedef NS_ENUM(NSInteger, FWGamesTableViewSection) {
    FWGamesTableViewSectionMyTurn   = 0,
    FWGamesTableViewSectionTheirTurn   = 1,
    FWGamesTableViewSectionGameEnded  = 2
};

@interface FWGamesTableViewController () <FWMatchCellTableViewCellDelegate>

@property (nonatomic, strong) NSArray *allMyMatches;

@end

@implementation FWGamesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
     self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.tableView.rowHeight = 120;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    [self reloadTableView];
}


- (void)cancelButtonPressed
{
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)reloadTableView
{
    [GKTurnBasedMatch loadMatchesWithCompletionHandler:^(NSArray *matches, NSError *error) {
        if (error) {
            NSLog(@"Error loading matches: %@", error.localizedDescription);
        }
        
        NSMutableArray *myMatches = [NSMutableArray array];
        NSMutableArray *otherMatches = [NSMutableArray array];
        NSMutableArray *endedMatches = [NSMutableArray array];
        
        for (GKTurnBasedMatch *m in matches) {
            GKTurnBasedMatchOutcome myOutcome;
            for (GKTurnBasedParticipant *p in m.participants) {
                if ([p.player.playerID isEqualToString:[GKLocalPlayer localPlayer].playerID]) {
                    myOutcome = p.matchOutcome;
                }
            }
            
            if (m.status != GKTurnBasedMatchStatusEnded && myOutcome != GKTurnBasedMatchOutcomeQuit) {
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
        
        NSLog(@"Ooh, matches: %@", self.allMyMatches);
        
        [self.tableView reloadData];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == FWGamesTableViewSectionMyTurn) {
        return @"My Turn";
    } else if (section == FWGamesTableViewSectionTheirTurn) {
        return @"Their Turn";
    } else {
        return @"Game Ended";
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
    }
    
    if (indexPath.section == FWGamesTableViewSectionGameEnded) {
        [cell.quitButton setTitle:@"Remove" forState:UIControlStateNormal];
    } else {
        [cell.quitButton setTitle:@"Quit Game" forState:UIControlStateNormal];
    }
    
    return cell;
}


- (void)loadAMatch:(GKTurnBasedMatch *)match
{
    [self.mainVC dismissViewControllerAnimated:YES completion:nil];
    [[FWTurnBasedMatch sharedInstance] turnBasedMatchmakerViewController:nil didFindMatch:match];
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
