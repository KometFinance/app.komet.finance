module Model.Balance exposing
    ( Balance
    , Fees
    , decoder
    , encode
    , fromBigInt
    , humanReadableBalance
    , isPositive
    , map
    , minusFees
    , percentOf
    , split
    , toBigInt
    )

import BigInt exposing (BigInt)
import Json.Decode exposing (Decoder)
import Json.Encode
import Maybe.Extra
import Utils.BigInt


type Balance
    = Balance BigInt


type alias Fees =
    Int


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
                |> BigInt.mul (BigInt.fromInt fees)
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
