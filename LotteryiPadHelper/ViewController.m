//
//  ViewController.m
//  LotteryiPadHelper
//
//  Created by Gil on 5/27/17.
//  Copyright © 2017 Hartman. All rights reserved.
//

#import "ViewController.h"
#import "WinningNumbersParser.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *number1;
@property (weak, nonatomic) IBOutlet UITextField *number2;
@property (weak, nonatomic) IBOutlet UITextField *number3;
@property (weak, nonatomic) IBOutlet UITextField *number4;
@property (weak, nonatomic) IBOutlet UITextField *number5;
@property (weak, nonatomic) IBOutlet UITextField *number6;
@property (weak, nonatomic) IBOutlet UITextField *extraNumber;
@property (weak, nonatomic) IBOutlet UILabel *drawDate;
@property (weak, nonatomic) IBOutlet UITextView *outputText;
@property (weak, nonatomic) IBOutlet UITextView *winningOutputText;
@property (weak, nonatomic) IBOutlet UITextView *generalWinningOutputText;
@property (nonatomic, strong) NSString *currentTicket;
@property (nonatomic, strong) NSString *currentTicketText;
@property (nonatomic) bool currentTicketWinner;
@property (nonatomic, strong) NSMutableArray *numbersArray;
@property (nonatomic, strong) NSXMLParser *xmlParser;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.numbersArray = [[NSMutableArray alloc] initWithObjects: self.number1,self.number2,self.number3,self.number4,self.number5,self.number6,nil];
    [[self outputText] setText: @"Waiting for file...."];
    [[self winningOutputText] setText: @""];
    [[self generalWinningOutputText] setText: @""];
//    [self debugSetup];
}

- (void) debugSetup {
    [self initXmlParser: [[NSBundle mainBundle] URLForResource:@"example3" withExtension:@".xml"]];
}


-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{

    if ([elementName isEqualToString: @"head"]) {
        NSString* LocalDrawDateTime = attributeDict[@"LocalDrawDateTime"];
        NSArray* date_time = [LocalDrawDateTime componentsSeparatedByString:@" "];
        [self.drawDate setText: date_time[0]];
        NSArray* date_components = [date_time[0] componentsSeparatedByString:@"-"];
        NSString* url = [NSString stringWithFormat:@"https://resultsservice.lottery.ie//resultsservice.asmx/GetResultsForDate?drawType=Lotto&drawDate=%@-%@-%@", date_components[2], date_components[1], date_components[0]];
        [self getWinningNumbers:url];

    }

    if ([elementName isEqualToString: @"bet"]) {
        self.currentTicket = attributeDict[@"OrdinalNumber"];
        self.currentTicketWinner = NO;
        self.currentTicketText = @"";
    }
    if ([elementName hasPrefix: @"Block"]) {
        NSArray *numersInBlock = [attributeDict[@"RegularGuess"] componentsSeparatedByString: @","];
        int matchings = 0;
        for (UITextField *number in self.numbersArray) {
            if ([numersInBlock containsObject: number.text]) {
                matchings += 1;
            }
        }
        if (matchings >= 3) {
            self.currentTicketWinner = YES;
            self.generalWinningOutputText.text = [self.generalWinningOutputText.text stringByAppendingString: [NSString stringWithFormat: @"Ticket %@ - %@\n", self.currentTicket, elementName]];
        } else if (matchings == 2 && [numersInBlock containsObject: self.extraNumber.text]) {
            self.currentTicketText = [self.currentTicketText stringByAppendingString: [NSString stringWithFormat: @"Ticket %@ - %@\n", self.currentTicket, elementName]];
        }
    }

}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if ([elementName isEqualToString: @"bet"]) {
        if (self.currentTicketWinner) {
            self.winningOutputText.text = [self.winningOutputText.text stringByAppendingString: self.currentTicketText];
        } else {
            self.outputText.text = [self.outputText.text stringByAppendingString: self.currentTicketText];
        }
    }
}

- (void) getWinningNumbers: (NSString*) url {

    WinningNumbersParser* winningNumbersParser = [[WinningNumbersParser alloc] init];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask * dataTask = [session dataTaskWithURL:[NSURL URLWithString: url]
                                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                        if(error == nil)
                                                        {
                                                            NSXMLParser * numbersXmlParser = [[NSXMLParser alloc] initWithData:data];
                                                            [numbersXmlParser setDelegate: winningNumbersParser];
                                                            [numbersXmlParser parse];
                                                        }
                                                        
                                                    }];
     [dataTask resume];
    while ([winningNumbersParser getWinningNumbers] == nil) {
        [NSThread sleepForTimeInterval:0.3f];
    }
    NSArray* winningNumbers = [winningNumbersParser getWinningNumbers];
    NSLog(@"Winning numbers: %@", winningNumbers);
    [self.number1 setText:winningNumbers[0]];
    [self.number2 setText:winningNumbers[1]];
    [self.number3 setText:winningNumbers[2]];
    [self.number4 setText:winningNumbers[3]];
    [self.number5 setText:winningNumbers[4]];
    [self.number6 setText:winningNumbers[5]];
    [self.extraNumber setText:winningNumbers[6]];
}

- (void) initXmlParser: (NSURL*) filePath {
    self.xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:filePath];
    [self.xmlParser setDelegate:self];
    [[self drawDate] setText: @""];
    [[self outputText] setText: @""];
    [[self winningOutputText] setText: @""];
    [[self generalWinningOutputText] setText: @""];
    [self.xmlParser parse];
}


@end
