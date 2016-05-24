//
//  FWGamesTableViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/24/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWGamesTableViewController.h"
@import GameKit;

@interface FWGamesTableViewController ()

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
            
            if(m.status != GKTurnBasedMatchStatusEnded && myOutcome != GKTurnBasedMatchOutcomeQuit) {
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
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return 0;
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

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
