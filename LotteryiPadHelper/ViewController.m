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
@property (weak, nonatomic) IBOutlet UILabel *totalWins;
@property (weak, nonatomic) IBOutlet UILabel *netbetWins;
@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSString *currentTicketOrdinal;
@property (nonatomic, strong) NSNumber *currentTicketTotalWinnings;
@property (nonatomic, strong) NSNumber *currentTicketTotalWinningsNo3s;
@property (nonatomic, strong) NSNumber *NSNumberTotalWins;
@property (nonatomic, strong) NSNumber *NSNumberTotalNetbetWins;
@property (nonatomic, strong) NSString *currentTicketWinningsList;
@property (nonatomic, strong) NSString *currentTicketFirstBetNumbers;
@property (nonatomic) bool currentTicketWinner;
@property (nonatomic, strong) NSMutableArray *UITextFieldNumbersArray;
@property (nonatomic, strong) NSArray *winningNumbersArray;
@property (nonatomic, strong) NSArray *prizesArray;
@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) NSMutableArray *tableData;
@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.UITextFieldNumbersArray = [[NSMutableArray alloc] initWithObjects: self.number1,self.number2,self.number3,self.number4,self.number5,self.number6,nil];
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
    [self initXmlParser: [[NSBundle mainBundle] URLForResource:@"example9" withExtension:@".xml"]];
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
        [cell.label5 setFont:[UIFont boldSystemFontOfSize:20]];
        cell.label1.text = @"Ticket Number";
        cell.label2.text = @"Total Wins";
        cell.label3.text = @"Netbet Wins";
        cell.label4.text = @"Wins Per Bet";
        cell.label5.text = @"First Bet Numbers";
    } else {
        [cell.label1 setFont:[UIFont systemFontOfSize:16]];
        [cell.label2 setFont:[UIFont systemFontOfSize:16]];
        [cell.label3 setFont:[UIFont systemFontOfSize:16]];
        [cell.label4 setFont:[UIFont systemFontOfSize:16]];
        [cell.label5 setFont:[UIFont systemFontOfSize:16]];
        cell.label1.text = [[self.tableData objectAtIndex:indexPath.row-1] objectAtIndex: 0];
        cell.label2.text = [[self.tableData objectAtIndex:indexPath.row-1] objectAtIndex: 1];
        cell.label3.text = [[self.tableData objectAtIndex:indexPath.row-1] objectAtIndex: 2];
        cell.label4.text = [[self.tableData objectAtIndex:indexPath.row-1] objectAtIndex: 3];
        cell.label5.text = [[self.tableData objectAtIndex:indexPath.row-1] objectAtIndex: 4];
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
        NSString* draw_date = [NSString stringWithFormat: @"%@-%@-%@", date_components[2], date_components[1], date_components[0]];
        [self getWinningNumbers:draw_date];

    }

    if ([elementName isEqualToString: @"bet"]) {
        self.currentTicketOrdinal = attributeDict[@"OrdinalNumber"];
        self.currentTicketWinner = NO;
        self.currentTicketTotalWinnings = 0;
        self.currentTicketTotalWinningsNo3s = 0;
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
        for (NSString *number in [self.winningNumbersArray subarrayWithRange:NSMakeRange(0,6)]) {
            if ([numersInBlock containsObject: number]) {
                matchings += 1;
            }
        }
        BOOL extraNum = [numersInBlock containsObject: self.winningNumbersArray[6]];
        if (matchings >= 3 || (matchings == 2 && extraNum)) {
            self.currentTicketWinner = YES;
        }
        int extraNumIfNeeded = extraNum ? 1 : 0;
        NSNumber *currentBlockWinning = 0;
        switch (matchings) {
            case 6: currentBlockWinning = self.prizesArray[0]; break;
            case 5: currentBlockWinning = self.prizesArray[2-extraNumIfNeeded]; break;
            case 4: currentBlockWinning = self.prizesArray[4-extraNumIfNeeded]; break;
            case 3: currentBlockWinning = self.prizesArray[6-extraNumIfNeeded]; break;
        }
        if (matchings == 2 && extraNum) {
            currentBlockWinning = self.prizesArray[7];
        }
        long currentBlockLong = [currentBlockWinning integerValue];
        self.currentTicketWinningsList = [self.currentTicketWinningsList stringByAppendingString: [NSString stringWithFormat: @"%lu, ", currentBlockLong]];
        self.currentTicketTotalWinnings = @([self.currentTicketTotalWinnings integerValue] + currentBlockLong);
        self.NSNumberTotalWins = @([self.NSNumberTotalWins integerValue] + currentBlockLong);
        if ([currentBlockWinning integerValue] != 3) {
            self.currentTicketTotalWinningsNo3s = @([self.currentTicketTotalWinningsNo3s integerValue] + currentBlockLong);
            self.NSNumberTotalNetbetWins = @([self.NSNumberTotalNetbetWins integerValue] + currentBlockLong);
        }
    }

}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if ([elementName isEqualToString: @"bet"]) {
        if (self.currentTicketWinner) {
            NSString *f = [self.currentTicketWinningsList substringToIndex:[self.currentTicketWinningsList length]-2];
            NSString * t = [self.currentTicketFirstBetNumbers stringByReplacingOccurrencesOfString:@"," withString:@", "];
            NSArray *rowData = @[self.currentTicketOrdinal, [self.currentTicketTotalWinnings stringValue], [self.currentTicketTotalWinningsNo3s stringValue], f, t];
            [self.tableData addObject: rowData];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableview reloadData];
        [self.totalWins setText:[self.NSNumberTotalWins stringValue]];
        [self.netbetWins setText:[self.NSNumberTotalNetbetWins stringValue]];
    });
}

- (void) showAlert: (NSString*) headline withContent: (NSString*) content {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.spinner stopAnimating];
        UIAlertController* alert = [UIAlertController alertControllerWithTitle: headline
                                                                       message: content
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                              }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];                                                });
}

- (void) getWinningNumbers: (NSString*) draw_date {

    NSString* url = @"https://irishlottoresults.ie/ajaxcontrol.php";
    WinningNumbersParser* winningNumbersParser = [[WinningNumbersParser alloc] init];
    NSLog(@"Sending request: %@ for draw date %@", url, draw_date);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    NSString *post = [NSString stringWithFormat:@"lrseldate=%@",draw_date];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu",(unsigned long)[postData length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask * dataTask = [session dataTaskWithRequest: request
                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                 if(error == nil)
                                                 {
                                                     NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                                     NSLog(@"Received lottery response %@", dataStr);
                                                     if (![dataStr containsString: @"winners"]) {
                                                         [self showAlert: @"Bad Response From Lotto API" withContent: [NSString stringWithFormat:@"Lotto API returned a bad respose:\n %@", dataStr]];

                                                     }
                                                     [winningNumbersParser parseResults:data];
                                                 } else {
                                                     NSLog(@"Error in connecting %@", error);
                                                     [self showAlert: @"No Network" withContent:@"Could not connect to lottery site. Please try again"];
                                                 }
                                             }];
    [dataTask resume];
    while (([winningNumbersParser getWinningNumbers] == nil) && ([winningNumbersParser getPrizes] == nil)) {
        [NSThread sleepForTimeInterval:0.3f];
    }
    self.winningNumbersArray = [winningNumbersParser getWinningNumbers];
    NSLog(@"Winning numbers: %@", self.winningNumbersArray);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.spinner stopAnimating];
        [self.number1 setText:self.winningNumbersArray[0]];
        [self.number2 setText:self.winningNumbersArray[1]];
        [self.number3 setText:self.winningNumbersArray[2]];
        [self.number4 setText:self.winningNumbersArray[3]];
        [self.number5 setText:self.winningNumbersArray[4]];
        [self.number6 setText:self.winningNumbersArray[5]];
        [self.extraNumber setText:self.winningNumbersArray[6]];
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
    self.NSNumberTotalWins = 0;
    [self.totalWins setText: @""];
    self.NSNumberTotalNetbetWins = 0;
    [self.netbetWins setText: @""];
    for (UITextField* number in self.UITextFieldNumbersArray) {
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
