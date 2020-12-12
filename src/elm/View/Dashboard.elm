module View.Dashboard exposing (dashboard)

import Html exposing (Html, a, br, button, div, h3, h4, hr, img, li, node, p, small, span, text, ul)
import Html.Attributes exposing (attribute, class, disabled, href, id, src, target, type_)
import Html.Events exposing (onClick)
import Html.Extra exposing (viewMaybe)
import Model exposing (Images, Model)
import Model.Balance exposing (split)
import Model.StakingInfo exposing (GeneralStakingInfo, RewardInfo, StakingInfoError, UserStakingInfo, isStaking)
import Model.Wallet exposing (Wallet, canStake)
import RemoteData exposing (RemoteData(..))
import Round
import Update exposing (Msg(..))
import View.Commons exposing (defaultError, defaultLoader)
import View.Gauge


dashboard : Model -> Html Msg
dashboard { images, wallet, userStakingInfo, rewardInfo, generalStakingInfo } =
    div [ class "w-full row" ]
        [ div [ class "col-12 col-md-12 col-lg-10 mx-lg-auto" ]
            [ div [ class "row" ]
                [ div [ class "col-12" ]
                    [ wallet |> RemoteData.toMaybe |> viewMaybe (generalInfoAndCTA images)
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
                    [ viewFidelity userStakingInfo
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
                        , node "plasma-reward" [] []
                        ]
            , button
                [ class "mt-3 btn btn-outline-primary btn-block"
                , type_ "submit"
                , remoteUserStakingInfo
                    |> RemoteData.unwrap True (not << isStaking)
                    |> disabled
                , onClick <| ShowWithdrawConfirmation True
                ]
                [ text "Withdraw earnings" ]
            ]
        ]


generalInfoAndCTA : Images -> Wallet -> Html Msg
generalInfoAndCTA images wallet =
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
                    [ text "Total balance" ]
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
                            , span [] [ text "Start staking" ]
                            ]
                        ]
                ]
            ]
        ]


viewStakingInfo : RemoteData StakingInfoError UserStakingInfo -> RemoteData StakingInfoError GeneralStakingInfo -> Html Msg
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


viewFidelity : RemoteData StakingInfoError UserStakingInfo -> Html Msg
viewFidelity _ =
    div [ class "my-3 card Appboard my-md-0 w-100", id "PlasmaPower" ]
        [ div [ class "p-4 card-body" ]
            [ h3 [ class "mb-0 text-center card-title" ]
                [ text "PlasmaPower" ]
            , p [ class "text-center text-muted" ]
                [ small []
                    [ text "Your staking fidelity" ]
                ]

            -- , div [ class "flex items-center justify-center flex-grow mx-auto flex-column w-75" ]
            -- [ View.Gauge.view 1 3
            -- ]
            -- , p [ class "mt-2 text-sm text-center alert text-muted" ]
            -- [ text "⚠ This gauge is not working yet ⚠"
            -- , br [] []
            -- , text "All the features required to show the information is there, we just need a bit more dev time to make it pretty, thanks for your patience and understanding"
            -- ]
            ]
        ]
