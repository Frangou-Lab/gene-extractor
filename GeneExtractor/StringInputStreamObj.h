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

#define BUFLEN 4096

@interface StringInputStreamObj : NSObject
{
	FILE *m_file;
	char m_buf[BUFLEN+1];
	int m_pos, m_read;
	long m_length;
    
    NSString *_name;
}

@property (readonly) NSString *name;

-(id)initWithFileName:(const char *)file;
-(NSString *)readLineAndAdd:(char)ch;
-(NSString *)readLine;
-(long)getPos;
-(void)setPos:(long)pos;
-(long) length;

@end
