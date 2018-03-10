//
//  WinningNumbersParser.m
//  LotteryiPadHelper
//
//  Created by Gil on 7/8/17.
//  Copyright © 2017 Hartman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WinningNumbersParser.h"

@interface WinningNumbersParser ()
@property (nonatomic, strong) NSMutableArray *winningNumbers;
@property (nonatomic, strong) NSMutableArray *prizes;
@end

@implementation WinningNumbersParser

Boolean insideNumber = NO;
Boolean insidePrize = NO;
Boolean insideDrawDate = NO;
Boolean foundDraw = NO;

-(id) init {
    self.winningNumbers = [[NSMutableArray alloc]init];
    self.prizes = [[NSMutableArray alloc]init];
    return self;
}

- (void) parseResults:(NSData *)data {
    NSError *myError = nil;
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&myError];
    if (!result) {
        return;
    }
    NSDictionary* winningNumbersDict = [result objectForKey:@"lr"];
    NSLog(@"winningNumbersDict: %@", winningNumbersDict);
    for (int i=1; i<8; i++) {
        NSObject* obj = [winningNumbersDict objectForKey:[NSString stringWithFormat:@"Num_%d", i]];
        [self.winningNumbers addObject: [NSString stringWithFormat:@"%@", obj]];
    }
    NSArray* winningResultsArray = [result objectForKey:@"wr"];
    NSLog(@"winningResultsArray: %@", winningResultsArray);
    for (int i=0; i<8; i++) {
        NSObject* obj = [winningResultsArray[i] objectForKey:@"iamount"];
        [self.prizes addObject: [[NSString stringWithFormat:@"%@", obj] stringByReplacingOccurrencesOfString:@"," withString:@""]];
    }
}

- (NSArray*) getWinningNumbers {
    if ([self.winningNumbers count] < 7) {
        return nil;
    } else {
        return self.winningNumbers;
    }
}

- (NSArray*) getPrizes {
    if ([self.prizes count] < 8) {
        return nil;
    } else {
        return self.prizes;
    }
}


@end
