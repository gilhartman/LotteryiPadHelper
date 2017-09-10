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
@property (nonatomic, strong) NSMutableArray *winningNumbers;
@end

@implementation WinningNumbersParser

Boolean insideNumber = NO;

- (id) init
{
    self = [super init];
    self.winningNumbers = [[NSMutableArray alloc]init];
    return self;
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{

    if ([elementName isEqualToString: @"Number"]) {
        insideNumber = YES;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (insideNumber) {
        NSLog(@"found: %@", string); // output book title here
        [self.winningNumbers addObject: string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{

    if ([elementName isEqualToString: @"Number"]) {
        insideNumber = NO;
    }
}

- (NSArray*) getWinningNumbers {
    if ([self.winningNumbers count] < 7) {
        return nil;
    } else {
        return self.winningNumbers;
    }
}



@end
