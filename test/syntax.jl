# Make sure that the high-level Objective-C syntax translates properly to messages

@classes NSString, NSNumber

@testset "syntax" begin
    
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
end