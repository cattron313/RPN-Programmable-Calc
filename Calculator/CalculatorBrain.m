//
//  CalculatorBrain.m
//  Calculator
//
//  Created by Alexandria Cattron on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CalculatorBrain.h"

@interface CalculatorBrain()

@property (nonatomic, strong) NSMutableArray* programStack;

@end

@implementation CalculatorBrain

@synthesize programStack = _programStack;
@synthesize program = _program;

- (NSMutableArray *)programStack
{
    if (!_programStack) {
        _programStack = [[NSMutableArray alloc] init];
    }
    return _programStack;
}

-(id)program
{
    return [self.programStack copy];
}

- (void)clearStack
{
    [self.programStack removeAllObjects];
}

- (void)removeTopOfStack
{
    id topOfStack = [self.programStack lastObject];
    if (topOfStack) [self.programStack removeLastObject];
}

- (void)pushOperand:(id)operand
{
    if ([operand isKindOfClass:[NSString class]] || [operand isKindOfClass:[NSNumber class]]) {
        [self.programStack addObject:operand];
    }        
}

- (double)performOperation:(NSString *)operation
{
    [self.programStack addObject:operation];
    return [[self class] runProgram:self.program];
}

+(double)popOperandOffProgramStack:(NSMutableArray *)stack
{
    double result = 0;
    
    id topOfStack = [stack lastObject];
    if (topOfStack) [stack removeLastObject];
    
    if ([topOfStack isKindOfClass:[NSNumber class]])
    {
        result = [topOfStack doubleValue];
    }
    else if ([topOfStack isKindOfClass:[NSString class]])
    {
        
        NSString *operation = topOfStack;
        if ([operation isEqualToString:@"+"]) {
            result = [self popOperandOffProgramStack:stack] + 
                     [self popOperandOffProgramStack:stack];
        } else if ([operation isEqualToString:@"*"]) {
            result = [self popOperandOffProgramStack:stack] *
                     [self popOperandOffProgramStack:stack];
        } else if ([operation isEqualToString:@"-"]) {
            result = - [self popOperandOffProgramStack:stack] +
                       [self popOperandOffProgramStack:stack];
        } else if ([operation isEqualToString:@"/"]) {
            double divisor = [self popOperandOffProgramStack:stack];
            if (divisor) result = [self popOperandOffProgramStack:stack] / divisor;
        } else if ([operation isEqualToString:@"sin"]) {
            result = sin([self popOperandOffProgramStack:stack]);
        } else if ([operation isEqualToString:@"cos"]) {
            result = cos([self popOperandOffProgramStack:stack]);
        } else if ([operation isEqualToString:@"sqrt"]) {
            double radicand = [self popOperandOffProgramStack:stack];
            if (radicand >= 0) result = sqrt(radicand);
        } else if ([operation isEqualToString:@"π"]) {
            result = M_PI;
        } else if ([operation isEqualToString:@"+/-"]) {
            result = -1 * [self popOperandOffProgramStack:stack];
        }
    }   
    
    return result;
}

+ (double)runProgram:(id)program
{
    NSMutableArray* stack;
    if ([program isKindOfClass:[NSArray class]]) {
        stack = [program mutableCopy];
    }
    return [self popOperandOffProgramStack:stack];
}

+(NSSet *)variablesUsedInProgram:(id)program
{
    NSMutableSet* set = [[NSSet set] mutableCopy];
    if ([program isKindOfClass:[NSArray class]]) {
        NSArray* array = program;
        for (id obj in array) {
            if ([obj isKindOfClass:[NSString class]] && ([(NSString*)obj isEqualToString:@"a"] || [(NSString*)obj isEqualToString:@"b"] || [(NSString*)obj isEqualToString:@"c"])) {
                [set addObject:obj];
            }
        }
    }
    
    if ([set count] == 0) return nil;
    else return [set copy];
}

+ (double)runProgram:(id)program usingVariableValues:(NSDictionary*)variableValues
{
    NSMutableArray* stack;
    if ([program isKindOfClass:[NSArray class]]) 
    {
        stack = [program mutableCopy];
    
        for (int i = 0; i < [stack count]; i++) {
            id stackItem = [stack objectAtIndex:i];
            NSSet* variablesInProgram = [self variablesUsedInProgram:program];
            if ([variablesInProgram containsObject:stackItem])
            {
                id value = [variableValues objectForKey:stackItem];
                if (value) [stack replaceObjectAtIndex:i withObject:value];
                else [stack replaceObjectAtIndex:i withObject:[NSNumber numberWithDouble:0]];
            }
        }
    }
    return [self popOperandOffProgramStack:stack];
}



+ (NSString *)generateExpression: (NSMutableArray *)stack
{
    NSString* description = @"";
    
    id topOfStack = [stack lastObject];
    if (topOfStack) [stack removeLastObject];
    
    if ([topOfStack isKindOfClass:[NSNumber class]] || ([topOfStack isKindOfClass:[NSString class]] &&
        ([topOfStack isEqualToString:@"a"] || [topOfStack isEqualToString:@"b"] || [topOfStack isEqualToString:@"c"])))
    {
        description = [topOfStack description];
    }
    else if ([topOfStack isKindOfClass:[NSString class]])
    {
        
        NSString *operation = topOfStack;
        
        if ([operation isEqualToString:@"-"] || [operation isEqualToString:@"/"] ||
            [operation isEqualToString:@"+"] || [operation isEqualToString:@"*"])
        {
            NSString *secondArgument = [self generateExpression:stack];
            description = [@"(" stringByAppendingFormat:[NSString stringWithFormat:@"%@ %@ %@)",
                          [self generateExpression:stack], operation, secondArgument]];
        }
        else if ([operation isEqualToString:@"sin"] || [operation isEqualToString:@"cos"] ||
                   [operation isEqualToString:@"sqrt"])
        {
            NSString* currentExpression = [self generateExpression:stack];
            if ([currentExpression hasPrefix:@"("] && [currentExpression hasSuffix:@")"]) {
                description = [operation stringByAppendingString:currentExpression];
            } else {
                description = [operation stringByAppendingFormat:[NSString stringWithFormat:@"(%@)", currentExpression]];
            }
        }
        else if ([operation isEqualToString:@"π"])
        {
            description = operation;
        }
        else if ([operation isEqualToString:@"+/-"])
        {
            description = [@"-" stringByAppendingString:[self generateExpression:stack]];
        }
    }
    
    return description;
}


+ (NSString *)removeExtraneousParentheses:(NSString*)unformattedDescription
{
    if ([unformattedDescription hasPrefix:@"("] && [unformattedDescription hasSuffix:@")"]) {
        unformattedDescription = [[unformattedDescription substringToIndex:([unformattedDescription length] - 1)] substringFromIndex:1];
    }
    
    return unformattedDescription;
}

+ (NSString *)descriptionOfProgram:(id)program
{

    NSMutableArray* stack;
    if ([program isKindOfClass:[NSArray class]]) {
        stack = [program mutableCopy];
    }
    NSString* descriptionOfEntireStack = [self removeExtraneousParentheses:[self generateExpression:stack]];
    while ([stack lastObject]) {
        NSString* descriptionOfExpression = [self removeExtraneousParentheses:[self generateExpression:stack]];
        descriptionOfEntireStack = [descriptionOfEntireStack stringByAppendingFormat:
                                    [NSString stringWithFormat:@", %@", descriptionOfExpression]];
    }
    return descriptionOfEntireStack;
}

@end
