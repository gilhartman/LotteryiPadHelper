//
//  ViewController.m
//  LotteryiPadHelper
//
//  Created by Gil on 5/27/17.
//  Copyright © 2017 Hartman. All rights reserved.
//

#import "ViewController.h"
#import "WinningNumbersParser.h"
#import "MultiColumnTableViewCell.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *number1;
@property (weak, nonatomic) IBOutlet UITextField *number2;
@property (weak, nonatomic) IBOutlet UITextField *number3;
@property (weak, nonatomic) IBOutlet UITextField *number4;
@property (weak, nonatomic) IBOutlet UITextField *number5;
@property (weak, nonatomic) IBOutlet UITextField *number6;
@property (weak, nonatomic) IBOutlet UITextField *extraNumber;
@property (weak, nonatomic) IBOutlet UILabel *drawDate;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
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
    self.tableData = [[NSMutableArray alloc] init];
    [self.tableview registerClass:[MultiColumnTableViewCell class] forCellReuseIdentifier:@"Cell"];
    self.tableview.separatorColor = [UIColor lightGrayColor];
    self.spinner.hidesWhenStopped = YES;
    [self.spinner stopAnimating];
    #if TARGET_IPHONE_SIMULATOR
    [self debugSetup];
    #endif
}

- (void) debugSetup {
    [self initXmlParser: [[NSBundle mainBundle] URLForResource:@"example2" withExtension:@".xml"]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableData count]+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MultiColumnTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    if (indexPath.row == 0) {
        [cell.label1 setFont:[UIFont boldSystemFontOfSize:20]];
        [cell.label2 setFont:[UIFont boldSystemFontOfSize:20]];
        [cell.label3 setFont:[UIFont boldSystemFontOfSize:20]];
        [cell.label4 setFont:[UIFont boldSystemFontOfSize:20]];
        cell.label1.text = @"Ticket Number";
        cell.label2.text = @"Total Wins";
        cell.label3.text = @"Wins Per Bet";
        cell.label4.text = @"First Bet Numbers";
    } else {
        [cell.label1 setFont:[UIFont systemFontOfSize:16]];
        [cell.label2 setFont:[UIFont systemFontOfSize:16]];
        [cell.label3 setFont:[UIFont systemFontOfSize:16]];
        [cell.label4 setFont:[UIFont systemFontOfSize:16]];
        cell.label1.text = [[self.tableData objectAtIndex:indexPath.row-1] objectAtIndex: 0];
        cell.label2.text = [[self.tableData objectAtIndex:indexPath.row-1] objectAtIndex: 1];
        cell.label3.text = [[self.tableData objectAtIndex:indexPath.row-1] objectAtIndex: 2];
        cell.label4.text = [[self.tableData objectAtIndex:indexPath.row-1] objectAtIndex: 3];
    }
    return cell;
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{

    if ([elementName isEqualToString: @"head"]) {
        NSString* LocalDrawDateTime = attributeDict[@"LocalDrawDateTime"];
        NSArray* date_time = [LocalDrawDateTime componentsSeparatedByString:@" "];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.drawDate setText: date_time[0]];
        });
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
            NSString *f = [self.currentTicketWinningsList substringToIndex:[self.currentTicketWinningsList length]-2];
            NSString * t = [self.currentTicketFirstBetNumbers stringByReplacingOccurrencesOfString:@"," withString:@", "];
            NSArray *rowData = @[self.currentTicketOrdinal, [self.currentTicketTotalWinnings stringValue], f, t];
            [self.tableData addObject: rowData];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableview reloadData];
    });
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
                                                 } else {
                                                     dispatch_async(dispatch_get_main_queue(), ^{
                                                         [self.spinner stopAnimating];
                                                         NSLog(@"Error in connecting %@", error);
                                                         UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"No Network"
                                                                                                                        message:@"Could not connect to lottery site. Please try again"
                                                                                                                 preferredStyle:UIAlertControllerStyleAlert];
                                                         UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                                                               handler:^(UIAlertAction * action) {
                                                                                                                   [alert dismissViewControllerAnimated:YES completion:nil];
                                                                                                               }];
                                                         [alert addAction:defaultAction];
                                                         [self presentViewController:alert animated:YES completion:nil];                                                });
                                                 }
                                             }];
    [dataTask resume];
    while (([winningNumbersParser getWinningNumbers] == nil) && ([winningNumbersParser getPrizes] == nil)) {
        [NSThread sleepForTimeInterval:0.3f];
    }
    NSArray* winningNumbers = [winningNumbersParser getWinningNumbers];
    NSLog(@"Winning numbers: %@", winningNumbers);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.spinner stopAnimating];
        [self.number1 setText:winningNumbers[0]];
        [self.number2 setText:winningNumbers[1]];
        [self.number3 setText:winningNumbers[2]];
        [self.number4 setText:winningNumbers[3]];
        [self.number5 setText:winningNumbers[4]];
        [self.number6 setText:winningNumbers[5]];
        [self.extraNumber setText:winningNumbers[6]];
    });

    self.prizesArray = [winningNumbersParser getPrizes];
    NSLog(@"Prizes: %@", self.prizesArray);
}

- (void) initXmlParser: (NSURL*) filePath {
    self.xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:filePath];
    [self.xmlParser setDelegate:self];
    [self.drawDate setText: @""];
    [self.tableData removeAllObjects];
    self.prizesArray = nil;
    for (UITextField* number in self.numbersArray) {
        [number setText: @""];
        [self.extraNumber setText:@""];
    }
    [self.tableview reloadData];
    [self.spinner startAnimating];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [self.xmlParser parse];
    });
}


@end
