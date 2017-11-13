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
@property (nonatomic, strong) NSXMLParser *numbersXmlParser;
@property (nonatomic, strong) NSString *drawDate;
@property (nonatomic, strong) NSMutableArray *winningNumbers;
@property (nonatomic, strong) NSMutableArray *prizes;
@end

@implementation WinningNumbersParser

Boolean insideNumber = NO;
Boolean insidePrize = NO;
Boolean insideDrawDate = NO;
Boolean foundDraw = NO;

-(id)initWithdrawDate:(NSString *)draw_date
{
    self = [super init];
    if (self) {
        self.drawDate = draw_date;
        self.winningNumbers = [[NSMutableArray alloc]init];
        self.prizes = [[NSMutableArray alloc]init];
    }
    return self;
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
    if ([elementName isEqualToString: @"DrawDate"]) {
        insideDrawDate = YES;
    }
    if (foundDraw) {
        if ([elementName isEqualToString: @"Number"]) {
            insideNumber = YES;
        }
        if ([elementName isEqualToString: @"Prize"]) {
            insidePrize = YES;
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (insideDrawDate) {
        if ([string hasPrefix:self.drawDate]) {
            NSLog(@"found drawDate: %@", string);
            foundDraw = YES;
        }
    }
    if (insideNumber) {
        NSLog(@"found number: %@", string);
        [self.winningNumbers addObject: string];
    }
    if (insidePrize) {
        NSLog(@"found prize: %@", string);
        NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
        f.numberStyle = NSNumberFormatterDecimalStyle;
        NSNumber *prizeMoney = [f numberFromString:string];
        [self.prizes addObject: prizeMoney];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{

    if ([elementName isEqualToString: @"DrawDate"]) {
        insideDrawDate = NO;
    }
    if ([elementName isEqualToString: @"Number"]) {
        insideNumber = NO;
    }
    if ([elementName isEqualToString: @"Prize"]) {
        insidePrize = NO;
    }
    if ([elementName isEqualToString: @"DrawResult"]) {
        foundDraw = NO;
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
