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

#import "Lexer.h"


@implementation Lexer
@synthesize m_curLexeme;
-(id) initWithOperators: (NSArray*) operators
{
	if (self = [super init])
	{
		m_exp = nil;
        m_operators = operators;
        m_whitespaceChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		NSMutableCharacterSet* allOperatorChars = [[NSMutableCharacterSet alloc] init];
		for (NSString* oper in m_operators)
		{
			[allOperatorChars addCharactersInString:oper];
		}
		m_operatorChars = allOperatorChars;
	}
	return self;
}

-(id)initWithString: (NSString *)exp withOperators: (NSArray*) operators
{
	if (self = [self initWithOperators: operators])
	{
        [self setExpression:exp];
	}
	return self;
}

-(void)setExpression: (NSString *)exp
{
    m_exp = [[NSString alloc] initWithFormat:@"%@ ", exp]; // Add space to end
    m_pos = 0;
    
}

-(enum LexemeType)type
{
	return m_curType;
}

-(NSString *)lexeme
{
	return m_curLexeme;
}

-(int)oper
{
	return m_curOper;
}

-(int) lexemeStartPos
{
	return m_lexemeStartPos;
}

-(int) lexemeLength
{
	return m_lexemeLength;
}

-(unichar) characterAtPos: (int) pos
{
	return [m_exp characterAtIndex: pos];
}
-(int) length
{
	return (int)[m_exp length];
}
-(void)formLexeme: (int) pos
{
	m_lexemeStartPos = m_pos;
	m_lexemeLength = pos - m_pos;
	NSString* lexeme = [m_exp substringWithRange:NSMakeRange(m_lexemeStartPos, m_lexemeLength)];
	self.m_curLexeme = [lexeme stringByReplacingOccurrencesOfString: @"\"\"" withString: @"\""];
	m_pos = pos;
}
-(void) trimLexeme
{
	while (m_lexemeLength > 0 && [m_whitespaceChars characterIsMember: [self characterAtPos: m_lexemeStartPos]]) 
	{
		m_lexemeStartPos++;
		m_lexemeLength--;
	}
	while (m_lexemeLength > 0 && [m_whitespaceChars characterIsMember: [self characterAtPos: m_lexemeStartPos + m_lexemeLength - 1]])
	{
		m_lexemeLength--;
	}	
	NSString* lexeme = [m_exp substringWithRange:NSMakeRange(m_lexemeStartPos, m_lexemeLength)];
	self.m_curLexeme = [lexeme stringByReplacingOccurrencesOfString: @"\"\"" withString: @"\""];
}
-(bool)nextI
{
	m_lexemeStartPos = 0;
	m_lexemeLength = 0;
	bool escaping = NO;
	for (; m_pos < [self length]; ++m_pos) // Skip whitespace
	{
		unichar ch = [self characterAtPos: m_pos];
        
        if ([m_operatorChars characterIsMember: ch])
            break; // TODO: workaround - whitespace as separator
        
		if (![m_whitespaceChars characterIsMember: ch])
			break;
	}
	if (m_pos >= [self length])
	{
		m_curType = EndOfExpression;
		return NO;
	}
	if ([m_operatorChars characterIsMember: [self characterAtPos: m_pos]])
	{
		m_curType = Operator;
		int curOper = -1;
		// Do operators lexing
		for (int pos = m_pos+1; pos <= [self length]; ++pos)
		{
			int oper = -1;
			for (NSUInteger i = 0; i < [m_operators count]; i++)
			{
				NSString* operator_ = [m_operators objectAtIndex: i];
				if (NSOrderedSame == [operator_ caseInsensitiveCompare: [m_exp substringWithRange:NSMakeRange(m_pos, pos-m_pos)]])
				{
					oper = (int)i;
				}
			}
			if (oper != -1)
				curOper = oper;
			else 
			{
				m_pos = pos-1;
				m_curOper = curOper;
				return YES;
			}
		}
		m_pos = [self length];
		m_curOper = curOper;
		return YES;
	}
	else
		m_curType = Literal;
	for (int pos = m_pos; pos < [self length]; ++pos)
	{
		char ch = [self characterAtPos: pos];
		if (ch == '\"')
		{
			if (!escaping)
			{
				escaping = YES;
				continue;
			}
			if ((pos + 1 < [self length]) && ('\"' == [self characterAtPos: pos + 1])) 
			{
				pos++;
				continue;
			}
			++m_pos;
			[self formLexeme: pos];
			++m_pos;
			return YES;
		}
		if (escaping)
			continue;
		if (/*[m_whitespaceChars characterIsMember: ch] ||*/ [m_operatorChars  characterIsMember: ch])
		{
			[self formLexeme:pos];
			[self trimLexeme];
			return YES;
		}
	}
	// Seems unfinished escape, finish it
	[self formLexeme: [self length]-1];
	return YES;
}

-(bool)next
{
	return [self nextI];
}

-(NSString *)getTail
{
	if (m_pos >= [self length])
		return @"end of expression";
	return [m_exp substringFromIndex:m_pos];
}
-(int)position
{
	return m_pos;
}
@end
