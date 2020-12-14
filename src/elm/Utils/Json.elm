module Utils.Json exposing
    ( decodeExactString
    , decoderOk
    )

import Json.Decode exposing (Decoder)


decoderOk : Decoder ()
decoderOk =
    Json.Decode.field "ok" <| Json.Decode.succeed ()


decodeExactString : String -> a -> Decoder a
decodeExactString shouldMatch onSuccess =
    Json.Decode.string
        |> Json.Decode.andThen
            (\str ->
                if str == shouldMatch then
                    Json.Decode.succeed onSuccess

                else
                    Json.Decode.fail <| "expected \"" ++ shouldMatch ++ "\" but got \"" ++ str ++ "\""
            )
