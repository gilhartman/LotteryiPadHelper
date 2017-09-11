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
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (nonatomic, strong) NSString *currentTicketOrdinal;
@property (nonatomic, strong) NSNumber *currentTicketTotalWinnings;
@property (nonatomic, strong) NSString *currentTicketWinningsList;
@property (nonatomic, strong) NSString *currentTicketFirstBetNumbers;
@property (nonatomic) bool currentTicketWinner;
@property (nonatomic, strong) NSMutableArray *numbersArray;
@property (nonatomic, strong) NSArray *prizesArray;
@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableArray *tableData;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.numbersArray = [[NSMutableArray alloc] initWithObjects: self.number1,self.number2,self.number3,self.number4,self.number5,self.number6,nil];
    [[self outputText] setText: @"Waiting for file...."];
    [[self winningOutputText] setText: @""];
    [[self generalWinningOutputText] setText: @""];
    self.tableData = [[NSMutableArray alloc] init];
    [self debugSetup];
}

- (void) debugSetup {
    [self initXmlParser: [[NSBundle mainBundle] URLForResource:@"example2" withExtension:@".xml"]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }

    cell.textLabel.text = [self.tableData objectAtIndex:indexPath.row];
    return cell;
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
        self.currentTicketOrdinal = attributeDict[@"OrdinalNumber"];
        self.currentTicketWinner = NO;
        self.currentTicketTotalWinnings = 0;
        self.currentTicketWinningsList = @"";
        self.currentTicketFirstBetNumbers = nil;
    }
    if ([elementName hasPrefix: @"Block"]) {
        NSString *guessString = attributeDict[@"RegularGuess"];
        NSArray *numersInBlock = [guessString componentsSeparatedByString: @","];
        if (self.currentTicketFirstBetNumbers == nil) {
            self.currentTicketFirstBetNumbers = [guessString copy];
        }
        int matchings = 0;
        for (UITextField *number in self.numbersArray) {
            if ([numersInBlock containsObject: number.text]) {
                matchings += 1;
            }
        }
        BOOL extraNum = [numersInBlock containsObject: self.extraNumber.text];
        if (matchings >= 3 || (matchings == 2 && extraNum)) {
            self.currentTicketWinner = YES;
        }
        int addIfNeeded = extraNum ? 0 : 1;
        NSNumber *currentBlockWinning = 0;
        switch (matchings) {
            case 6: currentBlockWinning = self.prizesArray[0]; break;
            case 5: currentBlockWinning = self.prizesArray[1+addIfNeeded]; break;
            case 4: currentBlockWinning = self.prizesArray[3+addIfNeeded]; break;
            case 3: currentBlockWinning = self.prizesArray[5+addIfNeeded]; break;
        }
        if (matchings == 2 && extraNum) {
            currentBlockWinning = self.prizesArray[7];
        }
        self.currentTicketWinningsList = [self.currentTicketWinningsList stringByAppendingString: [NSString stringWithFormat: @"%lu, ", [currentBlockWinning longValue]]];
        self.currentTicketTotalWinnings = @([self.currentTicketTotalWinnings longValue] + [currentBlockWinning longValue]);
    }

}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if ([elementName isEqualToString: @"bet"]) {
        if (self.currentTicketWinner) {
            [self.tableData addObject:[NSString stringWithFormat: @"Ticket %@ - %@ - %@ - %@", self.currentTicketOrdinal, self.currentTicketTotalWinnings, self.currentTicketWinningsList, self.currentTicketFirstBetNumbers]];
        }
    }
    [self.tableview reloadData];
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
    while (([winningNumbersParser getWinningNumbers] == nil) && ([winningNumbersParser getPrizes] == nil)) {
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

    self.prizesArray = [winningNumbersParser getPrizes];
    NSLog(@"Prizes: %@", self.prizesArray);
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
