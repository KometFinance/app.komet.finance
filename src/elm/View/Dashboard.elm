module View.Dashboard exposing (dashboard)

import Html exposing (Html, a, button, div, h3, h4, h5, h6, hr, img, li, node, p, small, span, text, ul)
import Html.Attributes exposing (attribute, class, disabled, href, id, src, target, type_)
import Html.Events exposing (onClick)
import Html.Extra exposing (viewMaybe)
import Maybe.Extra
import Model exposing (Images, Model)
import Model.Balance exposing (split)
import Model.OldState
import Model.StakingInfo exposing (GeneralStakingInfo, RewardInfo, StakingInfoError, UserStakingInfo, isStaking)
import Model.Wallet exposing (Wallet, canStake)
import RemoteData exposing (RemoteData(..))
import Round
import Svg exposing (defs, g, linearGradient, rect, stop, svg)
import Svg.Attributes exposing (fill, fillRule, height, offset, stopColor, stroke, strokeWidth, transform, width, x, x1, x2, y, y1, y2)
import Update exposing (Msg(..))
import View.Commons exposing (defaultError, defaultLoader)


dashboard : Model -> Html Msg
dashboard { images, wallet, userStakingInfo, rewardInfo, generalStakingInfo, oldState } =
    div [ class "w-full row" ]
        [ div [ class "col-12 col-md-12 col-lg-10 mx-lg-auto" ]
            [ Html.Extra.viewIf (Model.OldState.hasOldStuff oldState) <|
                div [ class "mt-16 alert alert-info d-flex align-items-center justify-content-start", attribute "role" "alert" ]
                    [ h5 [ class "mb-0 mr-3 alert-heading" ]
                        [ text "V2 is Here!" ]
                    , button [ class "ml-auto btn btn-info", onClick <| ShowMigrationPanel True ]
                        [ text "Switch from V1 now" ]
                    ]
            , div [ class "row" ]
                [ div [ class "col-12" ]
                    [ wallet |> RemoteData.toMaybe |> viewMaybe (generalInfoAndCTA images (RemoteData.toMaybe userStakingInfo))
                    ]
                ]
            , div [ class "row" ]
                [ div [ class "col-12 col-sm-12 col-md-4 d-flex align-self-stretch" ]
                    [ viewStakingInfo userStakingInfo generalStakingInfo
                    ]
                , div [ class "col-12 col-sm-6 col-md-4 d-flex align-self-stretch" ]
                    [ viewReward userStakingInfo rewardInfo
                    ]
                , div [ class "col-12 col-sm-6 col-md-4 d-flex align-self-stretch" ]
                    [ viewFidelity rewardInfo
                    ]
                ]
            ]
        ]


viewReward : RemoteData StakingInfoError UserStakingInfo -> RemoteData StakingInfoError RewardInfo -> Html Msg
viewReward remoteUserStakingInfo remoteRewardInfo =
    div [ class "my-3 card Appboard my-md-0 w-100", id "Reward" ]
        [ div [ class "p-4 card-body" ]
            [ h3 [ class "mb-0 text-center text-white card-title" ]
                [ text "Staking reward" ]
            , p [ class "text-center text-muted" ]
                [ small []
                    [ text "Pending NOVA Reward" ]
                ]
            , div [ class "my-5 d-block position-relative", attribute "style" "height: 10em" ] <|
                case remoteRewardInfo of
                    Loading ->
                        [ div [ class "Plasma position-absolute" ]
                            [ defaultLoader
                            ]
                        ]

                    NotAsked ->
                        [ div [ class "Plasma position-absolute" ]
                            [ defaultLoader
                            ]
                        ]

                    Failure _ ->
                        [ div [ class "Plasma position-absolute" ]
                            [ text "No Data" ]
                        ]

                    Success { fees, reward } ->
                        let
                            ( unit, decimals ) =
                                reward
                                    |> Model.Balance.minusFees fees
                                    |> split 2
                        in
                        [ div [ class "Plasma position-absolute" ]
                            [ p [ class "mb-0 text-center amount lead" ]
                                [ text unit
                                , small []
                                    [ text <| "." ++ decimals ]
                                ]
                            ]
                        , remoteUserStakingInfo
                            |> RemoteData.toMaybe
                            |> Maybe.Extra.filter isStaking
                            |> Html.Extra.viewMaybe
                                (\_ ->
                                    node "plasma-reward" [] []
                                )
                        ]
            , button
                [ class "mt-3 btn btn-primary btn-block"
                , type_ "submit"
                , remoteUserStakingInfo
                    |> RemoteData.unwrap True (not << isStaking)
                    |> disabled
                , onClick <| ShowClaimConfirmation True
                ]
                [ text "Claim rewards" ]
            , button
                [ class "mt-3 btn btn-outline-primary btn-block"
                , type_ "submit"
                , remoteUserStakingInfo
                    |> RemoteData.unwrap True (not << isStaking)
                    |> disabled
                , onClick <| ShowWithdrawConfirmation True
                ]
                [ text "Withdraw LP" ]
            ]
        ]


generalInfoAndCTA : Images -> Maybe UserStakingInfo -> Wallet -> Html Msg
generalInfoAndCTA images userStakingInfo wallet =
    let
        ( lpUnit, lpDecimals ) =
            split 4 wallet.lpBalance
    in
    div [ class "mb-5 card Appboard" ]
        [ div [ class "p-4 card-body d-flex align-items-center liqui" ]
            [ div [ class "mr-auto" ]
                [ h4 [ class "mb-0 text-center text-white gradient_lp" ]
                    [ span []
                        [ text lpUnit
                        , small []
                            [ text <| "." ++ lpDecimals
                            , span [ class "text-muted" ]
                                [ text " KOMET/ETH LP" ]
                            ]
                        ]
                    ]
                , span [ class "text-muted" ]
                    [ text "Available balance for Staking" ]
                ]
            , div [ class "ml-auto btn-liqui d-flex justify-content-end" ]
                [ a
                    [ class "flex flex-row items-center space-x-1 btn btn-outline-primary"
                    , type_ "submit"
                    , target "_blank"
                    , href "https://app.uniswap.org/#/add/ETH/0x6CfB6dF56BbdB00226AeFfCdb2CD1FE8Da1ABdA7"
                    ]
                    [ img [ src images.externalLink, class "filter" ] []
                    , span [] [ text "Add liquidity" ]
                    ]
                , Html.Extra.viewIf (canStake wallet) <|
                    div [ class "ml-3 d-flex justify-content-end" ]
                        [ button
                            [ class "flex flex-row items-center space-x-1 btn btn-primary"
                            , onClick <| ShowStakingForm True
                            ]
                            [ img [ src images.stakingGem ] []
                            , span []
                                [ text <|
                                    if Maybe.Extra.unwrap False Model.StakingInfo.isStaking userStakingInfo then
                                        "Stake more"

                                    else
                                        "Start staking"
                                ]
                            ]
                        ]
                ]
            ]
        ]


viewStakingInfo :
    RemoteData StakingInfoError UserStakingInfo
    -> RemoteData StakingInfoError GeneralStakingInfo
    -> Html Msg
viewStakingInfo remoteStakingInfo remoteGeneralStakingInfo =
    div [ class "my-3 card Appboard my-md-0 w-100", id "Stats" ]
        [ div [ class "flex flex-col items-center p-4 card-body" ]
            [ h3 [ class "mb-0 text-center text-white card-title" ]
                [ text "Staking info" ]
            , p [ class "text-center text-muted" ]
                [ small []
                    [ text "Statistics about staking" ]
                ]
            , case RemoteData.map2 Tuple.pair remoteGeneralStakingInfo remoteStakingInfo of
                Loading ->
                    defaultLoader

                NotAsked ->
                    defaultLoader

                Failure _ ->
                    defaultError

                Success ( { totalLpStaked }, { amount } ) ->
                    div [ class "pt-3 d-flex align-self-center flex-column" ]
                        [ ul [ class "mt-4 list-unstyled" ]
                            [ li []
                                [ text "Your active KOMET/ETH LP staked" ]
                            , let
                                ( unit, decimals ) =
                                    split 7 amount
                              in
                              li [ class "text-primary" ]
                                [ text unit
                                , small []
                                    [ text <| "." ++ decimals ++ " KOMET/ETH LP"
                                    , span [ class "ml-2 text-muted" ]
                                        [ Model.Balance.percentOf amount totalLpStaked
                                            |> viewMaybe
                                                (\percent ->
                                                    text <| "(" ++ Round.round 2 percent ++ "% of total)"
                                                )
                                        ]
                                    ]
                                ]
                            ]
                        , hr []
                            []
                        , ul [ class "list-unstyled" ]
                            [ li []
                                [ text "Total KOMET/ETH LP staked" ]
                            , let
                                ( unit, decimals ) =
                                    split 7 totalLpStaked
                              in
                              li [ class "text-muted" ]
                                [ text unit
                                , small []
                                    [ text <| "." ++ decimals ++ " KOMET/ETH LP" ]
                                ]
                            ]
                        ]
            ]
        ]


feeSlider : Int -> Html Msg
feeSlider fees =
    let
        percentFees : Float
        percentFees =
            min 98.0 (100 - ((toFloat <| (fees - 1) * 100) / 29))
    in
    svg
        [ height "20px"
        , width "100%"
        ]
        [ defs []
            [ linearGradient
                [ id "linear"
                , x1 "0%"
                , x2 "100%"
                , y1 "50%"
                , y2 "50%"
                ]
                [ stop
                    [ offset "0%", stopColor "#AA3D3D" ]
                    []
                , stop
                    [ offset "100%", stopColor "#76FFBA" ]
                    []
                ]
            ]
        , g
            [ fill "none"
            , fillRule "evenodd"
            , stroke "none"
            , strokeWidth "1"
            ]
            [ g [ transform "translate(-402.000000, -799.000000)" ]
                [ g [ transform "translate(402.000000, 799.000000)" ]
                    [ rect
                        [ fill "url(#linear)"
                        , height "4"
                        , width "100%"
                        , x "0"
                        , y "8"
                        ]
                        []
                    , rect
                        [ fill "#FFF"
                        , height "20"
                        , width "5"
                        , x <|
                            String.fromFloat percentFees
                                ++ "%"
                        , y "0"
                        ]
                        []
                    ]
                ]
            ]
        ]


viewFidelity : RemoteData StakingInfoError RewardInfo -> Html Msg
viewFidelity remoteRewardInfo =
    div [ class "my-3 card Appboard my-md-0 w-100", id "PlasmaPower" ]
        [ div [ class "p-4 card-body" ]
            [ h3 [ class "mb-0 text-center card-title" ]
                [ text "Fees breakdown" ]
            , p [ class "text-center text-muted" ]
                [ small []
                    [ text "Your staking fidelity" ]
                ]
            , RemoteData.toMaybe remoteRewardInfo
                |> Html.Extra.viewMaybe
                    (\{ fees } ->
                        div [ class "my-8" ]
                            [ h6 []
                                [ text <| String.fromInt fees ++ "% withdraw fees" ]
                            , feeSlider fees
                            , small [ class "text-muted" ]
                                [ text "Current withdraw fees on your NOVA reward" ]
                            ]
                    )
            , div [ class "p-4 text-left card text-muted space-y-8" ]
                [ p [ class "text-justify" ]
                    [ text "Fees only apply to withdrawing the NOVA you get as a reward for staking. "
                    , span [ class "text-warning" ]
                        [ text "We will never tax your KOMET/ETH LP tokens transactions!" ]
                    ]
                , a [ class "btn btn-outline-primary", onClick <| ShowFeeExplanation True ] [ text "Read More" ]
                ]
            ]
        ]
