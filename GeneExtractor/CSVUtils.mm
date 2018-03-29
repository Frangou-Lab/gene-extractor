/*
 * Copyright 2018 Frangou Lab
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#import "CSVUtils.h"
#import "Lexer.h"

static NSCharacterSet *escCharset = nil;

@implementation CSVUtils

+ (const char *)escapeCString:(char*)value
{
	NSString* toString = [NSString stringWithUTF8String:value];
	return [self escape:toString].UTF8String;
}

+ (const char *)escapeAndConvert2cString:(NSString *)value
{
	return [CSVUtils escape:value].UTF8String;
}

+ (NSString *)escape:(NSString *)value
{
    if (!escCharset)
        escCharset = [NSCharacterSet characterSetWithCharactersInString:@" \t\r\n,\""];
    
	NSRange r = [value rangeOfCharacterFromSet:escCharset];
	if (r.location != NSNotFound)
	{
		value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
		return [NSString stringWithFormat:@"\"%@\"", value];
	}
	return value;
}

+ (NSString *)firstComponentFromString:(NSString*)value separatedByString:(NSString *)delimiter
{
	Lexer* lexer = [[Lexer alloc] initWithString:value withOperators:@[delimiter]];
	enum LexemeType previousType = EndOfExpression;
	NSString* ret = nil;
	while ([lexer next])
	{
		if ([lexer type] == Literal)
		{
			ret = [lexer lexeme];
			break;
		}
		if (previousType != Literal && [lexer type] == Operator)
		{
			ret = @"";
			break;
		}
		previousType = [lexer type];
	}
	return ret;
}

+ (NSArray *)componentsFromString:(NSString *)value separatedByString:(NSString *)delimiter
{
	Lexer* lexer = [[Lexer alloc] initWithString:value withOperators:@[delimiter]];
	enum LexemeType previousType = EndOfExpression;
	NSMutableArray* components = [NSMutableArray array];
	while ([lexer next])
	{
		if ([lexer type] == Literal)
		{
			[components addObject:[lexer lexeme]];
		}
		if (previousType != Literal && [lexer type] == Operator)
		{
			[components addObject:@""];
		}
		previousType = [lexer type];
	}
	return components;
}

@end
