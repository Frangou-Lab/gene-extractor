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
#import "GeneExtractor.h"

#import <cstdio>

@implementation NSString(extension)

- (NSString *)appendSuffixToPath:(NSString *)pSuffix
{
    NSString * fileExtension = [self pathExtension];
    NSString * fileName = [self stringByDeletingPathExtension];
    
    NSString * newFileName = [fileName stringByAppendingString:pSuffix];
    NSString * newFullFileName = [newFileName stringByAppendingPathExtension:fileExtension];
    return newFullFileName;
}

@end

void help()
{
    printf("Gene Extractor v1.02\n");
    printf("Usage: geneextractor [-m] <reference file> <coordinate file> [output_file]\n");
    printf(" -m extract whole sequence but mask meaningful characters with N\n");
    exit(1);
}

void error(const char* text)
{
    printf("%s\n", text);
    exit(2);
}

int main(int argc, const char * argv[])
{
    @autoreleasepool
    {
        if (argc < 3)
            help();
        
        bool mask = false;
        int curArg = 1;
        for (;curArg < argc; curArg++)
        {
            if (argv[curArg][0] != '-')
                break;
            
            if (strlen(argv[curArg]) == 2 && argv[curArg][1] == 'm')
            {
                mask = true;
                continue;
            }
            printf("Warning: unknown flag %s, ignoring...\n", argv[curArg]);
        }
        
        if (argc - curArg < 2)
            help();
        
        StringInputStreamObj *ref = [[StringInputStreamObj alloc] initWithFileName:argv[curArg++]];
        if (!ref)
            error("Can't open reference file");
        
        StringInputStreamObj *coord = [[StringInputStreamObj alloc] initWithFileName:argv[curArg++]];
        if (!coord)
            error("Can't open co-ordinate file");
        
        NSString *outname;
        
        if (curArg < argc) // Have output
            outname = [NSString stringWithUTF8String:argv[curArg]];
        else // Construct
            outname = [[NSString stringWithUTF8String:argv[curArg - 1]] appendSuffixToPath:@"_extracted"];
        
        FILE *outfile = fopen(outname.UTF8String, "wt");
        
        if (!outfile)
            error("Can't create output file");
        
        GeneExtractor *extr = [[GeneExtractor alloc] initWithReference:ref coordinates:coord output:outfile];
        [extr process:mask];
    }
    return 0;
}
