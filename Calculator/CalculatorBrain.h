//
//  CalculatorBrain.h
//  Calculator
//
//  Created by Alexandria Cattron on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CalculatorBrain : NSObject

- (void)pushOperand:(id)operand;
- (double)performOperation:(NSString *)operation;
- (void)clearStack;
- (void)removeTopOfStack;

@property (nonatomic, readonly) id program;

+ (NSString *)descriptionOfProgram:(id)program;
+ (double)runProgram:(id)program;
+ (double)runProgram:(id)program usingVariableValues:(NSDictionary*)variableValue;
+ (NSSet *)variablesUsedInProgram:(id)program;
@end
