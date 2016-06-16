//
//  FWMatchCellTableViewCell.m
//  Farewell
//
//  Created by Zook Gek on 5/24/16.
//  Copyright © 2016 Stan Sarber. All rights reserved.
//

#import "FWMatchCellTableViewCell.h"
#import "UIImageView+Letters.h"

@implementation FWMatchCellTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.storyText.font = [UIFont fontWithName:@"AvenirNext-Bold" size:16];
    
//    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2;
//    self.profileImageView.clipsToBounds = YES;
    self.playerOnePhoto.layer.cornerRadius = self.playerOnePhoto.frame.size.width / 2;
    self.playerOnePhoto.clipsToBounds = YES;
    
    self.playerTwoPhoto.layer.cornerRadius = self.playerTwoPhoto.frame.size.width / 2;
    self.playerTwoPhoto.clipsToBounds = YES;
    
    self.playerThreePhoto.layer.cornerRadius = self.playerTwoPhoto.frame.size.width / 2;
    self.playerThreePhoto.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)loadGameButtonPressed:(id)sender
{ 
    [self.delegate loadAMatch:self.match];
}

- (IBAction)quitButtonPressed:(id)sender
{
    [self.match removeWithCompletionHandler:^(NSError *error) {
        NSLog(@"Removed match: %@", self.match);
    }];
}

@end
