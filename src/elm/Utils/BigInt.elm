module Utils.BigInt exposing
    ( encode
    , fromBaseUnit
    , toBaseUnit
    , toInt
    )

import BigInt exposing (BigInt)
import Json.Encode
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


toBaseUnit : BigInt -> String
toBaseUnit =
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
                in
                unit
                    ++ Maybe.Extra.unwrap "" ((++) ".") decimals
           )


encode : BigInt -> Json.Encode.Value
encode =
    Json.Encode.string << BigInt.toString
