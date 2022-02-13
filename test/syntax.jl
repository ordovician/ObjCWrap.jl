# Make sure that the high-level Objective-C syntax translates properly to messages


@testset "syntax tests" begin
    
    @testset "create a hello string" begin
        str = @objc [[NSString alloc] initWithUTF8String: "hello"]
        chars = @objc [str UTF8String]

        @test unsafe_string(chars) == "hello"
    end
    
    @testset "create integer" begin

        num = @objc [NSNumber numberWithInt:42]
        x = @objc [num intValue]

        @test x == 42
    end
    
    @testset "create integer in block of code" begin
        @objc begin
            num = [NSNumber numberWithInt:42]
            x = [num intValue]
        end
        @test x == 42
    end
    
    @testset "create string in block of objc code" begin
        @objc begin
            str = [[NSString alloc] initWithUTF8String: "hello"]
            chars = [str UTF8String]            
        end
        @test unsafe_string(chars) == "hello"
    end
    
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
end