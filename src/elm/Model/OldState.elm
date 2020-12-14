module Model.OldState exposing
    ( MigrationState
    , MigrationStep(..)
    , OldState
    , decoder
    , defaultMigrationState
    , hasOldStuff
    , update
    )

import BigInt
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Model.Balance exposing (Balance)
import RemoteData exposing (RemoteData(..))


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


type alias MigrationState =
    { approvingNovaTransition : RemoteData () ()
    , transferingNova : RemoteData () ()
    , withdrawal : RemoteData () ()
    , claimRewards : RemoteData () ()
    , approvingDeposit : RemoteData () ()
    , deposit : RemoteData () ()
    , currentStep : MigrationStep
    }


defaultMigrationState : MigrationState
defaultMigrationState =
    { approvingNovaTransition = NotAsked
    , transferingNova = NotAsked
    , withdrawal = NotAsked
    , claimRewards = NotAsked
    , approvingDeposit = NotAsked
    , deposit = NotAsked
    , currentStep = Start
    }


update : OldState -> Result () () -> MigrationState -> MigrationState
update { oldStaking } result model =
    case ( model.currentStep, result ) of
        ( Start, _ ) ->
            model

        ( Done, _ ) ->
            model

        ( ApprovingNovaTransition, Ok () ) ->
            { model
                | approvingNovaTransition = RemoteData.Success ()
                , transferingNova = RemoteData.Loading
                , currentStep = TransferingNova
            }

        ( ApprovingNovaTransition, Err () ) ->
            { model
                | approvingNovaTransition = RemoteData.Failure ()
                , withdrawal =
                    if Model.Balance.isPositive oldStaking then
                        RemoteData.Loading

                    else
                        RemoteData.NotAsked
                , currentStep =
                    if Model.Balance.isPositive oldStaking then
                        EmergencyWithdrawal

                    else
                        Done
            }

        ( TransferingNova, _ ) ->
            { model
                | transferingNova = RemoteData.fromResult result
                , withdrawal =
                    if Model.Balance.isPositive oldStaking then
                        RemoteData.Loading

                    else
                        RemoteData.NotAsked
                , currentStep =
                    if Model.Balance.isPositive oldStaking then
                        EmergencyWithdrawal

                    else
                        Done
            }

        ( EmergencyWithdrawal, Ok () ) ->
            { model
                | withdrawal = RemoteData.Success ()
                , claimRewards = RemoteData.Loading
                , currentStep = ClaimRewards
            }

        ( EmergencyWithdrawal, Err () ) ->
            { model
                | withdrawal = RemoteData.Failure ()
                , currentStep = Done
            }

        ( ClaimRewards, Ok () ) ->
            { model
                | claimRewards = RemoteData.Success ()
                , approvingNovaTransition = RemoteData.Loading
                , currentStep = ApprovingDeposit
            }

        ( ClaimRewards, Err () ) ->
            { model
                | claimRewards = RemoteData.Failure ()
                , currentStep = Done
            }

        ( ApprovingDeposit, Ok () ) ->
            { model
                | approvingDeposit = RemoteData.Success ()
                , deposit = RemoteData.Loading
                , currentStep = Deposing
            }

        ( ApprovingDeposit, Err () ) ->
            { model
                | approvingDeposit = RemoteData.Failure ()
                , currentStep = Done
            }

        ( Deposing, _ ) ->
            { model
                | deposit = RemoteData.fromResult result
                , currentStep = Done
            }


type MigrationStep
    = Start
    | ApprovingNovaTransition
    | TransferingNova
    | EmergencyWithdrawal
    | ClaimRewards
    | ApprovingDeposit
    | Deposing
    | Done
