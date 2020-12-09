module Model.Balance exposing
    ( Balance
    , Fees
    , decoder
    , encode
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


toBigInt : Balance -> BigInt
toBigInt (Balance balance) =
    balance


map : (BigInt -> BigInt) -> Balance -> Balance
map fct (Balance balance) =
    Balance <| fct balance


isPositive : Balance -> Bool
isPositive (Balance balance) =
    BigInt.gt balance (BigInt.fromInt 0)


weiToFactor : Int -> Balance -> BigInt
weiToFactor factor (Balance fullBalance) =
    BigInt.div fullBalance (BigInt.pow (BigInt.fromInt 10) (BigInt.fromInt (18 - factor)))



-- TODO maybe a lot of these implementations should go in BigInt and just be defined here as map BigInt.stuff


humanReadableBalance : Int -> Balance -> String
humanReadableBalance precision =
    split precision >> (\( unit, decimals ) -> unit ++ "." ++ decimals)


split : Int -> Balance -> ( String, String )
split precision =
    weiToFactor precision
        >> BigInt.toString
        >> (\intStr ->
                ( String.dropRight precision intStr
                    |> (\unit ->
                            if String.isEmpty unit then
                                "0"

                            else
                                unit
                       )
                , String.right precision intStr
                )
           )


percentOf : Balance -> Balance -> Maybe Float
percentOf balance1 balance2 =
    let
        baseUnitAmount1 =
            weiToFactor 18 balance1

        baseUnitAmount2 =
            weiToFactor 18 balance2

        maybeAmount1 =
            Utils.BigInt.toInt baseUnitAmount1

        maybeAmount2 =
            Utils.BigInt.toInt baseUnitAmount2
    in
    maybeAmount2
        |> Maybe.andThen
            (\amount2 ->
                if amount2 == 0 then
                    Nothing

                else
                    Just amount2
            )
        |> Maybe.map2
            (\amount1 amount2 ->
                toFloat amount1 * 100 / toFloat amount2
            )
            maybeAmount1


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
