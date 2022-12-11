//
//  stringUtliTests.m
//  voiceboxTests
//
//  Created by Steve Cosman on 2022-12-10.
//

#import <XCTest/XCTest.h>

#import "VBStringUtils.h"

@interface stringUtliTests : XCTestCase

@end

@implementation stringUtliTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

-(void) lastPartialHelper:(NSString*)text withExpected:(NSString*)expected {
    NSString* lastPartial = [VBStringUtils lastPartialSentenceFromString:text];
    BOOL pass = [lastPartial isEqualToString:expected] || (lastPartial == nil && expected == nil);
    XCTAssertTrue(pass,
                   @"lastPartialSentenceFromString failed for: '%@'\n  expected: '%@'\n  actual: '%@'", text, expected, lastPartial);
}

- (void)testLastPartialSentenceInString {
    NSString *text, *expected;
    
    text = @"Not terminated";
    expected = @"Not terminated";
    [self lastPartialHelper:text withExpected:expected];
    
    text = @"First. Second partial";
    expected = @"Second partial";
    [self lastPartialHelper:text withExpected:expected];
    
    text = @"";
    expected = nil;
    [self lastPartialHelper:text withExpected:expected];
}

- (void)testTextEndsInCompleteSentence {
    NSString* text;
    
    text = @"Not ending in sentence";
    XCTAssertFalse([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    text = @"  Not ending in sentence with trailing space ";
    XCTAssertFalse([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    text = @"  Not ending in sentence with trailing tab\t";
    XCTAssertFalse([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    text = @"Not ending in sentence with trailing other punctuation,";
    XCTAssertFalse([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    text = @"Not ending in sentence with nl\n";
    XCTAssertFalse([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    text = @"";
    XCTAssertFalse([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    
    text = @"Ending with sentence terminator period.";
    XCTAssertTrue([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    text = @"Ending with sentence terminator exclamation point!";
    XCTAssertTrue([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    text = @"Ending with sentence terminator question mark?";
    XCTAssertTrue([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    text = @"Ending with sentence terminator semi-colon;";
    XCTAssertTrue([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    text = @"Ending with sentence terminator period and trailing space. ";
    XCTAssertTrue([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    text = @" Ending with sentence terminator period and trailing spaces.  ";
    XCTAssertTrue([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    text = @"\tEnding with sentence terminator period and trailing tab.\t";
    XCTAssertTrue([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    text = @"\nEnding with sentence with newlines.\n";
    XCTAssertTrue([VBStringUtils endsInCompleteSentence:text],
                   @"endsInCompleteSentence failed for: %@", text);
    
}

-(void) truncateHelper:(NSString*)first wS:(NSString*)second wE:(NSString*)expected {
    NSString* truncated = [VBStringUtils truncateStringsAddingSpaceBetweenAndTrailingIfNeeded:first withSecondString:second];
    BOOL pass = [expected isEqualToString:truncated];
    
    XCTAssertTrue(pass, @"truncated with whitespace failed for:\n  first: '%@'\n  second '%@'\n  expected: '%@'\n  actual:'%@'", first, second, expected, truncated);
}

- (void)testTruncatingStringsWithWhitespace {
    NSString* first, *second, *expected;
    
    first = @"First.";
    second = @"Second.";
    expected = @"First. Second. ";
    [self truncateHelper:first wS:second wE:expected];
    
    first = @"First.";
    second = @"Second";
    expected = @"First. Second ";
    [self truncateHelper:first wS:second wE:expected];
    
    first = @"First. ";
    second = @"Second.";
    expected = @"First. Second. ";
    [self truncateHelper:first wS:second wE:expected];
    
    first = @"First.";
    second = @" Second.";
    expected = @"First. Second. ";
    [self truncateHelper:first wS:second wE:expected];
    
    first = @"First.\n";
    second = @"Second.";
    expected = @"First.\nSecond. ";
    [self truncateHelper:first wS:second wE:expected];
    
    first = @"First.\t";
    second = @"Second.";
    expected = @"First.\tSecond. ";
    [self truncateHelper:first wS:second wE:expected];
    
    first = @"First.";
    second = @"\nSecond.";
    expected = @"First.\nSecond. ";
    [self truncateHelper:first wS:second wE:expected];
    
    first = @"First.";
    second = @"Second.  ";
    expected = @"First. Second.  ";
    [self truncateHelper:first wS:second wE:expected];
    
    first = @"\n\nFirst.\n\t";
    second = @"\nSecond. \n ";
    expected = @"\n\nFirst.\n\t\nSecond. \n ";
    [self truncateHelper:first wS:second wE:expected];

    first = @"";
    second = @"";
    expected = @" ";
    [self truncateHelper:first wS:second wE:expected];
    
    first = @"";
    second = @"Hello.";
    expected = @"Hello. ";
    [self truncateHelper:first wS:second wE:expected];
    
    first = @"Hello.";
    second = @"";
    expected = @"Hello. ";
    [self truncateHelper:first wS:second wE:expected];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
