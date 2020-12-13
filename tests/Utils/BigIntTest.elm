module Utils.BigIntTest exposing (fromBaseUnitTests, idempotence, toBaseUnitTests)

import BigInt exposing (BigInt)
import Expect
import Fuzz
import Test exposing (Test, describe, fuzz, fuzz2, test)
import Utils.BigInt exposing (fromBaseUnit, toBaseUnit)


alphaFuzzer : Fuzz.Fuzzer Char
alphaFuzzer =
    Fuzz.intRange 65 90
        |> Fuzz.map Char.fromCode


fromBaseUnitTests : Test
fromBaseUnitTests =
    describe "fromBaseUnit" <|
        [ test "empty string gives nothing" <|
            \_ -> fromBaseUnit "" |> Expect.equal Nothing
        , fuzz2 Fuzz.string alphaFuzzer "string with alpha inside gives nothing" <|
            \string char ->
                -- make sure this string has some letters
                String.cons char string |> fromBaseUnit |> Expect.equal Nothing
        ]
            ++ List.map fromBaseUnitSimpleTester simpleFromBaseUnitCases


idempotence : Test
idempotence =
    fuzz (Fuzz.float |> Fuzz.map Basics.abs) "idempotence of fromBaseUnit >> toBaseUnit" <|
        \input ->
            String.fromFloat input
                |> fromBaseUnit
                |> Maybe.map toBaseUnit
                |> Maybe.andThen String.toFloat
                |> Expect.equal (Just input)


shiftXBy : Int -> Int -> BigInt
shiftXBy num by =
    BigInt.fromInt num
        |> (\bn -> BigInt.mul bn (BigInt.pow (BigInt.fromInt 10) (BigInt.fromInt by)))


simpleFromBaseUnitCases : List ( String, BigInt )
simpleFromBaseUnitCases =
    [ ( "1", shiftXBy 1 18 )
    , ( "123123", shiftXBy 123123 18 )
    , ( "10", shiftXBy 10 18 )
    , ( "100", shiftXBy 100 18 )
    , ( "0.1", shiftXBy 1 17 )
    , ( ".1", shiftXBy 1 17 )
    , ( "0.01", shiftXBy 1 16 )
    , ( ".01", shiftXBy 1 16 )
    , ( "0.001", shiftXBy 1 15 )
    , ( ".001", shiftXBy 1 15 )
    , ( "0.00123", shiftXBy 123 13 )
    , ( ".00123", shiftXBy 123 13 )
    ]


fromBaseUnitSimpleTester : ( String, BigInt ) -> Test
fromBaseUnitSimpleTester ( number, result ) =
    test number <| \_ -> fromBaseUnit number |> Expect.equal (Just result)


toBaseUnitTests : Test
toBaseUnitTests =
    describe "toBaseUnit" <|
        List.map toBaseUnitSimpleTestRunner simpleToBaseUnitCases


simpleToBaseUnitCases : List ( BigInt, String )
simpleToBaseUnitCases =
    [ ( shiftXBy 1 18, "1" )
    , ( shiftXBy 1 17, "0.1" )
    , ( shiftXBy 1 16, "0.01" )
    , ( shiftXBy 1 15, "0.001" )
    , ( shiftXBy 1832 12, "0.001832" )
    ]


toBaseUnitSimpleTestRunner : ( BigInt, String ) -> Test
toBaseUnitSimpleTestRunner ( number, result ) =
    test result <| \_ -> toBaseUnit number |> Expect.equal result
