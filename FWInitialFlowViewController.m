//
//  FWInitialFlowViewController.m
//  Farewell
//
//  Created by Zook Gek on 5/11/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWInitialFlowViewController.h"

NSString *const kFWUserHasSeenInitialFlowUserDefault = @"FWUserHasSeenInitialFlowUserDefault";

@interface FWInitialFlowViewController ()

@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UIButton *textLabelButton;
@property (weak, nonatomic) IBOutlet UIButton *beginButton;

@property (strong, nonatomic) NSArray *textArray;
@property (nonatomic) NSUInteger textIndex;

@property (assign, nonatomic) BOOL userHasSeenInitialFlow;

@end

@implementation FWInitialFlowViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    _textIndex = -1;
    [self.textLabel sizeToFit];
    self.beginButton.hidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([self hasSeenInitialFlow] == NO) {
        
        // User has seen the initial flow, don't show again
        [defaults setObject:[NSNumber numberWithBool: YES] forKey:kFWUserHasSeenInitialFlowUserDefault];
        [defaults synchronize];
    }
}

-(BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)hasSeenInitialFlow
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults objectForKey:kFWUserHasSeenInitialFlowUserDefault] boolValue];
}

- (NSArray *)textArray {
    if (!_textArray) {
        _textArray= @[@"You come to work in the morning. Pour yourself a cup of coffee, settle into your chair and open Gmail.\
                      Read all the stupid emails that don't have a thing to do with you, go say hi to your friend from accounting.\
                      Discuss what idiots your bosses are and how they're running the company into the ground.\
                      But you know what, if you're such a genius, why are you still working here?",

                      @"This is a game. It's not serious.\nYou are tasked with writing a farewell email to all your co-workers.\
                      This place could use some honesty, quite honestly. Just say what's on your mind. Write a couple sentences to get started, then pass turn to your friend, see if he/she can add anything. Then read what they wrote and add a couple sentences again. See if you can have some fun.",
                      
                      @"You are a wale of farewells. Some might even say, a farewale.",
                      
                      @"Ready to begin?"];
    }
    
    return _textArray;
}


- (IBAction)changeText:(id)sender
{
    [UIView transitionWithView:self.textLabel duration:0.5
                       options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.textLabel.text = [self newSentence];
    } completion:nil];
}


- (NSString *)newSentence
{
    self.beginButton.hidden = self.userHasSeenInitialFlow? NO : YES;
    
    if (self.textIndex >= self.textArray.count - 1) {
        self.textIndex = 0;
    } else {
        self.textIndex = self.textIndex + 1;
    }
    if (self.textIndex == self.textArray.count - 1) {
        void (^initialFlowFinishedBlock)() = ^{
            self.userHasSeenInitialFlow = YES;
            self.beginButton.hidden =  NO;
            self.beginButton.alpha = 1;
            self.view.backgroundColor = [UIColor blackColor];
        };
        
        [UIView transitionWithView:self.beginButton duration:0
                           options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                               self.beginButton.alpha = 0;
                               self.textLabelButton.userInteractionEnabled = NO;
                               
                           } completion:^ (BOOL finished){
                               [UIView animateWithDuration:.75
                                                     delay:2
                                                   options: UIViewAnimationOptionTransitionCrossDissolve
                                                animations:^{
                                                    initialFlowFinishedBlock();
                                                } completion:nil];
                           }];
    }
    return self.textArray[self.textIndex];
}

@end
