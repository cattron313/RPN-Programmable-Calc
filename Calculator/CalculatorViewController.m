//
//  CalculatorViewController.m
//  Calculator
//
//  Created by Alexandria Cattron on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CalculatorViewController.h"
#import "CalculatorBrain.h"

@interface CalculatorViewController ()

@property (weak, nonatomic) IBOutlet UILabel *display;
@property (weak, nonatomic) IBOutlet UILabel *stackDisplay;
@property (weak, nonatomic) IBOutlet UILabel *displayVars;
@property (nonatomic) BOOL userIsInTheMiddleOfEnteringANumber;
@property (nonatomic) BOOL isDecimalPresentInNumber;
@property (nonatomic) BOOL wasUserLastActionOperation;
@property (nonatomic) BOOL areThereVarsInExpression;
@property (nonatomic, strong) CalculatorBrain* brain;
@property (nonatomic, strong) NSMutableDictionary* testVariableValues;
@end

@implementation CalculatorViewController

@synthesize display =_display;
@synthesize stackDisplay = _stackDisplay;
@synthesize displayVars = _displayVars;
@synthesize userIsInTheMiddleOfEnteringANumber = _userIsInTheMiddleOfEnteringANumber;
@synthesize isDecimalPresentInNumber = _isDecimalPresentInNumber;
@synthesize wasUserLastActionOperation = _wasUserLastActionOperation;
@synthesize areThereVarsInExpression = _areThereVarsInExpression;
@synthesize brain = _brain;
@synthesize testVariableValues = _testVariableValues;

- (CalculatorBrain *)brain
{
    if (!_brain) _brain = [[CalculatorBrain alloc] init];
    return _brain;
}

- (NSMutableDictionary*)testVariableValues
{
    if (!_testVariableValues) _testVariableValues = [[NSMutableDictionary alloc] init];
    return _testVariableValues;
}

/*
 *  Method: updateVariableLabel
 *  Constructs the varibale label based on what variables are being used in the program.
 *  Gets the correct values to display depending on what test the user has chosen.
 */

- (void) updateVariableLabel
{
    NSSet* variablesInProgram = [CalculatorBrain variablesUsedInProgram:self.brain.program];
    BOOL replacingVarDisplayContent = YES;
    NSString* key;
    NSEnumerator *enumerator = [variablesInProgram objectEnumerator];
    while ((key = [enumerator nextObject])) {
        NSString* value;
        if (!(value = [self.testVariableValues valueForKey:key])) value = @"0";
        if (replacingVarDisplayContent) {
            self.displayVars.text = [key stringByAppendingFormat:
                                     [NSString stringWithFormat:@" = %@", value]];
            replacingVarDisplayContent = NO;
        } else {
            self.displayVars.text = [self.displayVars.text stringByAppendingFormat:
                                     [NSString stringWithFormat:@"   %@ = %@", key, value]];
        }
    }   
}

- (IBAction)backspacePressed {
    //If the display is 0 then we don't want it to go blank.
    
    //Removes last digit
    if (self.userIsInTheMiddleOfEnteringANumber) {
        NSUInteger lastIndex = [self.display.text length] - 1;
        self.display.text = [self.display.text substringToIndex: lastIndex];
        
        //Checks if decimal was deleted from number and updates isDecimalPresentInNumber BOOL.
        NSRange range = [self.display.text rangeOfString:@"."];
        if (range.location == NSNotFound) self.isDecimalPresentInNumber = NO;
        
    } else {
        //When not removing digits you remove top item on stack.
        [self.brain removeTopOfStack];
        
        //If last operation was an equal sign you have to remove the equal sign first
        //and then re-append it later after running the program again.
        if (self.wasUserLastActionOperation) [self removeEqualSignFromEndOfStackLabel];
        double result = [CalculatorBrain runProgram:self.brain.program
                                usingVariableValues:self.testVariableValues];
        
        self.stackDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
        self.stackDisplay.text = [self.stackDisplay.text stringByAppendingString:@" ="];
        
        //Fixes a bug where "-0" would be displayed.
        if ([[[NSNumber numberWithDouble:result] stringValue] isEqualToString:@"-0"]) {
            result = 0;
        }
        self.display.text = [NSString stringWithFormat:@"%g", result];
        self.wasUserLastActionOperation = YES;
            
        [self updateVariableLabel];
            
    }
        
    //Handles edge cases where display text maybe be empty, left with a
    //lone zero, or a negation edge case.  These are cases where the user is not in the middle of
    //typing and we want to make sure a "0" is displayed.
    if ([self.display.text isEqualToString:@""] || [self.display.text isEqualToString:@"0"] ||
        [self.display.text isEqualToString:@"-"] || [self.display.text isEqualToString:@"-0."]) {
        self.display.text = @"0";
        self.userIsInTheMiddleOfEnteringANumber = NO;
    }
}

- (IBAction)digitPressed:(UIButton *)sender
{
    NSString* digit = sender.currentTitle;
    
    //Prevents edge case where user starts with a 0 and continues entering 0s.
    if (!([self.display.text isEqualToString:@"0"] && [digit isEqualToString:@"0"])) {
        if (self.userIsInTheMiddleOfEnteringANumber) {
            self.display.text = [self.display.text stringByAppendingString:digit];
        } else {
            self.display.text = digit;
            self.userIsInTheMiddleOfEnteringANumber = YES;
        }
    }
}

/*
 *  Method: decimalPressed
 *  Allows user to create decimal numbers.  Appends a "0" to the front of the string if
 *  user is not currently entering a number.  Only allows decimal to be entered into number
 *  once.
 */
- (IBAction)decimalPressed
{
    if (!self.isDecimalPresentInNumber) {
        if (!self.userIsInTheMiddleOfEnteringANumber) self.display.text = @"0";
        self.display.text = [self.display.text stringByAppendingString:@"."];
        self.isDecimalPresentInNumber = YES;
        self.userIsInTheMiddleOfEnteringANumber = YES;
    }
}

/*
 *  Method: updateStackLabelWith
 *  This method checks to see if the inital display text is present 
 *  then displays the user's input that has been sent to the brain.
 *  The initial text also serves to let the user know when the stack
 *  is empty.
 */

- (IBAction)clearPressed
{
    self.wasUserLastActionOperation = NO;
    self.userIsInTheMiddleOfEnteringANumber = NO;
    self.isDecimalPresentInNumber = NO;
    self.areThereVarsInExpression = NO;
    self.display.text = @"0";
    self.stackDisplay.text = @"Calculator history";
    self.displayVars.text = @"No variables";
    [self.brain clearStack];
    
}

- (void)removeEqualSignFromEndOfStackLabel
{
    if (self.wasUserLastActionOperation) {
        NSInteger lastIndex = [self.stackDisplay.text length] - 2;
        if (lastIndex >= 0) {
            self.stackDisplay.text = [self.stackDisplay.text substringToIndex: lastIndex];
        }
    }
}

- (IBAction)enterPressed
{  
    [self removeEqualSignFromEndOfStackLabel];
    [self.brain pushOperand:[NSNumber numberWithDouble:[self.display.text doubleValue]]];
    self.stackDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
    self.userIsInTheMiddleOfEnteringANumber = NO;
    self.isDecimalPresentInNumber = NO;
    self.wasUserLastActionOperation = NO;
}

- (IBAction)operationPressed:(UIButton *)sender
{
    if (self.userIsInTheMiddleOfEnteringANumber) [self enterPressed];
    else [self removeEqualSignFromEndOfStackLabel];
    
    NSString* operation = sender.currentTitle;
    [self.brain pushOperand:operation];
    
    double result = [CalculatorBrain runProgram:self.brain.program
                            usingVariableValues:self.testVariableValues];
    
    self.stackDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
    self.stackDisplay.text = [self.stackDisplay.text stringByAppendingString:@" ="];
    
    //Fixes a bug where "-0" would be displayed.
    if ([[[NSNumber numberWithDouble:result] stringValue] isEqualToString:@"-0"]) {
        result = 0;
    }
    self.display.text = [NSString stringWithFormat:@"%g", result];
    self.wasUserLastActionOperation = YES;
}

- (IBAction)negationPressed:(UIButton *)sender
{
    if (self.userIsInTheMiddleOfEnteringANumber) {
        if ([self.display.text doubleValue] > 0) {
            self.display.text = [@"-" stringByAppendingString:self.display.text];
        } else if ([self.display.text doubleValue] < 0) {
            self.display.text = [self.display.text substringFromIndex:1];
        }
    } else [self operationPressed:(UIButton *)sender];
}

- (IBAction)variablePressed:(UIButton *)sender
{
    if (self.userIsInTheMiddleOfEnteringANumber) [self enterPressed];
    self.display.text = sender.currentTitle;
    [self.brain pushOperand:sender.currentTitle];
    self.stackDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
    
    //Substitues nil for the value zero so display will be correct.
    NSString* value;
    if (!(value = [self.testVariableValues valueForKey:sender.currentTitle])) value = @"0";
    
    //Updates the variable label properly based on if it is currently displaying variables or not.
    if ([self.displayVars.text isEqualToString:@"No variables"]) {
        self.displayVars.text = [sender.currentTitle stringByAppendingFormat:[NSString stringWithFormat:@" = %@", value]];
    } else if([self.displayVars.text rangeOfString:sender.currentTitle].location == NSNotFound){
        self.displayVars.text = [self.displayVars.text stringByAppendingFormat:
                                [NSString stringWithFormat:@"   %@ = %@", sender.currentTitle, value]];
    }
    self.areThereVarsInExpression = YES;
}

- (IBAction)testPressed:(UIButton *)sender
{
    if ([sender.currentTitle isEqualToString:@"Test 1"]) {
        self.testVariableValues = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithDouble:-2], @"a", [NSNumber numberWithDouble:6.7], @"b", [NSNumber numberWithDouble:39], @"c", nil];
    } else if ([sender.currentTitle isEqualToString:@"Test 2"]) {
        self.testVariableValues = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithDouble:-7.3], @"a", [NSNumber numberWithDouble:8], @"b", [NSNumber numberWithDouble:0.4], @"c", nil];
    } else if ([sender.currentTitle isEqualToString:@"Test 3"]) {
        self.testVariableValues = nil;
    }
    
    [self updateVariableLabel];
     
     
    //After changing the variables, you must re-running the program.
    if (self.userIsInTheMiddleOfEnteringANumber) [self enterPressed];
    else [self removeEqualSignFromEndOfStackLabel];
    double result = [CalculatorBrain runProgram:self.brain.program
                            usingVariableValues:self.testVariableValues];
    
    self.stackDisplay.text = [CalculatorBrain descriptionOfProgram:self.brain.program];
    self.stackDisplay.text = [self.stackDisplay.text stringByAppendingString:@" ="];
    
    //Fixes a bug where "-0" would be displayed.
    if ([[[NSNumber numberWithDouble:result] stringValue] isEqualToString:@"-0"]) {
        result = 0;
    }
    self.display.text = [NSString stringWithFormat:@"%g", result];
    self.wasUserLastActionOperation = YES;
}

- (void)viewDidUnload {
    [self setStackDisplay:nil];
    [self setDisplayVars:nil];
    [super viewDidUnload];
}
@end
