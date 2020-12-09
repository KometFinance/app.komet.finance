module View.AmountForm exposing
    ( stakingModal
    , withdrawModal
    )

import BigInt exposing (BigInt)
import Html exposing (Html, button, div, fieldset, form, h3, h4, input, p, small, span, text)
import Html.Attributes exposing (attribute, class, classList, disabled, id, placeholder, type_, value)
import Html.Events exposing (onBlur, onClick, onInput, onSubmit)
import Html.Extra
import Maybe.Extra
import Model exposing (AmountInputForm, Images, StakingFormStage(..), WithdrawInfo)
import Model.Balance exposing (Balance)
import Model.StakingInfo exposing (RewardInfo, UserStakingInfo)
import Model.Wallet exposing (Wallet)
import RemoteData exposing (RemoteData(..))
import Update exposing (Msg(..))
import Utils.BigInt
import View.Commons


stakingModal : AmountInputForm -> Wallet -> Html Msg
stakingModal stakingForm wallet =
    View.Commons.modal
        { onClose =
            if stakingForm.stakingRequest == Loading then
                Nothing

            else
                Just <| ShowStakingForm False
        , progress =
            case ( stakingForm.stage, stakingForm.stakingRequest ) of
                ( PendingStaking, Loading ) ->
                    75

                ( PendingStaking, _ ) ->
                    50

                ( PendingApproval, Loading ) ->
                    25

                ( PendingApproval, _ ) ->
                    0
        , content =
            let
                availableBigInt =
                    Model.Balance.toBigInt wallet.lpBalance

                amount =
                    Utils.BigInt.fromBaseUnit stakingForm.amountInput
                        |> Maybe.map (BigInt.min availableBigInt)

                isValid =
                    amount
                        |> Maybe.Extra.unwrap False
                            (\validAmount -> BigInt.gt validAmount (BigInt.fromInt 0))
            in
            case stakingForm.stage of
                PendingApproval ->
                    viewInput
                        { title = "Staking KOMET/ETH LP tokens"
                        , amountDescription = "Amount of KOMET/ETH LP tokens you want to stake"
                        , buttonText = "Approve contract"
                        , buttonTextPending = "Awaiting approval..."
                        , onSubmitMsg = AskContractApproval
                        , updateInput = \str -> UpdateStakingForm <| { stakingForm | amountInput = str }
                        , validateInput =
                            UpdateStakingForm
                                { stakingForm
                                    | amountToStake = amount |> Maybe.withDefault (BigInt.fromInt 0)
                                    , amountInput = Maybe.Extra.unwrap "" Utils.BigInt.toBaseUnit amount
                                }
                        , setMax =
                            UpdateStakingForm
                                { stakingForm
                                    | amountToStake = availableBigInt
                                    , amountInput = Utils.BigInt.toBaseUnit availableBigInt
                                }
                        }
                        { available = wallet.lpBalance
                        , amount = amount
                        , amountInput = stakingForm.amountInput
                        , isValid = isValid
                        , request = stakingForm.stakingRequest
                        }

                PendingStaking ->
                    viewStakingConfirmation amount stakingForm.stakingRequest
        }


viewStakingConfirmation : Maybe BigInt -> RemoteData () () -> Html Msg
viewStakingConfirmation amount request =
    let
        isLoading =
            RemoteData.isLoading request
    in
    div [ class "p-5 card-body" ]
        [ h3 [ class "text-center card-title" ]
            [ text "Selected amount" ]
        , h4 [ class "mt-4 mb-2 text-center gradient_lp display-3" ]
            [ text <| Maybe.Extra.unwrap "" Utils.BigInt.toBaseUnit amount ]
        , p [ class "mb-5 text-center text-muted" ]
            [ small []
                [ text "Amount of KOMET/ETH LP tokens ready to stake" ]
            ]
        , button
            [ class "mb-12 btn btn-block btn-outline-secondary"
            , disabled isLoading
            , onClick <|
                if isLoading then
                    NoOp

                else
                    ShowStakingForm False
            ]
            [ text "Cancel" ]
        , button
            [ class "mb-0 btn btn-block btn-primary btn-lg"
            , disabled isLoading
            , onClick <|
                if isLoading then
                    NoOp

                else
                    SendDeposit
            ]
            [ text "Start staking" ]
        , if isLoading then
            wankyLoader

          else
            Html.Extra.nothing
        ]


type alias Input =
    { available : Balance
    , amount : Maybe BigInt
    , amountInput : String
    , isValid : Bool
    , request : RemoteData () ()
    }


type alias InputConfig =
    { title : String
    , amountDescription : String
    , buttonText : String
    , buttonTextPending : String
    , onSubmitMsg : Msg
    , updateInput : String -> Msg
    , validateInput : Msg
    , setMax : Msg
    }


viewInput : InputConfig -> Input -> Html Msg
viewInput { title, amountDescription, buttonText, buttonTextPending, onSubmitMsg, updateInput, validateInput, setMax } { available, amount, amountInput, isValid, request } =
    let
        isLoading =
            RemoteData.isLoading request
    in
    div [ class "p-5 card-body" ]
        [ h3 [ class "text-center card-title" ]
            [ text title ]
        , p [ class "mt-4 mb-0 text-center lead gradient_lp" ]
            [ text <| Model.Balance.humanReadableBalance 2 available ]
        , p [ class "text-center text-muted" ]
            [ small []
                [ text "Amount available" ]
            ]
        , form
            [ class "pt-4"
            , onSubmit <|
                if isValid then
                    onSubmitMsg

                else
                    NoOp
            ]
            [ fieldset
                [ class "form-group"
                , disabled isLoading
                ]
                [ div
                    [ class "input-group"
                    ]
                    [ input
                        [ attribute "aria-describedby" ""
                        , attribute "aria-label" "Amount"
                        , class "form-control bg-dark text-primary"
                        , placeholder "0.0"
                        , classList
                            [ ( "is-invalid"
                              , (amountInput /= "")
                                    && (amount == Nothing)
                              )
                            ]
                        , value amountInput
                        , disabled isLoading
                        , onInput updateInput
                        , onBlur validateInput
                        ]
                        []
                    , div [ class "input-group-append" ]
                        [ button
                            [ class "btn btn-secondary"
                            , type_ "button"
                            , onClick setMax
                            ]
                            [ text "Max" ]
                        ]
                    ]
                , small [ class "py-2 form-text text-muted", id "" ]
                    [ text amountDescription ]
                , button
                    [ class "flex flex-row items-center justify-center mt-5 mb-0 btn btn-block btn-primary space-x-4"
                    , disabled isLoading
                    ]
                  <|
                    if isLoading then
                        [ span [ class "spinner-border" ] []
                        , span [] [ text buttonTextPending ]
                        ]

                    else
                        [ text buttonText ]
                , if isLoading then
                    wankyLoader

                  else
                    Html.Extra.nothing
                ]
            ]
        ]


wankyLoader : Html msg
wankyLoader =
    div [ class "pt-4 loader" ]
        [ div [ class "dot dot-1" ]
            []
        , div [ class "dot dot-2" ]
            []
        , div [ class "dot dot-3" ]
            []
        ]


withdrawModal : Images -> WithdrawInfo -> UserStakingInfo -> RewardInfo -> Html Msg
withdrawModal _ { withdrawRequest } userStakingInfo rewardInfo =
    let
        isLoading =
            RemoteData.isLoading withdrawRequest
    in
    div
        [ attribute "aria-labelledby" "connect"
        , attribute "aria-modal" "true"
        , class "modal fade show"
        , attribute "data-backdrop" "static"
        , attribute "data-keyboard" "false"
        , id "StackingModal"
        , attribute "role" "dialog"
        , attribute "style" "display: block;"
        , attribute "tabindex" "-1"
        ]
        [ div [ class "modal-dialog" ]
            [ div [ class "bg-transparent modal-content" ]
                [ div [ class "modal-header" ]
                    [ button
                        [ onClick <|
                            if isLoading then
                                NoOp

                            else
                                ShowWithdrawConfirmation False
                        , attribute "aria-label" "Close"
                        , class "close"
                        , id "StackingModalButton"
                        , attribute "data-dismiss" "modal"
                        , type_ "button"
                        , disabled isLoading
                        ]
                        [ span [ attribute "aria-hidden" "true" ]
                            [ text "×" ]
                        ]
                    ]
                , div [ class "p-0 text-center modal-body" ]
                    [ div [ class "mx-auto card Appboard" ]
                        [ let
                            progress =
                                case ( NotAsked, withdrawRequest ) of
                                    ( NotAsked, _ ) ->
                                        "0"

                                    ( Loading, _ ) ->
                                        "25"

                                    ( Success _, NotAsked ) ->
                                        "50"

                                    ( Success _, Failure _ ) ->
                                        "50"

                                    ( Success _, Loading ) ->
                                        "75"

                                    ( _, _ ) ->
                                        "25"
                          in
                          div [ class "progress" ]
                            [ div [ attribute "aria-valuemax" "100", attribute "aria-valuemin" "0", attribute "aria-valuenow" progress, class "progress-bar bg-primary", attribute "role" "progressbar", attribute "style" <| "width: " ++ progress ++ "%" ]
                                []
                            ]
                        , div [ class "p-5 card-body" ]
                            [ h3 [ class "text-center card-title" ]
                                [ text "Withdraw NOVA" ]
                            , p [ class "mt-4 mb-0 text-center lead gradient_lp" ]
                                [ text <| Model.Balance.humanReadableBalance 2 rewardInfo.reward
                                ]
                            , p [ class "text-center text-muted" ]
                                [ small []
                                    [ text "amount available" ]
                                ]
                            , div [ class "p-4 mb-12 text-left card text-muted space-y-2" ]
                                [ p [ class "pb-0 mb-0 text-muted" ]
                                    [ text "NOVA to withdraw: " ]
                                , p [ class "text-danger" ]
                                    [ NotAsked
                                        |> RemoteData.unwrap (text "\u{00A0}")
                                            (\justFees ->
                                                let
                                                    taxes =
                                                        rewardInfo.reward
                                                            |> Model.Balance.toBigInt
                                                            |> BigInt.mul (BigInt.fromInt justFees)
                                                            |> BigInt.div (BigInt.fromInt 100)

                                                    novaTTC =
                                                        rewardInfo.reward |> Model.Balance.map (BigInt.add (BigInt.negate taxes))
                                                in
                                                text <|
                                                    "-"
                                                        ++ Model.Balance.humanReadableBalance 2 novaTTC
                                                        ++ " (fees: "
                                                        ++ String.fromInt justFees
                                                        ++ "%)"
                                            )
                                    ]
                                , p [ class "pb-0 mb-0 text-muted" ]
                                    [ text "KOMET/ETH LP auto withdraw: " ]
                                , p [ class "text-danger" ]
                                    [ text <|
                                        "-"
                                            ++ Model.Balance.humanReadableBalance 2 userStakingInfo.amount
                                    ]
                                ]
                            , button
                                [ class "my-8 btn btn-block btn-primary btn-lg"
                                , disabled isLoading
                                , onClick <|
                                    if isLoading then
                                        NoOp

                                    else
                                        Withdraw
                                ]
                                [ text "Withdraw" ]
                            , p [ class "alert alert-warning" ] [ text "⚠ Withdrawing will reset your PlasmaPower" ]
                            , Html.Extra.viewIf (RemoteData.isFailure withdrawRequest) <| p [ class "alert alert-danger" ] [ text "⚠ the withdraw could not go through. Try again in a moment." ]
                            , if isLoading then
                                wankyLoader

                              else
                                Html.Extra.nothing
                            ]
                        ]
                    ]
                ]
            ]
        ]
