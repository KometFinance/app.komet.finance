port module Update exposing
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
import Model.StakingInfo exposing (GeneralStakingInfo, RewardInfo, StakingInfoError, UserStakingInfo, isStaking)
import Model.Wallet exposing (Wallet, WalletError)
import RemoteData exposing (RemoteData(..))
import Result.Extra
import Time
import Utils.BigInt


type Msg
    = NoOp
    | Connect
    | UpdateWallet (Result WalletError Wallet)
    | UpdateUserStakingInfo (Result StakingInfoError UserStakingInfo)
    | UpdateGeneralStakingInfo (Result StakingInfoError GeneralStakingInfo)
    | UpdateReward (Result StakingInfoError RewardInfo)
    | ShowStakingForm Bool
    | ShowFeeExplanation Bool
    | ShowWithdrawConfirmation Bool
    | UpdateStakingForm AmountInputForm
    | UpdateWithdrawForm WithdrawInputForm
    | AskContractApproval
    | ApprovalResponse (Result () ())
    | SendDeposit
    | DepositResponse (Result () ())
    | Withdraw
    | WithdrawResponse (Result () ())
    | RefreshInfo
    | VisibityChange Visibility


port connectMetamask : Bool -> Cmd msg


port updateWallet : (Json.Decode.Value -> msg) -> Sub msg


port requestUserStakingInfo : String -> Cmd msg


port updateUserStakingInfo : (Json.Decode.Value -> msg) -> Sub msg


port requestGeneralStakingInfo : () -> Cmd msg


port updateGeneralStakingInfo : (Json.Decode.Value -> msg) -> Sub msg


port askContractApproval : Json.Encode.Value -> Cmd msg


port contractApprovalResponse : (Json.Encode.Value -> msg) -> Sub msg


port sendDeposit : Json.Encode.Value -> Cmd msg


port depositResponse : (Json.Encode.Value -> msg) -> Sub msg


port withdraw : Json.Encode.Value -> Cmd msg


port withdrawResponse : (Json.Encode.Value -> msg) -> Sub msg


port updateReward : (Json.Decode.Value -> msg) -> Sub msg


port poolReward : String -> Cmd msg


type alias Flags =
    Images


init : Flags -> ( Model, Cmd Msg )
init images =
    ( { images = images
      , wallet = Loading
      , modal = Nothing
      , userStakingInfo = NotAsked
      , generalStakingInfo = Loading
      , rewardInfo = NotAsked
      , visibility = Browser.Events.Visible
      }
    , Cmd.batch
        [ connectMetamask False
        , requestGeneralStakingInfo ()
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        VisibityChange visibility ->
            ( { model | visibility = visibility }, Cmd.none )

        Connect ->
            ( { model | wallet = Loading }, connectMetamask True )

        UpdateWallet newWallet ->
            let
                isNewAddress =
                    model.wallet
                        |> RemoteData.unwrap False
                            (.address >> (/=) (newWallet |> Result.Extra.unwrap "" .address))
            in
            ( { model
                | wallet = RemoteData.fromResult newWallet
                , userStakingInfo =
                    if isNewAddress then
                        Loading

                    else
                        model.userStakingInfo
              }
            , Result.Extra.unwrap Cmd.none
                (\{ address } ->
                    Cmd.batch
                        [ requestUserStakingInfo address
                        , poolReward address
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
                            poolReward wallet.address

                        else
                            Cmd.none
                    )
            )

        UpdateGeneralStakingInfo generalStakingInfo ->
            ( { model | generalStakingInfo = RemoteData.fromResult generalStakingInfo }, Cmd.none )

        ShowStakingForm False ->
            ( { model | modal = Nothing }, Cmd.none )

        ShowStakingForm True ->
            ( { model | modal = Just <| StakingDetail Model.defaultAmountInputForm }, Cmd.none )

        ShowFeeExplanation True ->
            ( { model | modal = Just FeeExplanation }, Cmd.none )

        ShowFeeExplanation False ->
            ( { model | modal = Nothing }, Cmd.none )

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
                    , askContractApproval <|
                        Json.Encode.object
                            [ ( "userAddress", Json.Encode.string wallet.address )
                            , ( "amount", Utils.BigInt.encode form.amount )
                            ]
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
                    , sendDeposit <|
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
                        [ connectMetamask False
                        , requestGeneralStakingInfo ()
                        ]
                    )

        DepositResponse (Err ()) ->
            updateWithWalletAndStakingModal model <|
                \_ form ->
                    ( { model | modal = Just <| StakingDetail { form | request = RemoteData.Failure () } }
                    , connectMetamask False
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
                    , withdraw <|
                        Json.Encode.object
                            [ ( "amount", Utils.BigInt.encode form.amount )
                            , ( "userAddress", Json.Encode.string wallet.address )
                            ]
                    )
                )

        WithdrawResponse (Ok ()) ->
            ( { model | modal = Nothing }, connectMetamask False )

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
                            [ connectMetamask False
                            , if RemoteData.unwrap False isStaking model.userStakingInfo then
                                poolReward wallet.address

                              else
                                Cmd.none
                            , requestGeneralStakingInfo ()
                            ]
                        )
                    )

        UpdateReward newReward ->
            ( { model | rewardInfo = RemoteData.fromResult newReward }, Cmd.none )


updateWithWalletAndStakingModal : Model -> (Wallet -> AmountInputForm -> ( Model, Cmd Msg )) -> ( Model, Cmd Msg )
updateWithWalletAndStakingModal model updater =
    model.wallet
        |> RemoteData.toMaybe
        |> Maybe.map2 Tuple.pair model.modal
        |> Maybe.Extra.unwrap ( model, Cmd.none )
            (\( modal, wallet ) ->
                case modal of
                    MoneyDetail ->
                        ( model, Cmd.none )

                    FeeExplanation ->
                        ( model, Cmd.none )

                    StakingDetail form ->
                        updater wallet form

                    WithdrawDetail _ ->
                        ( model, Cmd.none )
            )


updateWithWalletAndWithdrawModal : Model -> (Wallet -> WithdrawInputForm -> ( Model, Cmd Msg )) -> ( Model, Cmd Msg )
updateWithWalletAndWithdrawModal model updater =
    Maybe.map3
        (\modal wallet _ ->
            case modal of
                MoneyDetail ->
                    ( model, Cmd.none )

                FeeExplanation ->
                    ( model, Cmd.none )

                StakingDetail _ ->
                    ( model, Cmd.none )

                WithdrawDetail info ->
                    updater wallet info
        )
        model.modal
        (RemoteData.toMaybe model.wallet)
        (RemoteData.toMaybe model.userStakingInfo)
        |> Maybe.withDefault ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions { wallet, modal, visibility } =
    Sub.batch
        [ Browser.Events.onVisibilityChange VisibityChange
        , updateWallet
            (Json.Decode.decodeValue Model.Wallet.decoder
                >> Result.mapError Model.Wallet.WrongJson
                >> Result.andThen identity
                >> UpdateWallet
            )
        , wallet
            |> RemoteData.unwrap Sub.none
                (\_ ->
                    Sub.batch
                        [ updateUserStakingInfo
                            (Json.Decode.decodeValue Model.StakingInfo.decoderUserInfo
                                >> Result.mapError Model.StakingInfo.WrongJson
                                >> UpdateUserStakingInfo
                            )
                        , withdrawResponse
                            (Json.Decode.decodeValue Model.StakingInfo.decoderWithdraw
                                >> Result.mapError (\_ -> ())
                                >> WithdrawResponse
                            )
                        , updateReward
                            (Json.Decode.decodeValue Model.StakingInfo.decoderReward
                                >> Result.mapError Model.StakingInfo.WrongJson
                                >> UpdateReward
                            )
                        , if visibility == Browser.Events.Visible then
                            Time.every 30000
                                (\_ -> RefreshInfo)

                          else
                            Sub.none
                        ]
                )
        , updateGeneralStakingInfo
            (Json.Decode.decodeValue Model.StakingInfo.decoderGeneralInfo
                >> Result.mapError Model.StakingInfo.WrongJson
                >> UpdateGeneralStakingInfo
            )
        , modal
            |> Maybe.Extra.unwrap Sub.none
                (\justModal ->
                    case justModal of
                        MoneyDetail ->
                            Sub.none

                        FeeExplanation ->
                            Sub.none

                        StakingDetail _ ->
                            wallet
                                |> RemoteData.unwrap
                                    Sub.none
                                    (\_ ->
                                        Sub.batch
                                            [ contractApprovalResponse
                                                (Json.Decode.decodeValue Model.StakingInfo.decoderApproval
                                                    >> Result.mapError (\_ -> ())
                                                    >> ApprovalResponse
                                                )
                                            , depositResponse
                                                (Json.Decode.decodeValue Model.StakingInfo.decoderDeposit
                                                    >> Result.mapError (\_ -> ())
                                                    >> DepositResponse
                                                )
                                            ]
                                    )

                        WithdrawDetail _ ->
                            wallet
                                |> RemoteData.unwrap Sub.none
                                    (\_ ->
                                        withdrawResponse
                                            (Json.Decode.decodeValue
                                                Model.StakingInfo.decoderWithdraw
                                                >> Result.mapError (\_ -> ())
                                                >> WithdrawResponse
                                            )
                                    )
                )
        ]
