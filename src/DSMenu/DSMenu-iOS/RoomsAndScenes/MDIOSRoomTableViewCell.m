//
//  DMRoomTableViewCell.m
//  dSMetering
//
//  Created by Jonas Schnelli on 16.10.14.
//  Copyright (c) 2014 include7. All rights reserved.
//

#import "MDIOSRoomTableViewCell.h"
#import "MDDSSManager.h"
#import "MDIOSFavoritesManager.h"

@implementation MDIOSRoomTableViewCell

- (void)awakeFromNib {
    // Initialization code
    
    self.colorBadge.backgroundColor = [UIColor clearColor];
}

- (IBAction)favorite:(id)sender
{
    self.isFavorite = !self.isFavorite;
 
    if([sender isKindOfClass:[NSNumber class]])
    {
        self.isFavorite = [sender boolValue];
    }
    
    MDIOSFavorite *favorite = [[MDIOSFavorite alloc] init];
    favorite.zone   = [(NSNumber *)self.zoneId stringValue];
    favorite.group  = nil;
    favorite.scene  = nil;
    favorite.favoriteType = MDIOSFavoriteTypeZone;
    
    UIImage *favStar = nil;
    if(self.isFavorite)
    {
        favStar = [UIImage imageNamed:@"ReviewSheetStarFull.png"];
        [[MDIOSFavoritesManager defaultManager] addFavorit:favorite];
    }
    else
    {
        favStar = [UIImage imageNamed:@"ReviewSheetStarEmptyNew.png"];
        [[MDIOSFavoritesManager defaultManager] removeFavorite:favorite];
    }
    
    self.favoriteButton.selected = self.isFavorite;
}

- (void)buildLabels:(NSObject *)groupNumbersParam
{
    self.groupNumberParam = groupNumbersParam;
    
    NSArray *groupNumbers = nil;
    NSString *customTitle = nil;
    
    if([groupNumbersParam isKindOfClass:[NSDictionary class]])
    {
        groupNumbers = @[ [(NSDictionary *)groupNumbersParam objectForKey:@"group"] ];
        customTitle = [(NSDictionary *)groupNumbersParam objectForKey:@"title"];
    }
    else
    {
        groupNumbers = (NSArray *)groupNumbersParam;
    }
    if(groupNumbers == nil || groupNumbers.count == 0)
    {
        groupNumbers = @[@"nogroups"];
    }
    
    self.availableGroups = groupNumbers;
    
    
    [self.labelsView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.labels = [NSMutableArray array];
    self.labelBackgroundViews = [NSMutableArray array];
    
    NSMutableArray *groups = [NSMutableArray array];
    for(NSString *groupNumber in groupNumbers)
    {
        if([groupNumber isEqualToString:@"nogroups"])
        {
            NSString *title = NSLocalizedString(@"nogroupslabel", @"");
            [groups addObject:@{@"title": title, @"group": @"", @"textcolor": [UIColor whiteColor], @"bgcolor": [UIColor lightGrayColor]}];
        }
        else
        {
            NSString *title = NSLocalizedString(([NSString stringWithFormat:@"group%@OnOff", groupNumber]), @"");
            if(customTitle)
            {
                title = customTitle;
            }
            [groups addObject:@{@"title": title, @"group": groupNumber, @"textcolor": [UIColor whiteColor], @"bgcolor": [UIColor darkGrayColor]}];
        }
    }
    
    for(NSDictionary *labelDict in groups)
    {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,100,20)];
        label.text = [labelDict objectForKey:@"title"];
        label.backgroundColor = [UIColor clearColor];
        label.font = [UIFont systemFontOfSize:12];
        label.textColor = [labelDict objectForKey:@"textcolor"];
        
        [self.labels addObject:label];
        
        UIButton *labelBackgroundView = [[UIButton alloc] init];
        labelBackgroundView.backgroundColor = [labelDict objectForKey:@"bgcolor"];
        [labelBackgroundView setImage:[UIImage imageNamed:[NSString stringWithFormat:@"group_%@.png", [labelDict objectForKey:@"group"]]] forState:UIControlStateNormal];
        
        // check if off item
        if([self isOffItem]){
            [labelBackgroundView setImage:[UIImage imageNamed:@"off_menu_icon.png"] forState:UIControlStateNormal];
        }
        
        labelBackgroundView.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        
        labelBackgroundView.layer.cornerRadius = 2.0;
        labelBackgroundView.layer.masksToBounds = YES;
        labelBackgroundView.tag = [[labelDict objectForKey:@"group"] intValue];
        [labelBackgroundView addTarget:self action:@selector(labelTaped:) forControlEvents:UIControlEventTouchUpInside];
        [self.labelBackgroundViews addObject:labelBackgroundView];
        
        [self.labelsView addSubview:labelBackgroundView];
        [self.labelsView addSubview:label];
    }
    
    [self calculateSizes];
}

- (BOOL)isOffItem
{
    //overwrite when subclassing
    return NO;
}

- (void)showLoading
{
    [self.labelsView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.labels = [NSMutableArray array];
    self.labelBackgroundViews = [NSMutableArray array];
    
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,0,100,20)];
    label.text = @"loading...";
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont systemFontOfSize:12];
    label.textColor = [UIColor whiteColor];
    
    [self.labels addObject:label];
    
    UIButton *labelBackgroundView = [[UIButton alloc] init];
    labelBackgroundView.backgroundColor = [UIColor darkGrayColor];
    
    labelBackgroundView.layer.cornerRadius = 2.0;
    labelBackgroundView.layer.masksToBounds = YES;
    labelBackgroundView.tag = 1000;
    //[labelBackgroundView addTarget:self action:@selector(loadingLabelTaped:) forControlEvents:UIControlEventTouchUpInside];
    [self.labelBackgroundViews addObject:labelBackgroundView];
    
    [self.labelsView addSubview:labelBackgroundView];
    [self.labelsView addSubview:label];

}

- (void)labelTaped:(UIButton *)sender
{
    if(self.availableGroups && self.availableGroups.count == 1 && [[self.availableGroups objectAtIndex:0] isEqualToString:@"nogroups"])
    {
        return;
    }
    
    NSString *group = [NSString stringWithFormat:@"%ld", sender.tag];
    if([MDDSSManager defaultManager].useLastCalledSceneCheck)
    {
        [[MDDSSManager defaultManager] lastCalledSceneInZoneId:self.zoneId groupID:group callback:^(NSDictionary *json, NSError *error)
         {
             if(!error && [json objectForKey:@"result"])
             {
                 NSString *scene = [[json objectForKey:@"result"] objectForKey:@"scene"];
                 int desiredScene = [MDDSHelper nextScene:[scene intValue] group:[group intValue]];

                 NSUInteger aIndex = [self.labelBackgroundViews indexOfObject:sender];
                 UILabel *label = [self.labels objectAtIndex:aIndex];
                 
                 [UIView animateWithDuration:0.5 animations:^{
                     
                     label.text = [NSString stringWithFormat:@"calling %@", NSLocalizedString(( [NSString stringWithFormat:@"group%@scene%d",  group,desiredScene]), @"")];
                     [self calculateSizes];
                     
                 }];
                 
                 NSString *sceneString = [NSString stringWithFormat:@"%d", desiredScene];
                 [[MDDSSManager defaultManager] callScene:sceneString zoneId:self.zoneId groupID:group callback:^(NSDictionary *json, NSError *error)
                  {
                      [self buildLabels:self.groupNumberParam];
                      [self calculateSizes];
                  }];
             }
         }];
        
        NSUInteger aIndex = [self.labelBackgroundViews indexOfObject:sender];
        UILabel *label = [self.labels objectAtIndex:aIndex];
        
        [UIView animateWithDuration:0.5 animations:^{
            label.text = @"loading state...";
            [self calculateSizes];
        }];
    }
    else
    {
        NSUInteger aIndex = [self.labelBackgroundViews indexOfObject:sender];
        UILabel *label = [self.labels objectAtIndex:aIndex];
        
        [UIView animateWithDuration:0.5 animations:^{
            
            label.text = NSLocalizedString(( [NSString stringWithFormat:@"group%@scene5", group]), @"");
            [self calculateSizes];
            
        }];
        
        [[MDDSSManager defaultManager] callScene:@"5" zoneId:self.zoneId groupID:group callback:^(NSDictionary *json, NSError *error)
         {
             label.text = @"done";
             [self calculateSizes];
         }];
    }
}

- (void)calculateSizes
{
    if(self.availableGroups.count > 0)
    {
        int cnt = 0;
        CGFloat xOffset = 0;
        CGFloat xSpace = 4;
        CGFloat imageSpaceH = 20;
        if(self.availableGroups && self.availableGroups.count == 1 && [[self.availableGroups objectAtIndex:0] isEqualToString:@"nogroups"])
        {
            imageSpaceH = 0;
        }
        CGFloat labelHeight = 25;
        for(UILabel *label in self.labels)
        {
            UIButton *backgroundView = [self.labelBackgroundViews objectAtIndex:cnt];
            CGRect calculatedSize = [label textRectForBounds:CGRectMake(0,0,1000,20) limitedToNumberOfLines:1];
            label.frame = CGRectMake(xOffset+4+imageSpaceH,5,calculatedSize.size.width,20);
            
            backgroundView.imageEdgeInsets = UIEdgeInsetsMake(0, -label.frame.size.width-12, 0, 0);
            
            backgroundView.frame = CGRectMake(xOffset+0,2,calculatedSize.size.width+16+imageSpaceH,labelHeight+2);
            xOffset+=backgroundView.frame.size.width+xSpace;
            cnt++;
        }
        self.labelsView.hidden = NO;
        self.labelsView.frame = CGRectMake(self.labelsView.frame.origin.x, self.labelsView.frame.origin.y, self.labelsView.frame.size.width, labelHeight+6);
    }
    else
    {
        self.labelsView.hidden = YES;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    int cnt = 0;
    for(cnt = 0;cnt < self.labels.count; cnt++)
    {
        UIButton *backgroundView = [self.labelBackgroundViews objectAtIndex:cnt];
        backgroundView.backgroundColor = (highlighted) ? [UIColor lightGrayColor]: [UIColor darkGrayColor];
    }
}


@end
