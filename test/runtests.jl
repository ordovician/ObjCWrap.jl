using ObjCWrap
using Test

@classes NSString, NSNumber, NSMutableDictionary, NSArray, NSMutableArray

@testset "All Tests" begin
    include("messaging.jl")
    include("syntax.jl")
    include("collections.jl")
end
