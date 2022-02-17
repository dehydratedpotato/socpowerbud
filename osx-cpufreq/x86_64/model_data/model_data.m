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

#if defined(__x86_64__)

#include <Foundation/Foundation.h>
#include "model_data.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSDictionary * generate_macbook_data(void)
{
    return @{
                                            
        @"M-5Y31" : @2400,
        @"M-5Y51" : @2600,
        @"M-5Y71" : @2900,
        
        @"M3-6Y30" : @2200,
        @"M3-7Y32" : @3000,
        @"M5-6Y54" : @2700,
        @"M7-6Y75" : @3100,
        
        @"i5-7Y54" : @3200,
        @"i7-7Y75" : @3600,
    };
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSDictionary * generate_macbook_air_data(void)
{
    return @{
                                            
        @"i5-3317U" : @2600,
        @"i5-3427U" : @2800,
        @"i7-3667U" : @3200,
        
        @"i5-4250U" : @2600,
        @"i5-4260U" : @2700,
        @"i7-4650U" : @3300,
        
        @"i5-5250U" : @2700,
        @"i5-5350U" : @2900,
        @"i7-5650U" : @3200,
        
        @"i5-8210Y" : @3600,
        
        @"i3-1000NG4" : @3200,
        @"i5-1030NG7" : @3500,
        @"i7-1060NG7" : @3800
    };
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSDictionary * generate_macbook_pro_data(void)
{
    return @{
                                            
        @"i5-3210M" : @3100,
        @"i5-3230M" : @3200,
        @"i7-2620M" : @3400,
        @"i7-3520M" : @3600,
        @"i7-3540M" : @3700,
        @"i7-3615QM" : @3300,
        @"i7-3720QM" : @3600,
        @"i7-3820QM" : @3700,
        @"i7-3635QM" : @3400,
        @"i7-3840QM" : @3800,
                                            
        @"i5-4258U" : @2900,
        @"i5-4288U" : @3100,
        @"i5-4278U" : @3100,
        @"i5-4308U" : @3300,
        @"i7-4558U" : @3300,
        @"i7-4578U" : @3500,
        @"i7-4750HQ" : @3200,
        @"i7-4850HQ" : @3500,
        @"i7-4960HQ" : @3800,
        @"i7-4770HQ" : @3400,
        @"i7-4870HQ" : @3700,
        @"i7-4980HQ" : @4000,
                                 
        @"i5-5257U" : @3100,
        @"i5-5287U" : @3300,
        @"i7-5557U" : @3400,
                                 
        @"i5-6360U" : @3100,
        @"i5-6267U" : @3300,
        @"i5-6287U" : @3500,
        @"i7-6660U" : @3400,
        @"i7-6567U" : @3600,
        @"i7-6700HQ" : @3500,
        @"i7-6820HQ" : @3600,
        @"i7-6920HQ" : @3800,
                                        
        @"i5-7360U" : @3600,
        @"i5-7267U" : @3500,
        @"i5-7287U" : @3700,
        @"i7-7660U" : @4000,
        @"i7-7567U" : @4000,
        @"i7-7700HQ" : @3800,
        @"i7-7820HQ" : @3900,
        @"i7-7920HQ" : @4100,
                                        
        @"i5-8257U" : @3900,
        @"i5-8279U" : @4100,
        @"i5-8259U" : @3800,
        @"i7-8569U" : @4700,
        @"i7-8557U" : @4500,
        @"i7-8559U" : @4500,
        @"i7-8750H" : @4100,
        @"i7-8850H" : @4300,
        @"i9-8950HK" : @4800,
                                        
        @"i7-9750H" : @4500,
        @"i9-9880H" : @4800,
        @"i9-9980HK" : @5000,
                                        
        @"i5-1038NG7" : @3800,
        @"i7-1068NG7" : @4100
    };
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSDictionary * generate_imac_data(void)
{
    return @{
        
        @"i3-3225" : @3300,
        @"i5-3330S" : @3200,
        @"i5-3470S" : @3600,
        @"i5-3470" : @3600,
        @"i7-3770S" : @3900,
        @"i7-3770" : @3900,
        
        @"i5-4570" : @3600,
        @"i5-4670" : @3800,
        @"i5-4690" : @3900,
        @"i5-4590" : @3700,
        @"i5-4260U" : @2700,
        @"i5-4570R" : @3200,
        @"i5-4570S" : @3600,
        @"i7-4770S" : @3900,
        @"i7-4790K" : @4400,
        @"i7-4771" : @3900,
        
        @"i5-6500" : @3600,
        @"i5-6600" : @3900,
        @"i7-6700K" : @4200,
        
        @"i5-7360U" : @3600,
        @"i5-7400" : @3500,
        @"i5-7500" : @3800,
        @"i5-7600" : @4100,
        @"i5-7600K" : @4200,
        @"i7-7700" : @4200,
        @"i7-7700K" : @4500,
        
        @"i3-8100" : @3600,
        @"i5-8500" : @4100,
        @"i5-8600" : @4300,
        @"i7-8700" : @4600,
        
        @"i5-9600K" : @4600,
        @"i9-9900K" : @5000,
        
        @"i5-10500" : @4500,
        @"i5-10600" : @4800,
        @"i7-10700K" : @5100,
        @"i9-10910" : @5000
    };
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSDictionary * generate_imac_pro_data(void)
{
    return @{
        
        @"W-2150B" : @3700,
        @"W-2140B" : @4200,
        @"W-2170B" : @4300,
        @"W-2191B" : @3400,
    };
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSDictionary * generate_mac_mini_data(void)
{
    return @{
        
        @"i5-3210M" : @3100,
        @"i7-3615QM" : @3300,
        @"i7-3720QM" : @3600,
        
        @"i5-4260U" : @2700,
        @"i5-4278U" : @3100,
        @"i5-4308U" : @3300,
        @"i7-4578U" : @3500,
        
        @"i3-8100B" : @3600,
        @"i5-8500B" : @4100,
        @"i7-8700B" : @4600
    };
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSDictionary * generate_mac_pro_data(void)
{
    return @{
        
        @"W3565" : @3460,
        @"W3680" : @3600,
    };
}

#endif
