module Model.OldState exposing (OldState, hasOldStuff)

import BigInt
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
