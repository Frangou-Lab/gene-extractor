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

#import "GeneExtractor.h"
#import "CSVUtils.h"

void error(const char *);

@implementation GeneExtractor
{
    StringInputStreamObj *m_ref, *m_coord;
    FILE *m_out;
    NSMutableDictionary<NSString *, NSString *> *m_seq;
}

- (id)initWithReference:(StringInputStreamObj *)ref coordinates:(StringInputStreamObj *)coord output:(FILE *)output
{
    if (self = [super init])
    {
        m_ref = ref;
        m_coord = coord;
        m_out = output;
    }
    return self;
}

- (void)readReference
{
    printf("Reading reference file...\n");
    
    NSString *str = [m_ref readLine];
    if (!str)
        error("Empty reference file");
    
    // NSArray<NSString *> *columns = [CSVUtils componentsFromString:str separatedByString:@","]; // TODO: may be used later
    
    m_seq = [[NSMutableDictionary alloc] init];
    
    while (1)
    {
        str = [m_ref readLine];
        if (!str)
            break;
        NSArray *vals = [CSVUtils componentsFromString:str separatedByString:@","];
        if ([vals count] < 2)
            continue;
        m_seq[vals[0]] = vals[1];
    }
    m_ref = nil;
}

- (void)process:(BOOL)mask
{
    [self readReference];
    
    NSString *str = [m_coord readLine];
    if (!str)
        error("Empty co-ordinates file");
    
    NSArray *columns = [CSVUtils componentsFromString:str separatedByString:@","];
    
    int startCol = -1, endCol = -1, minCols = -1;
    
    // Find start and end columns
    for (int i = 0; i < [columns count]; i++)
    {
        NSString *col = [columns[i] lowercaseString];
        if ([col compare:@"start"] == NSOrderedSame)
        {
            startCol = i;
            if (i > minCols)
                minCols = i;
        }
        if ([col compare:@"end"] == NSOrderedSame)
        {
            endCol = i;
            if (i > minCols)
                minCols = i;
        }
    }
    
    if (startCol < 0)
        error("Can't find start column in co-ordinates file");
    if (endCol < 0)
        error("Can't find end column in co-ordinates file");

    if (mask)
        printf("Masking...\n");
    else
        printf("Extracting...\n");
    
    fprintf(m_out, "%s,%s\n", str.UTF8String, "Extracted");
 
    long counter = 0;
    size_t buf_len = 16384;
    char *buf = (char *)malloc(buf_len);
    
    NSDate *start = [NSDate date];
    
    while (1)
    {
        str = [m_coord readLine];
        if (!str)
            break;
        
        ++counter;
        
        const char *c_str = str.UTF8String;
        if (strlen(c_str) + 1 > buf_len) // Grow buffer
        {
            buf_len = strlen(c_str) + 1;
            buf = (char *)realloc(buf, buf_len);
        }
        strcpy(buf, c_str);
        
        fprintf(m_out, "%s,", c_str);
        
        // We need here: 1st column and start, end columns
        NSString *key = nil;
        int64_t start = -1, end = -1;
        
        int column = 0;
        int64_t length = strlen(buf);
        char *pch = buf;
        while (pch - buf < length)
        {
            // Find next ",", ignoring """
            bool escaping = false;
            char *p_next = pch;
            while (*p_next)
            {
                if (*p_next == ',')
                {
                    if (!escaping)
                    {
                        *p_next = 0;
                        break;
                    }
                } else if (*p_next == '"')
                    escaping = !escaping;
                ++p_next;
            }
            
            if (column == 0)
                key = [NSString stringWithUTF8String:pch];
            else if (column == startCol)
                start = atoi(pch);
            else if (column == endCol)
                end = atoi(pch);
            else if (column > minCols)
                break;
            pch = p_next + 1;
            ++column;
        }
        
        if (!key || start < 0 || end < 0)
        {
            fprintf(m_out, "\n");
            continue;
        }
        
        NSString *gene = m_seq[key];
        if (gene == nil)
        {
            fprintf(m_out, "\n");
            continue;
        }
        
        if (end < start)
            end = start;
        
        if ([gene length] < start)
            continue;
        if (end >= [gene length])
            end = [gene length] - 1;
        
        if (mask) // Dump whole gene, replace start..end with 'N'
        {
            fprintf(m_out, "%s", [gene substringToIndex:start].UTF8String);
            for (int64_t i = start; i <= end; i++)
                fputc('N', m_out);
            fprintf(m_out, "%s\n", [gene substringFromIndex:end + 1].UTF8String);
        }
        else
            fprintf(m_out, "%s\n", [gene substringWithRange:NSMakeRange(start, end - start + 1)].UTF8String);
    }
    
    free(buf);
    fclose(m_out);
    
    NSTimeInterval elapsed = -[start timeIntervalSinceNow];
    
    printf("%ld lines processd in %.2f seconds (%.2f lines per second)\n", counter, elapsed, counter/elapsed);
}

@end
