module Model.Wallet exposing
    ( Token(..)
    , Wallet
    , WalletError(..)
    , allTokens
    , canStake
    , decoder
    )

import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Model.Balance as Balance exposing (Balance)
import Utils.Json exposing (decodeExactString)


type alias Wallet =
    { address : String

    -- might need to make these more specifictly typed than that
    , kometBalance : Balance
    , ethBalance : Balance
    , lpBalance : Balance
    , novaBalance : Balance
    }


type Token
    = Komet
    | LP
    | Eth
    | Nova


allTokens : List Token
allTokens =
    [ LP, Komet, Nova, Eth ]


type WalletError
    = SoftConnectFailed
    | MissingContracts
      -- TODO add more error handling here
    | WrongJson Json.Decode.Error


{-| for now: staking available only requires LP tokens
-}
canStake : Wallet -> Bool
canStake { lpBalance } =
    Balance.isPositive lpBalance


decoder : Decoder (Result WalletError Wallet)
decoder =
    Json.Decode.oneOf
        [ -- ok decoder
          Json.Decode.field "ok"
            (Json.Decode.succeed Wallet
                |> required "account" Json.Decode.string
                |> required "komet"
                    Balance.decoder
                |> required "eth"
                    Balance.decoder
                |> required "lp"
                    Balance.decoder
                |> required "nova"
                    Balance.decoder
                |> Json.Decode.map Ok
            )

        -- err decoder
        , Json.Decode.field "err"
            (Json.Decode.oneOf
                [ decodeExactString "SOFT_CONNECT_FAILED" <| Err SoftConnectFailed
                , decodeExactString "CONTRACT_NOT_FOUND" <| Err MissingContracts
                ]
            )
        ]
