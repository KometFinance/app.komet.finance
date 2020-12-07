module Utils.BigInt exposing (fromBaseUnit, toBaseUnit, toInt)

import BigInt exposing (BigInt)
import Maybe.Extra
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


toBaseUnit : BigInt -> String
toBaseUnit =
    BigInt.toString
        >> (\str ->
                let
                    unit =
                        String.dropRight baseFactor str

                    decimals =
                        String.right baseFactor str
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
                in
                unit
                    ++ Maybe.Extra.unwrap "" ((++) ".") decimals
           )
