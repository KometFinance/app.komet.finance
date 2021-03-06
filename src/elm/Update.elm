module Update exposing
    ( Flags
    , Msg(..)
    , init
    , subscriptions
    , update
    )

import BigInt
import Browser.Events exposing (Visibility)
import Json.Decode
import Json.Encode
import Maybe.Extra
import Model exposing (AmountInputForm, Images, Modal(..), Model, StakingFormStage(..), WithdrawInputForm)
import Model.Balance
import Model.OldState exposing (MigrationState, MigrationStep(..), OldState)
import Model.StakingInfo exposing (GeneralStakingInfo, RewardInfo, StakingInfoError, UserStakingInfo, isStaking)
import Model.Wallet exposing (Token, Wallet, WalletError)
import Ports
import Process exposing (sleep)
import RemoteData exposing (RemoteData(..))
import Result.Extra
import Task
import Time
import Utils.BigInt
import Utils.Json


type Msg
    = NoOp
    | Connect
    | CopyAddressToClickBoard
    | RemoveFeedback
    | UpdateWallet (Result WalletError Wallet)
    | UpdateUserStakingInfo (Result StakingInfoError UserStakingInfo)
    | UpdateGeneralStakingInfo (Result StakingInfoError GeneralStakingInfo)
    | UpdateReward (Result StakingInfoError RewardInfo)
    | UpdateOldState (Result () OldState)
    | ShowMoneyDetails (Maybe Token)
    | ShowStakingForm Bool
    | ShowFeeExplanation Bool
    | ShowWithdrawConfirmation Bool
    | ShowClaimConfirmation Bool
    | ShowMigrationPanel Bool
    | StartMigration
    | UpdateStakingForm AmountInputForm
    | UpdateWithdrawForm WithdrawInputForm
    | UpdateMigration (Result () ())
    | AskContractApproval
    | ApprovalResponse (Result () ())
    | SendDeposit
    | DepositResponse (Result () ())
    | Withdraw
    | ClaimResponse (Result () ())
    | RewardClaim
    | WithdrawResponse (Result () ())
    | RefreshInfo
    | VisibityChange Visibility


type alias Flags =
    { images : Images
    , addresses : Model.Wallet.Addresses
    }


init : Flags -> ( Model, Cmd Msg )
init { images, addresses } =
    ( { images = images
      , addresses = addresses
      , copyToClipboardFeedback = False
      , wallet = Loading
      , modal = Nothing
      , userStakingInfo = NotAsked
      , generalStakingInfo = Loading
      , rewardInfo = NotAsked
      , oldState = NotAsked
      , visibility = Browser.Events.Visible
      }
    , Cmd.batch
        [ Ports.connectMetamask False
        , Ports.requestGeneralStakingInfo ()
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        CopyAddressToClickBoard ->
            ( { model | copyToClipboardFeedback = True }
            , Cmd.batch
                [ Ports.copyToClipboard "contract-address"
                , sleep 2000 |> Task.perform (\_ -> RemoveFeedback)
                ]
            )

        RemoveFeedback ->
            ( { model | copyToClipboardFeedback = False }
            , Cmd.none
            )

        VisibityChange visibility ->
            ( { model | visibility = visibility }, Cmd.none )

        Connect ->
            ( { model | wallet = Loading }, Ports.connectMetamask True )

        UpdateWallet newWallet ->
            let
                isNewAddress =
                    model.wallet
                        |> RemoteData.unwrap False
                            (.address >> (/=) (newWallet |> Result.Extra.unwrap "" .address))

                newModel =
                    { model
                        | wallet = RemoteData.fromResult newWallet
                        , userStakingInfo =
                            if isNewAddress then
                                Loading

                            else
                                model.userStakingInfo
                        , oldState =
                            if isNewAddress then
                                Loading

                            else
                                model.oldState
                    }
            in
            ( newModel
            , Result.Extra.unwrap Cmd.none
                (\{ address } ->
                    Cmd.batch
                        [ Ports.requestUserStakingInfo address
                        , if RemoteData.isLoading newModel.oldState || RemoteData.isNotAsked newModel.oldState then
                            Ports.requestOldState address

                          else
                            Cmd.none
                        , if RemoteData.unwrap False Model.StakingInfo.isStaking newModel.userStakingInfo then
                            Cmd.batch
                                [ Ports.poolReward address
                                , Ports.requestOldState address
                                ]

                          else
                            Cmd.none
                        ]
                )
                newWallet
            )

        UpdateUserStakingInfo stakingInfo ->
            let
                isCurrentlyStaking =
                    Result.Extra.unwrap False isStaking stakingInfo
            in
            ( { model
                | userStakingInfo = RemoteData.fromResult stakingInfo
                , rewardInfo =
                    if isCurrentlyStaking then
                        if RemoteData.isSuccess model.rewardInfo then
                            model.rewardInfo

                        else
                            Loading

                    else
                        Failure Model.StakingInfo.SNAFU
              }
            , model.wallet
                |> RemoteData.unwrap Cmd.none
                    (\wallet ->
                        if isCurrentlyStaking then
                            Ports.poolReward wallet.address

                        else
                            Cmd.none
                    )
            )

        UpdateGeneralStakingInfo generalStakingInfo ->
            ( { model | generalStakingInfo = RemoteData.fromResult generalStakingInfo }, Cmd.none )

        ShowMoneyDetails (Just token) ->
            ( { model | modal = Just <| Model.MoneyDetail token }, Cmd.none )

        ShowMoneyDetails Nothing ->
            ( { model | modal = Nothing }, Cmd.none )

        ShowStakingForm False ->
            ( { model | modal = Nothing }, Cmd.none )

        ShowStakingForm True ->
            ( { model | modal = Just <| StakingDetail Model.defaultAmountInputForm }, Cmd.none )

        ShowClaimConfirmation True ->
            ( { model | modal = Just <| ConfirmRewardClaim NotAsked }, Cmd.none )

        ShowClaimConfirmation False ->
            ( { model | modal = Nothing }, Cmd.none )

        RewardClaim ->
            updateWithWalletAndClaimModal model
                (\wallet _ ->
                    ( { model
                        | modal =
                            Just <| ConfirmRewardClaim Loading
                      }
                    , Ports.withdraw <|
                        Json.Encode.object
                            [ ( "amount", Utils.BigInt.encode <| BigInt.fromInt 0 )
                            , ( "userAddress", Json.Encode.string wallet.address )
                            ]
                    )
                )

        ClaimResponse request ->
            ( { model
                | modal =
                    if model.modal == (Just <| ConfirmRewardClaim Loading) then
                        Just <| ConfirmRewardClaim <| RemoteData.fromResult request

                    else
                        model.modal
              }
            , Cmd.none
            )

        ShowFeeExplanation True ->
            ( { model | modal = Just FeeExplanation }, Cmd.none )

        ShowFeeExplanation False ->
            ( { model | modal = Nothing }, Cmd.none )

        ShowMigrationPanel True ->
            ( { model | modal = Just <| MigrationDetail Model.OldState.defaultMigrationState }, Cmd.none )

        ShowMigrationPanel False ->
            ( { model | modal = Nothing }
            , model.wallet
                |> RemoteData.unwrap Cmd.none
                    (\wallet ->
                        Cmd.batch
                            [ Ports.requestOldState wallet.address
                            , Task.succeed () |> Task.perform (\_ -> RefreshInfo)
                            ]
                    )
            )

        StartMigration ->
            updateWithWalletAndMigrationModal model <|
                \wallet oldState migrationState ->
                    let
                        ( nextState, cmd ) =
                            if Model.Balance.isPositive oldState.oldNova then
                                ( { migrationState
                                    | approvingNovaTransition = Loading
                                    , currentStep = ApprovingNovaTransition
                                  }
                                , Ports.requestContractApproval
                                    { from = Ports.OldNova
                                    , to = Ports.NovaMigration
                                    , userAddress = wallet.address
                                    , amount = Model.Balance.toBigInt oldState.oldNova
                                    }
                                )

                            else
                                ( { migrationState
                                    | withdrawal = Loading
                                    , currentStep = EmergencyWithdrawal
                                  }
                                , Ports.requestEmergencyWithdrawal wallet.address
                                )
                    in
                    ( { model | modal = Just <| MigrationDetail nextState }, cmd )

        UpdateMigration result ->
            updateWithWalletAndMigrationModal model <|
                \wallet oldState migrationState ->
                    Model.OldState.update oldState result migrationState
                        |> (\newState ->
                                ( { model | modal = Just <| MigrationDetail newState }
                                , case newState.currentStep of
                                    Start ->
                                        Cmd.none

                                    Done ->
                                        Cmd.none

                                    ApprovingNovaTransition ->
                                        Cmd.none

                                    TransferingNova ->
                                        Ports.novaSwap wallet.address oldState.oldNova

                                    EmergencyWithdrawal ->
                                        Ports.requestEmergencyWithdrawal wallet.address

                                    ClaimRewards ->
                                        Ports.claimRewards wallet.address

                                    ApprovingDeposit ->
                                        Ports.requestContractApproval
                                            { from = Ports.LPToken
                                            , to = Ports.MasterUniverse
                                            , userAddress = wallet.address
                                            , amount =
                                                Model.Balance.toBigInt oldState.oldStaking
                                            }

                                    Deposing ->
                                        Ports.sendDeposit <|
                                            Json.Encode.object
                                                [ ( "userAddress", Json.Encode.string wallet.address )
                                                , ( "amount", Model.Balance.encode oldState.oldStaking )
                                                ]
                                )
                           )

        UpdateStakingForm form ->
            updateWithWalletAndStakingModal model <|
                \_ _ ->
                    ( { model
                        | modal =
                            Just <| StakingDetail form
                      }
                    , Cmd.none
                    )

        UpdateWithdrawForm form ->
            updateWithWalletAndWithdrawModal model <|
                \_ _ ->
                    ( { model
                        | modal =
                            Just <| WithdrawDetail form
                      }
                    , Cmd.none
                    )

        AskContractApproval ->
            updateWithWalletAndStakingModal model <|
                \wallet form ->
                    ( { model | modal = Just <| StakingDetail { form | request = Loading } }
                    , Ports.requestContractApproval
                        { from = Ports.LPToken
                        , to = Ports.MasterUniverse
                        , userAddress = wallet.address
                        , amount = form.amount
                        }
                    )

        ApprovalResponse response ->
            updateWithWalletAndStakingModal model <|
                \_ form ->
                    ( { model
                        | modal =
                            Just <|
                                StakingDetail
                                    { form
                                        | request =
                                            response
                                                |> RemoteData.fromResult
                                                -- if all went well we move to the next stage hence we reset the request
                                                |> RemoteData.andThen (\_ -> NotAsked)
                                        , stage = Result.Extra.unwrap PendingApproval (\_ -> PendingStaking) response
                                    }
                      }
                    , Cmd.none
                    )

        SendDeposit ->
            updateWithWalletAndStakingModal model <|
                \wallet form ->
                    ( { model
                        | modal =
                            Just <| StakingDetail { form | request = Loading }
                      }
                    , Ports.sendDeposit <|
                        Json.Encode.object
                            [ ( "userAddress", Json.Encode.string wallet.address )
                            , ( "amount", Json.Encode.string <| BigInt.toString form.amount )
                            ]
                    )

        DepositResponse (Ok ()) ->
            updateWithWalletAndStakingModal model <|
                \_ _ ->
                    ( { model | modal = Nothing }
                    , Cmd.batch
                        [ Ports.connectMetamask False
                        , Ports.requestGeneralStakingInfo ()
                        ]
                    )

        DepositResponse (Err ()) ->
            updateWithWalletAndStakingModal model <|
                \_ form ->
                    ( { model | modal = Just <| StakingDetail { form | request = RemoteData.Failure () } }
                    , Ports.connectMetamask False
                    )

        ShowWithdrawConfirmation False ->
            ( { model | modal = Nothing }, Cmd.none )

        ShowWithdrawConfirmation True ->
            model.wallet
                |> RemoteData.unwrap ( model, Cmd.none )
                    (\_ ->
                        ( { model | modal = Just <| WithdrawDetail Model.defaultWithdrawInfo }, Cmd.none )
                    )

        Withdraw ->
            updateWithWalletAndWithdrawModal model
                (\wallet form ->
                    ( { model
                        | modal =
                            Just <|
                                WithdrawDetail
                                    { form
                                        | request = Loading
                                    }
                      }
                    , Ports.withdraw <|
                        Json.Encode.object
                            [ ( "amount", Utils.BigInt.encode form.amount )
                            , ( "userAddress", Json.Encode.string wallet.address )
                            ]
                    )
                )

        WithdrawResponse (Ok ()) ->
            ( { model | modal = Nothing }, Ports.connectMetamask False )

        WithdrawResponse (Err ()) ->
            updateWithWalletAndWithdrawModal model
                (\_ info ->
                    ( { model | modal = Just <| WithdrawDetail { info | request = RemoteData.Failure () } }, Cmd.none )
                )

        RefreshInfo ->
            model.wallet
                |> RemoteData.unwrap ( model, Cmd.none )
                    (\wallet ->
                        ( model
                        , Cmd.batch
                            [ Ports.connectMetamask False
                            , if RemoteData.unwrap False isStaking model.userStakingInfo then
                                Ports.poolReward wallet.address

                              else
                                Cmd.none
                            , Ports.requestGeneralStakingInfo ()
                            ]
                        )
                    )

        UpdateReward newReward ->
            ( { model | rewardInfo = RemoteData.fromResult newReward }, Cmd.none )

        UpdateOldState oldState ->
            ( { model | oldState = RemoteData.fromResult oldState }, Cmd.none )


updateWithWalletAndStakingModal : Model -> (Wallet -> AmountInputForm -> ( Model, Cmd Msg )) -> ( Model, Cmd Msg )
updateWithWalletAndStakingModal model updater =
    model.wallet
        |> RemoteData.toMaybe
        |> Maybe.map2 Tuple.pair model.modal
        |> Maybe.Extra.unwrap ( model, Cmd.none )
            (\( modal, wallet ) ->
                case modal of
                    MoneyDetail _ ->
                        ( model, Cmd.none )

                    FeeExplanation ->
                        ( model, Cmd.none )

                    StakingDetail form ->
                        updater wallet form

                    ConfirmRewardClaim _ ->
                        ( model, Cmd.none )

                    WithdrawDetail _ ->
                        ( model, Cmd.none )

                    MigrationDetail _ ->
                        ( model, Cmd.none )
            )


updateWithWalletAndClaimModal : Model -> (Wallet -> RemoteData () () -> ( Model, Cmd Msg )) -> ( Model, Cmd Msg )
updateWithWalletAndClaimModal model updater =
    Maybe.map3
        (\modal wallet _ ->
            case modal of
                MoneyDetail _ ->
                    ( model, Cmd.none )

                FeeExplanation ->
                    ( model, Cmd.none )

                StakingDetail _ ->
                    ( model, Cmd.none )

                ConfirmRewardClaim request ->
                    updater wallet request

                WithdrawDetail _ ->
                    ( model, Cmd.none )

                MigrationDetail _ ->
                    ( model, Cmd.none )
        )
        model.modal
        (RemoteData.toMaybe model.wallet)
        (RemoteData.toMaybe model.userStakingInfo)
        |> Maybe.withDefault ( model, Cmd.none )


updateWithWalletAndWithdrawModal : Model -> (Wallet -> WithdrawInputForm -> ( Model, Cmd Msg )) -> ( Model, Cmd Msg )
updateWithWalletAndWithdrawModal model updater =
    Maybe.map3
        (\modal wallet _ ->
            case modal of
                MoneyDetail _ ->
                    ( model, Cmd.none )

                FeeExplanation ->
                    ( model, Cmd.none )

                StakingDetail _ ->
                    ( model, Cmd.none )

                ConfirmRewardClaim _ ->
                    ( model, Cmd.none )

                WithdrawDetail info ->
                    updater wallet info

                MigrationDetail _ ->
                    ( model, Cmd.none )
        )
        model.modal
        (RemoteData.toMaybe model.wallet)
        (RemoteData.toMaybe model.userStakingInfo)
        |> Maybe.withDefault ( model, Cmd.none )


updateWithWalletAndMigrationModal : Model -> (Wallet -> OldState -> MigrationState -> ( Model, Cmd Msg )) -> ( Model, Cmd Msg )
updateWithWalletAndMigrationModal model updater =
    Maybe.map3
        (\modal wallet oldState ->
            case modal of
                MoneyDetail _ ->
                    ( model, Cmd.none )

                FeeExplanation ->
                    ( model, Cmd.none )

                StakingDetail _ ->
                    ( model, Cmd.none )

                ConfirmRewardClaim _ ->
                    ( model, Cmd.none )

                WithdrawDetail _ ->
                    ( model, Cmd.none )

                MigrationDetail migrationState ->
                    updater wallet oldState migrationState
        )
        model.modal
        (RemoteData.toMaybe model.wallet)
        (RemoteData.toMaybe model.oldState)
        |> Maybe.withDefault ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions { wallet, modal, visibility } =
    Sub.batch
        [ Browser.Events.onVisibilityChange VisibityChange
        , Ports.updateWallet
            (Json.Decode.decodeValue Model.Wallet.decoder
                >> Result.mapError Model.Wallet.WrongJson
                >> Result.andThen identity
                >> UpdateWallet
            )
        , wallet
            |> RemoteData.unwrap Sub.none
                (\_ ->
                    Sub.batch
                        [ Ports.updateUserStakingInfo
                            (Json.Decode.decodeValue Model.StakingInfo.decoderUserInfo
                                >> Result.mapError Model.StakingInfo.WrongJson
                                >> UpdateUserStakingInfo
                            )
                        , Ports.withdrawResponse
                            (Json.Decode.decodeValue Model.StakingInfo.decoderWithdraw
                                >> Result.mapError (\_ -> ())
                                >> WithdrawResponse
                            )
                        , Ports.updateReward
                            (Json.Decode.decodeValue Model.StakingInfo.decoderReward
                                >> Result.mapError Model.StakingInfo.WrongJson
                                >> UpdateReward
                            )
                        , Ports.updateOldState
                            (Json.Decode.decodeValue Model.OldState.decoder
                                >> Result.mapError (\_ -> ())
                                >> UpdateOldState
                            )
                        , if visibility == Browser.Events.Visible then
                            Time.every 30000
                                (\_ -> RefreshInfo)

                          else
                            Sub.none
                        ]
                )
        , Ports.updateGeneralStakingInfo
            (Json.Decode.decodeValue Model.StakingInfo.decoderGeneralInfo
                >> Result.mapError Model.StakingInfo.WrongJson
                >> UpdateGeneralStakingInfo
            )
        , modal
            |> Maybe.Extra.unwrap Sub.none
                (\justModal ->
                    case justModal of
                        MoneyDetail _ ->
                            Sub.none

                        FeeExplanation ->
                            Sub.none

                        StakingDetail _ ->
                            wallet
                                |> RemoteData.unwrap
                                    Sub.none
                                    (\_ ->
                                        Sub.batch
                                            [ Ports.contractApprovalResponse
                                                (Json.Decode.decodeValue Utils.Json.decoderOk
                                                    >> Result.mapError (\_ -> ())
                                                    >> ApprovalResponse
                                                )
                                            , Ports.depositResponse
                                                (Json.Decode.decodeValue Model.StakingInfo.decoderDeposit
                                                    >> Result.mapError (\_ -> ())
                                                    >> DepositResponse
                                                )
                                            ]
                                    )

                        ConfirmRewardClaim _ ->
                            wallet
                                |> RemoteData.unwrap Sub.none
                                    (\_ ->
                                        Ports.withdrawResponse
                                            (Json.Decode.decodeValue
                                                Model.StakingInfo.decoderWithdraw
                                                >> Result.mapError (\_ -> ())
                                                >> ClaimResponse
                                            )
                                    )

                        WithdrawDetail _ ->
                            wallet
                                |> RemoteData.unwrap Sub.none
                                    (\_ ->
                                        Ports.withdrawResponse
                                            (Json.Decode.decodeValue
                                                Model.StakingInfo.decoderWithdraw
                                                >> Result.mapError (\_ -> ())
                                                >> WithdrawResponse
                                            )
                                    )

                        MigrationDetail _ ->
                            Sub.batch
                                [ Ports.contractApprovalResponse
                                    (Json.Decode.decodeValue Utils.Json.decoderOk
                                        >> Result.mapError (\_ -> ())
                                        >> UpdateMigration
                                    )
                                , Ports.updateEmergencyWithdrawal
                                    (Json.Decode.decodeValue Utils.Json.decoderOk
                                        >> Result.mapError (\_ -> ())
                                        >> UpdateMigration
                                    )
                                , Ports.reportExchange
                                    (Json.Decode.decodeValue Utils.Json.decoderOk
                                        >> Result.mapError (\_ -> ())
                                        >> UpdateMigration
                                    )
                                , Ports.reportClaimRewards
                                    (Json.Decode.decodeValue Utils.Json.decoderOk
                                        >> Result.mapError (\_ -> ())
                                        >> UpdateMigration
                                    )
                                , Ports.depositResponse
                                    (Json.Decode.decodeValue Utils.Json.decoderOk
                                        >> Result.mapError (\_ -> ())
                                        >> UpdateMigration
                                    )
                                ]
                )
        ]
