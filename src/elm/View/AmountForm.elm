module View.AmountForm exposing
    ( confirmRewardClaimModal
    , stakingModal
    , withdrawModal
    )

import BigInt exposing (BigInt)
import Html exposing (Html, button, div, fieldset, form, h1, h3, h4, input, p, small, span, text)
import Html.Attributes exposing (attribute, class, classList, disabled, id, placeholder, type_, value)
import Html.Events exposing (onBlur, onClick, onInput, onSubmit)
import Html.Extra
import Maybe.Extra
import Model exposing (AmountInputForm, StakingFormStage(..), WithdrawInputForm)
import Model.Balance exposing (Balance)
import Model.StakingInfo exposing (RewardInfo, UserStakingInfo)
import Model.Wallet exposing (Wallet)
import RemoteData exposing (RemoteData(..))
import Update exposing (Msg(..))
import Utils.BigInt
import View.Commons


confirmRewardClaimModal : RemoteData () () -> UserStakingInfo -> RewardInfo -> Html Msg
confirmRewardClaimModal request userStakingInfo rewardInfo =
    let
        isLoading =
            RemoteData.isLoading request
    in
    View.Commons.modal
        { onClose =
            if isLoading then
                Nothing

            else
                Just <| ShowClaimConfirmation False
        , progress =
            case request of
                NotAsked ->
                    33

                Loading ->
                    66

                Success _ ->
                    100

                Failure _ ->
                    33
        , content =
            div [ class "p-5 card-body" ]
                [ h3 [ class "text-center card-title" ]
                    [ text "Claiming NOVA rewards" ]
                , p [ class "mt-4 mb-0 text-center lead gradient_lp" ]
                    [ text <| Model.Balance.humanReadableBalance 2 rewardInfo.reward ]
                , p [ class "text-center text-muted" ]
                    [ small []
                        [ text "Pending NOVA" ]
                    ]
                , costBreakdown userStakingInfo rewardInfo (BigInt.fromInt 0) Claim
                , button
                    [ class "flex flex-row items-center justify-center mt-5 mb-0 btn btn-block btn-primary space-x-4"
                    , disabled <| isLoading
                    , onClick RewardClaim
                    ]
                  <|
                    if isLoading then
                        [ span [ class "spinner-border" ] []
                        , span [] [ text "Claiming ..." ]
                        ]

                    else
                        [ text "Start" ]
                , if isLoading then
                    wankyLoader

                  else
                    Html.Extra.nothing
                ]
        }


withdrawModal : WithdrawInputForm -> UserStakingInfo -> RewardInfo -> Html Msg
withdrawModal ({ request } as withdrawInfo) userStakingInfo rewardInfo =
    View.Commons.modal
        { onClose =
            if RemoteData.isLoading request then
                Nothing

            else
                Just <| ShowWithdrawConfirmation False
        , progress =
            case request of
                NotAsked ->
                    33

                Loading ->
                    66

                Success _ ->
                    100

                Failure _ ->
                    33
        , content =
            viewInput
                { title = "Withdraw KOMET/ETH LP tokens"
                , amountDescription = "Amount of KOMET/ETH LP tokens you want to withdraw"
                , buttonText = "Withdraw LP"
                , buttonTextPending = "Withdrawing"
                , onSubmitMsg = Withdraw
                , updateMsg = UpdateWithdrawForm
                , available = userStakingInfo.amount
                , validityTest =
                    \amount ->
                        let
                            left =
                                BigInt.sub (Model.Balance.toBigInt userStakingInfo.amount) amount
                        in
                        (BigInt.gt amount <| BigInt.fromInt 0)
                            && (left == BigInt.fromInt 0)
                            || BigInt.gte left Model.StakingInfo.minStaking
                , move = Withdrawal
                }
                withdrawInfo
            <|
                Just ( userStakingInfo, rewardInfo )
        }


stakingModal : AmountInputForm -> Wallet -> Maybe ( UserStakingInfo, RewardInfo ) -> Html Msg
stakingModal stakingForm wallet maybeStakingAndRewards =
    View.Commons.modal
        { onClose =
            if stakingForm.request == Loading then
                Nothing

            else
                Just <| ShowStakingForm False
        , progress =
            case ( stakingForm.stage, stakingForm.request ) of
                ( PendingStaking, Loading ) ->
                    75

                ( PendingStaking, _ ) ->
                    50

                ( PendingApproval, Loading ) ->
                    25

                ( PendingApproval, _ ) ->
                    0
        , content =
            case stakingForm.stage of
                PendingApproval ->
                    viewInput
                        { title = "Staking KOMET/ETH LP tokens"
                        , amountDescription = "Amount of KOMET/ETH LP tokens you want to stake"
                        , buttonText = "Approve contract"
                        , buttonTextPending = "Awaiting approval..."
                        , onSubmitMsg = AskContractApproval
                        , updateMsg = UpdateStakingForm
                        , available = wallet.lpBalance
                        , validityTest = \amount -> BigInt.gte amount Model.StakingInfo.minStaking
                        , move = Deposit
                        }
                        stakingForm
                        maybeStakingAndRewards

                PendingStaking ->
                    viewStakingConfirmation stakingForm.amount stakingForm.request
        }


viewStakingConfirmation : BigInt -> RemoteData () () -> Html Msg
viewStakingConfirmation amount request =
    let
        isLoading =
            RemoteData.isLoading request
    in
    div [ class "p-5 card-body" ]
        [ h3 [ class "text-center card-title" ]
            [ text "Selected amount" ]
        , h4 [ class "mt-4 mb-2 text-center gradient_lp display-3" ]
            [ text <| Utils.BigInt.toBaseUnit amount ]
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


type alias InputConfig a =
    { title : String
    , amountDescription : String
    , buttonText : String
    , buttonTextPending : String
    , onSubmitMsg : Msg
    , updateMsg : Form a -> Msg
    , available : Balance
    , validityTest : BigInt -> Bool
    , move : Move
    }


type alias Form a =
    { a
        | amount : BigInt
        , amountInput : String
        , request : RemoteData () ()
    }


type Move
    = Withdrawal
    | Claim
    | Deposit


viewInput : InputConfig a -> Form a -> Maybe ( UserStakingInfo, RewardInfo ) -> Html Msg
viewInput config ({ amountInput, request } as inputForm) maybeStakingAndRewards =
    let
        isLoading : Bool
        isLoading =
            RemoteData.isLoading request

        availableBigInt : BigInt
        availableBigInt =
            Model.Balance.toBigInt config.available

        maybeAmount : Maybe BigInt
        maybeAmount =
            Utils.BigInt.fromBaseUnit amountInput
                |> Maybe.map (BigInt.min availableBigInt)

        isValid : Bool
        isValid =
            maybeAmount
                |> Maybe.Extra.unwrap False
                    config.validityTest

        setMax : Msg
        setMax =
            config.updateMsg <|
                { inputForm
                    | amount = availableBigInt
                    , amountInput = Utils.BigInt.toBaseUnit availableBigInt
                }

        validateInput : Msg
        validateInput =
            config.updateMsg <|
                { inputForm
                    | amount = maybeAmount |> Maybe.withDefault (BigInt.fromInt 0)
                    , amountInput = Maybe.Extra.unwrap "" Utils.BigInt.toBaseUnit maybeAmount
                }

        updateInput : String -> Msg
        updateInput =
            \str ->
                config.updateMsg <|
                    { inputForm
                        | amountInput = str
                        , amount = maybeAmount |> Maybe.withDefault (BigInt.fromInt 0)
                    }
    in
    div [ class "p-5 card-body" ]
        [ h3 [ class "text-center card-title" ]
            [ text config.title ]
        , p [ class "mt-4 mb-0 text-center lead gradient_lp" ]
            [ text <| Model.Balance.humanReadableBalance 2 config.available ]
        , p [ class "text-center text-muted" ]
            [ small []
                [ text "Amount available" ]
            ]
        , form
            [ class "pt-4"
            , onSubmit <|
                if isValid then
                    config.onSubmitMsg

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
                                    && (maybeAmount == Nothing)
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
                    [ text config.amountDescription ]
                , Maybe.withDefault
                    Html.Extra.nothing
                  <|
                    Maybe.map2
                        (\( userStakingInfo, rewardInfo ) amount ->
                            if Model.StakingInfo.isStaking userStakingInfo && BigInt.gt amount (BigInt.fromInt 0) then
                                costBreakdown userStakingInfo rewardInfo amount config.move

                            else
                                Html.Extra.nothing
                        )
                        maybeStakingAndRewards
                        maybeAmount
                , maybeAmount
                    |> Html.Extra.viewMaybe
                        (\_ ->
                            Html.Extra.viewIf (not isValid) <|
                                -- we've got a amount but it's not valid => minimum limit
                                p [ class "alert alert-warning" ]
                                <|
                                    case config.move of
                                        Withdrawal ->
                                            [ text "The minimal amount to stay in the pool is  "
                                            , span [ class "font-bold text-black" ] [ text "0.1" ]
                                            , text " KOMET/ETH LP"
                                            ]

                                        Deposit ->
                                            [ text "You need to put at least "
                                            , span [ class "font-bold text-black" ] [ text "0.1" ]
                                            , text " KOMET/ETH LP to add tokens to the pool"
                                            ]

                                        Claim ->
                                            []
                        )
                , button
                    [ class "flex flex-row items-center justify-center mt-5 mb-0 btn btn-block btn-primary space-x-4"
                    , disabled <| isLoading && not isValid
                    , classList
                        [ ( "disabled", not isValid )
                        ]
                    ]
                  <|
                    if isLoading then
                        [ span [ class "spinner-border" ] []
                        , span [] [ text config.buttonTextPending ]
                        ]

                    else
                        [ text config.buttonText ]
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


costBreakdown : UserStakingInfo -> RewardInfo -> BigInt -> Move -> Html Msg
costBreakdown userStakingInfo { reward, fees } amount move =
    div [ class "flex flex-col mt-8 mb-12" ]
        [ h1 [ class "pl-4 text-xl text-left" ] [ text "Operation preview" ]
        , div [ class "p-4 text-left card text-muted space-y-2" ]
            [ h4 [ class "pt-2 pb-0 mb-0 text-lg text-muted" ]
                [ text "Your stake in the pool:" ]
            , p [ class "flex flex-row items-center space-x-2" ]
                [ span [ class "text-info" ]
                    [ text <|
                        Utils.BigInt.toBaseUnit <|
                            let
                                stakingAmount =
                                    Model.Balance.toBigInt userStakingInfo.amount
                            in
                            case move of
                                Withdrawal ->
                                    BigInt.sub stakingAmount amount

                                Deposit ->
                                    BigInt.add stakingAmount amount

                                Claim ->
                                    stakingAmount
                    ]
                , case move of
                    Withdrawal ->
                        span [ class "text-danger" ]
                            [ text <|
                                "(-\u{00A0}"
                                    ++ Utils.BigInt.toBaseUnit amount
                                    ++ ")"
                            ]

                    Deposit ->
                        span [ class "text-success" ]
                            [ text <|
                                "(+\u{00A0}"
                                    ++ Utils.BigInt.toBaseUnit amount
                                    ++ ")"
                            ]

                    Claim ->
                        span [ class "text-success" ]
                            [ text <|
                                "(No Changes!)"
                            ]
                , span [ class "text-secondary" ] [ text "KOMET/ETH LP" ]
                ]
            , h4 [ class "pt-2 pb-0 mb-0 text-lg text-muted" ]
                [ text "Your reward distribution" ]
            , p [ class "flex flex-row items-center space-x-2" ]
                [ span [ class "text-info" ]
                    [ text <|
                        Model.Balance.humanReadableBalance 4 <|
                            Model.Balance.minusFees fees reward
                    ]
                , span [ class "text-secondary" ] [ text "NOVA" ]
                , div [ class "text-secondary" ]
                    [ text "(including "
                    , span [ class "text-secondary" ] [ text <| String.fromInt fees ]
                    , span [] [ text "% fees)" ]
                    ]
                ]
            , h4 [ class "pt-2 pb-0 mb-0 text-lg text-muted" ]
                [ text "Your fees" ]
            , p [ class "flex flex-row items-center space-x-2" ] <|
                case move of
                    Deposit ->
                        [ span [ class "text-info" ]
                            [ text <| String.fromInt fees ++ "%"
                            ]
                        , span [ class "text-secondary" ] [ text "(No changes!)" ]
                        ]

                    Claim ->
                        [ span [ class "text-info" ]
                            [ text <| String.fromInt fees ++ "%"
                            ]
                        , span [ class "text-secondary" ] [ text "(No changes!)" ]
                        ]

                    Withdrawal ->
                        [ span [ class "text-info" ]
                            [ text "30%"
                            ]
                        , span [ class "text-danger" ]
                            [ text <| "(+" ++ String.fromInt (fees - 30) ++ ")"
                            ]
                        , span [ class "text-secondary" ] [ text "(reset)" ]
                        ]
            ]
        ]
