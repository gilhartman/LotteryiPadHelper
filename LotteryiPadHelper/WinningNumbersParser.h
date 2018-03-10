//
//  WinningNumbersParser.h
//  LotteryiPadHelper
//
//  Created by Gil on 7/8/17.
//  Copyright © 2017 Hartman. All rights reserved.
//

#ifndef WinningNumbersParser_h
#define WinningNumbersParser_h

#import <UIKit/UIKit.h>

@interface WinningNumbersParser : NSObject

-(id) init;

- (void) parseResults:(NSData *)data;

- (NSArray*) getWinningNumbers;

- (NSArray*) getPrizes;

@end
#endif /* WinningNumbersParser_h */
