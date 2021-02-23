module Model.Balance exposing
    ( Balance
    , Fees
    , Underflow(..)
    , decoder
    , encode
    , feeDecoder
    , feesToInt
    , feesToString
    , fromBigInt
    , humanReadableBalance
    , isPositive
    , map
    , minusFees
    , percentOf
    , split
    , toBigInt
    , underflowFeeLevel
    )

import BigInt exposing (BigInt)
import Json.Decode exposing (Decoder)
import Json.Decode.Extra
import Json.Encode
import Maybe.Extra
import Result.Extra
import Utils.BigInt


type Balance
    = Balance BigInt


type Underflow
    = Underflow


type alias Fees =
    Result Underflow Int


underflowFeeLevel : Int
underflowFeeLevel =
    1


feesToInt : Fees -> Int
feesToInt =
    Result.withDefault underflowFeeLevel


feesToString : Fees -> String
feesToString =
    Result.Extra.unwrap "🐛*\u{00A0}" String.fromInt


fromBigInt : BigInt -> Balance
fromBigInt =
    Balance


toBigInt : Balance -> BigInt
toBigInt (Balance balance) =
    balance


map : (BigInt -> BigInt) -> Balance -> Balance
map fct =
    Balance << fct << toBigInt


isPositive : Balance -> Bool
isPositive (Balance balance) =
    BigInt.gt balance (BigInt.fromInt 0)


humanReadableBalance : Int -> Balance -> String
humanReadableBalance precision =
    toBigInt >> Utils.BigInt.humanReadable precision


split : Int -> Balance -> ( String, String )
split precision =
    toBigInt
        >> Utils.BigInt.toBaseUnitAndDecimals
        >> (\( unit, decimals ) ->
                ( unit
                , if String.isEmpty decimals then
                    "0"

                  else
                    String.left precision decimals
                )
           )


percentOf : Int -> Balance -> Balance -> Maybe String
percentOf precision (Balance balance1) (Balance balance2) =
    Utils.BigInt.percentOf precision balance1 balance2


minusFees : Fees -> Balance -> Balance
minusFees fees (Balance number) =
    let
        taxes =
            number
                |> BigInt.mul (BigInt.fromInt <| Result.withDefault underflowFeeLevel fees)
                |> (\num ->
                        BigInt.div num (BigInt.fromInt 100)
                   )
    in
    Balance <| BigInt.sub number taxes


encode : Balance -> Json.Encode.Value
encode =
    toBigInt >> BigInt.toString >> Json.Encode.string


decoder : Decoder Balance
decoder =
    Json.Decode.string
        |> Json.Decode.andThen
            (BigInt.fromIntString
                >> Maybe.Extra.unwrap (Json.Decode.fail "not a bigInt") Json.Decode.succeed
            )
        |> Json.Decode.map Balance


feeDecoder : Decoder Fees
feeDecoder =
    Json.Decode.Extra.parseInt
        |> Json.Decode.map
            (\int ->
                if int > 35 then
                    Err Underflow

                else
                    Ok int
            )
