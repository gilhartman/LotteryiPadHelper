//
//  ViewController.h
//  LotteryiPadHelper
//
//  Created by Gil on 5/27/17.
//  Copyright © 2017 Hartman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSXMLParserDelegate, UITextFieldDelegate>


- (void) initXmlParser: (NSURL*) filePath;
@end

