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

#import "StringInputStreamObj.h"

#include <algorithm>

@implementation StringInputStreamObj

@synthesize name = _name;

-(id)initWithFileName:(const char *)file
{
	if (self = [super init])
	{
        _name = [NSString stringWithUTF8String:file];
		m_pos = m_read = 0;
		m_file = fopen(file, "rt");
		if (!m_file)
        {
			return nil;
		}
        fseek(m_file, 0L, SEEK_END);
        m_length = ftell(m_file);
        fseek(m_file, 0L, SEEK_SET);
	}
	return self;
}

- (void)dealloc
{
	if (m_file)
		fclose(m_file);
}

-(long) length
{
	return m_length;
}

-(long)getPos
{
	return ftell(m_file)-m_read+m_pos;
}

-(void)setPos:(long)pos
{
	fseek(m_file, pos, SEEK_SET);
	m_read = m_pos = 0;
}

-(NSString *)readLine
{
	return [self readLineAndAdd: 0];
}
-(NSString *)readLineAndAdd:(char)ch
{
	NSMutableString *retStr = [NSMutableString stringWithCapacity:100];
	
	do 
	{
		if (m_pos < m_read) // Have something in buf
		{
			char *p1 = strchr(m_buf+m_pos, '\r');
			char *p2 = strchr(m_buf+m_pos, '\n');
			if (p1 || p2) // Found string
			{
				char *p;
				if (p1 && p2)
                    p = std::min(p1, p2);
				else if (p1)
					p = p1;
				else
					p = p2;
				
				*p = 0;
				NSString *ret =  [NSString stringWithCString:m_buf+m_pos encoding:NSUTF8StringEncoding];
				// eat all 0xd, 0xa
				m_pos = (int)(p-m_buf)+1;
				for (; m_pos < m_read; m_pos++)
					if (m_buf[m_pos] == '\r' || m_buf[m_pos] == '\n')
						m_buf[m_pos] = 0;
					else
						break;
				
				NSAssert(ret, @"nil result");
				[retStr appendString:ret];
				if ([retStr length] == 0)
					continue;
				if (ch)
					[retStr appendFormat:@"%c", ch];								
				return retStr;
			}
			// Add readed to ret and continue
			[retStr appendString: [NSString stringWithCString:m_buf+m_pos encoding:NSUTF8StringEncoding]];
		} 
        // Read more data
		m_pos = 0;
		m_read = (int)fread(m_buf, 1, BUFLEN, m_file);
		m_buf[m_read] = 0; // EOL
	} while (m_read);
	
	if ([retStr isEqualToString:@""]) // lAst
		return nil;
	if (ch)
		[retStr appendFormat:@"%c", ch];
	return retStr;
}

@end
