@testset "collection tests" begin
    
    @testset "create dictionary" begin
        dict = @objc [NSMutableDictionary dictionaryWithCapacity:6]
        @test dict != nil
        
        @objc [dict setObject:4 forKey:"four"]
        @objc [dict setObject:5 forKey:"five"]
        
        # Test that float values can later be retrieved as integers
        # to see NSNumber conversions happen properly
        @objc [dict setObject:6.0 forKey:"six"]
        
        four = @objc [[dict objectForKey:"four"] intValue]
        
        # Testing that integer 5 can be converted to floating point
        # value 5.0f0
        five = @objc [[dict objectForKey:"five"] floatValue]
        six = @objc [[dict objectForKey:"six"] intValue]
        
        @test four == 4
        @test five == 5.0f0
        @test six == 6
    end
    
     @testset "create array with single number" begin
         xs = @objc [NSArray arrayWithObject:42]
         x = @objc [[xs objectAtIndex:0] intValue]
         @test x == 42
     end
     
     @testset "create mutable array with multible numbers" begin
         xs = @objc [NSMutableArray arrayWithCapacity:10]
         
         @objc [xs addObject:8]
         @objc [xs addObject:12]
         @objc [xs addObject:14]
         
         third = @objc [[xs objectAtIndex:2] intValue]
         second = @objc [[xs objectAtIndex:1] intValue]
         first = @objc [[xs objectAtIndex:0] intValue]
         
         @test third == 14
         @test second == 12
         @test first == 8         
     end
end