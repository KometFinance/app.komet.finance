module Utils.BigInt exposing
    ( baseFactor
    , encode
    , fromBaseUnit
    , humanReadable
    , percentOf
    , toBaseUnit
    , toBaseUnitAndDecimals
    , toInt
    )

import BigInt exposing (BigInt)
import Json.Encode
import Maybe.Extra
import Round
import String


baseFactor : Int
baseFactor =
    18


toInt : BigInt -> Maybe Int
toInt =
    BigInt.toString >> String.toInt


fromBaseUnit : String -> Maybe BigInt
fromBaseUnit =
    String.split "."
        >> (\split ->
                case split of
                    [ "" ] ->
                        Nothing

                    [ unit ] ->
                        unit
                            ++ String.repeat baseFactor "0"
                            |> BigInt.fromIntString

                    [ unit, decimals ] ->
                        decimals
                            -- only keep 18 digits at most
                            |> String.left baseFactor
                            -- now pad that to have exactly 18 digits
                            |> String.padRight baseFactor '0'
                            |> (++) unit
                            |> BigInt.fromIntString

                    _ ->
                        Nothing
           )


toBaseUnitAndDecimals : BigInt -> ( String, String )
toBaseUnitAndDecimals =
    BigInt.toString
        >> (\str ->
                let
                    unit_ =
                        String.dropRight baseFactor str

                    unit =
                        if String.isEmpty unit_ then
                            "0"

                        else
                            unit_

                    decimals =
                        String.right baseFactor str
                            |> String.padLeft baseFactor '0'
                            |> String.foldr
                                (\c maybeStr ->
                                    case ( c, maybeStr ) of
                                        ( '0', Nothing ) ->
                                            Nothing

                                        ( _, Nothing ) ->
                                            Just [ c ]

                                        ( _, Just chars ) ->
                                            Just <| c :: chars
                                )
                                Nothing
                            |> Maybe.map String.fromList
                            |> Maybe.withDefault ""
                in
                ( unit, decimals )
           )


toBaseUnit : BigInt -> String
toBaseUnit =
    toBaseUnitAndDecimals
        >> (\( unit, decimals ) ->
                unit
                    ++ (if String.isEmpty decimals then
                            ""

                        else
                            "." ++ decimals
                       )
           )


humanReadable : Int -> BigInt -> String
humanReadable precision =
    toBaseUnitAndDecimals
        >> (\( unit, decimals ) ->
                unit
                    ++ (if String.isEmpty decimals then
                            ""

                        else
                            decimals |> String.left precision |> (++) "."
                       )
           )


percentOf : Int -> BigInt -> BigInt -> Maybe String
percentOf precision big1 big2 =
    if BigInt.gt big2 (BigInt.fromInt 0) then
        BigInt.mul big1 (BigInt.fromInt <| 100 * 10 ^ precision)
            |> (\times100 ->
                    BigInt.div times100 big2
                        |> BigInt.toString
                        |> String.toFloat
                        |> Maybe.map (\percent -> percent / (toFloat <| 10 ^ precision))
                        |> Maybe.map (Round.round precision)
               )

    else
        Nothing


encode : BigInt -> Json.Encode.Value
encode =
    Json.Encode.string << BigInt.toString
