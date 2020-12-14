module Model.OldState exposing
    ( MigrationStep(..)
    , OldState
    , decoder
    , hasOldStuff
    )

import BigInt
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Model.Balance exposing (Balance)
import RemoteData exposing (RemoteData)


type alias OldState =
    { oldNova : Balance
    , oldStaking : Balance
    }


hasOldStuff : RemoteData err OldState -> Bool
hasOldStuff =
    RemoteData.unwrap False
        (\{ oldNova, oldStaking } ->
            BigInt.gt (Model.Balance.toBigInt oldNova) (BigInt.fromInt 0) || BigInt.gt (Model.Balance.toBigInt oldStaking) (BigInt.fromInt 0)
        )


decoder : Decoder OldState
decoder =
    Json.Decode.field "ok"
        (Json.Decode.succeed OldState
            |> required "oldNova" Model.Balance.decoder
            |> required "oldStaking" Model.Balance.decoder
        )


type MigrationStep
    = Start
    | ApprovingNovaTransition (RemoteData () ())
    | TransferingNovas (RemoteData () ())
    | EmergencyWithdrawal (RemoteData () ())
    | ClaimRewards (RemoteData () ())
    | ApprovingDeposit (RemoteData () ())
    | Deposing (RemoteData () ())
    | Done
