@testset "messaging" begin
    
    # This test makes the follow Objective-C calls in a low-level fashion
    # str = [[NSString alloc] initWithUTF8String: "hello"]
    # @test unsafe_string([str UTF8String]) == "hello"
    @testset "create a hello string" begin
        NSString = Class("NSString")
    
        # uninit_str = [NSString alloc]
        uninit_str = message(NSString, Selector("alloc"))
        @test uninit_str != nil

        # str = [uninit_str initWithUTF8String: "hello"]
        str = message(uninit_str, Selector("initWithUTF8String:"), "hello")
        @test str != nil
        
        # Turn NSString object into regular UTF8 chars
        chars = message(str, Selector("UTF8String"))
        @test chars != nil
        
        @test unsafe_string(chars) == "hello"
    end
    
    @testset "create integer" begin
        NSNumber = Class("NSNumber")
        
        num = message(NSNumber, Selector("numberWithInt:"), 42)
        x = message(num, Selector("intValue"))
        
        @test x == 42
    end
end