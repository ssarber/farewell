//
//  FWPromptSelectionViewController.m
//  Farewell
//
//  Created by Zook Gek on 7/4/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWPromptSelectionViewController.h"
#import "FWGameCenterHelper.h"
#import "AMSmoothAlertView.h"
#import "AMSmoothAlertConstants.h"

@interface FWPromptSelectionViewController  () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *prompts;

@end

@implementation FWPromptSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.rowHeight = 120;
    
    if ([self.gamesVC hasSeenInitialTutorial] == NO) {
        
        AMSmoothAlertView *alert = [[AMSmoothAlertView alloc] initDropAlertWithTitle:@"Psst!"
                                                                             andText:@"Select a topic, invite your Game Center friend or get matched with a random individual."
                                                                     andCancelButton:NO
                                                                        forAlertType:AlertInfo
                                                                         buttonTitle:@"OK!"];
        [alert setCornerRadius:10];
        [alert setTitleFont:[UIFont fontWithName:@"Verdana" size:30.0f]];
        
        [alert show];
    }
}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}


- (NSArray *)prompts {
    if (!_prompts ) {
        _prompts = @[@"Grievances and Complaints", @"Relationships", @"Pets: Cats, Dogs, Alligators", @"Office Affairs", @"Guy At Work", @"Politics And Politicians",@"Family", @"Doughnuts", @"Zombies", @"Doughnuts and Zombies", @"Apocalypse", @"TV and Movies"];
    }
    
    return _prompts;
}


#pragma mark - UITableViewDataSource Protocol methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.prompts count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"PromptCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    cell.textLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:23];
    
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.allowsDefaultTighteningForTruncation = YES;
    
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.minimumScaleFactor = .5;

    cell.textLabel.text = [self.prompts objectAtIndex:indexPath.row];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:cell.textLabel.text forKey:@"FWUserPromptSelectionDefault"];
    [defaults synchronize];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // User has seen the initial flow, don't show again
    [defaults setObject:[NSNumber numberWithBool: YES] forKey:@"FWUserHasSeenInitialTutorialUserDefault"];
    [defaults synchronize];
    
    
    AMSmoothAlertView *alert = [[AMSmoothAlertView alloc] initDropAlertWithTitle:@"Psst!"
                                                                         andText:@"If you select Auto-match, whoever starts the game first gets to choose the topic. Keeps things interesting!"
                                                                 andCancelButton:NO
                                                                    forAlertType:AlertInfo
                                                                     buttonTitle:@"Really? OK..."];
    
    [alert setTitleFont:[UIFont fontWithName:@"Verdana" size:30.0f]];
    [alert setCornerRadius:10];
    
    [alert show];
    
    [[FWGameCenterHelper sharedInstance] findMatchWithMinPlayers:2 maxPlayers:2 showExistingMatches:NO viewController:self.gamesVC];
}


- (IBAction)backButtonPressed:(id)sender {
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
