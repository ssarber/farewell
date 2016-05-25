//
//  FWInitialFlowViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/11/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWInitialFlowViewController.h"
#import "FWMainScreenViewController.h"

@interface FWInitialFlowViewController ()

@property (weak, nonatomic) IBOutlet UILabel *label;

@property (strong, nonatomic) NSArray *textArray;

@property (nonatomic) NSUInteger textIndex;

@property (weak, nonatomic) IBOutlet UIButton *beginButton;

@property (assign, nonatomic) BOOL userHasSeenInitialFlow;

@end

@implementation FWInitialFlowViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    _textIndex = -1;
    self.beginButton.hidden = YES;
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

- (NSArray *)textArray {
    if (!_textArray) {
        _textArray= @[@"You come to work in the morning. Pour yourself a cup of coffee.",
                      @"You settle into your chair and open Gmail.",
                      @"Read all the stupid emails that dont't have a thing to do with you.",
                      @"Go say hi to your friend from accounting.",
                      @"Discuss what idiots your bosses are and how they're running the company into the ground.",
                      @"But you know what, if you're such a genius, why are you still working here?",
                      @"Hmm, you do have a point.",
                      @"Maybe you should quit?",
                      @"Go do something meaningful, something you wanted to do up until you got that mortgage and car payments.",
                      @"You know what, maybe I will quit.",
                      @"OK, what do you do now?",
                      @"You need to write an email saying you hereby tender your resignation and wish everyone much success.",
                      @"Sounds kinda aweful. Kinda dull and cookie-cutter.",
                      @"Doesn't it?",
                      @"Well, why don't you use your imagination and write a better email?",
                      @"This place could use some honesty, quite honestly.",
                      @"Just say what's on your mind.",
                      @"Just write a couple sentences to get started, then pass turn to your friend, see if he/she can add anything.",
                      @"Then read what they wrote and add a couple sentences again. See if you can have some fun.",
                      @"Ready to begin?"];
    }
    
    return _textArray;
}

- (IBAction)changeText:(id)sender
{
    
    [UIView transitionWithView:self.label duration:0.5 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.label.text = [self text];
    } completion:nil];
}

- (NSString *)text
{
    self.beginButton.hidden = self.userHasSeenInitialFlow? NO : YES;
    
    if (self.textIndex >= self.textArray.count - 1) {
        self.textIndex = 0;
    } else {
        self.textIndex = self.textIndex + 1;
    }
    if (self.textIndex == self.textArray.count - 1) {
        
        [UIView transitionWithView: self.beginButton duration:4.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
            self.beginButton.hidden = NO;
            self.userHasSeenInitialFlow = YES;
        } completion:nil];
    }
    return self.textArray[self.textIndex];
}

- (IBAction)presentLandingViewController:(id)sender
{
    UIViewController *landingScreenVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"FWLandingScreenViewControllerID"];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:landingScreenVC];
    
    [self presentViewController:navController animated:YES completion:nil];
}


@end