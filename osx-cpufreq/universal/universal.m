//
//    MIT License
//
//    Copyright (c) 2021-2022 BitesPotatoBacks
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//

#include <Foundation/Foundation.h>
#include "universal.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

int get_sysctl_int(char * entry)
{
    int variable;
    size_t len = 4;
    
    if (sysctlbyname(entry, &variable, &len, NULL, 0) == -1)
    {
        //perror("read");
        ERROR("invalid output from sysctl");
    }
    else
    {
        sysctlbyname(entry, &variable, &len, NULL, 0);
        return variable;
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

char * get_sysctl_string(char * entry)
{
    char * variable;
    size_t len;
    
    if (sysctlbyname(entry, NULL, &len, NULL, 0) == -1)
    {
        ERROR("invalid output from sysctl");
    }
    else
    {
        variable = malloc(len);
        
        sysctlbyname(entry, variable, &len, NULL, 0);
        return variable;
    }
}
