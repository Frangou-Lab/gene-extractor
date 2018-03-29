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

#import <Cocoa/Cocoa.h>

enum LexemeType
{
	Literal,
	Operator,
	EndOfExpression
};

@interface Lexer : NSObject {
	NSString *m_exp;
	int m_pos;
	NSArray* m_operators;
	NSCharacterSet* m_operatorChars;
	NSCharacterSet* m_whitespaceChars;
	enum LexemeType m_curType;
	int m_curOper;
	int m_lexemeStartPos;
	int m_lexemeLength;
	NSString *m_curLexeme;
}
@property(readwrite, retain) NSString* m_curLexeme;

-(id)initWithOperators: (NSArray*) operators;
-(id)initWithString: (NSString *)exp withOperators: (NSArray*) operators;

-(void)setExpression: (NSString *)exp;
-(bool)next;
-(bool)nextI;
-(void)formLexeme: (int) pos;
-(enum LexemeType)type;
-(NSString *)lexeme;
-(int)oper;
-(int)position;
-(NSString *)getTail;
-(int)lexemeStartPos;
-(int)lexemeLength;
@end
