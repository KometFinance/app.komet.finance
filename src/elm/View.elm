module View exposing (view)

import Browser exposing (Document)
import Html exposing (Html, a, button, div, footer, img, li, nav, small, span, text, ul)
import Html.Attributes exposing (alt, attribute, class, href, id, src, style, target, type_, width)
import Html.Attributes.Extra exposing (role)
import Html.Events exposing (onClick)
import Html.Extra exposing (viewMaybe)
import Model exposing (Images, Model, StakingFormStage(..))
import Model.Balance exposing (Balance, humanReadableBalance)
import Model.Wallet exposing (Wallet, WalletError(..))
import RemoteData exposing (RemoteData(..))
import Update exposing (Msg(..))
import View.AmountForm exposing (stakingModal, withdrawModal)
import View.Commons exposing (defaultLoader)
import View.Dashboard exposing (dashboard)


view : Model -> Document Msg
view ({ wallet, userStakingInfo, rewardInfo, images, modal } as model) =
    { title = "KOMET"
    , body =
        [ div [ class "overflow-hidden light_1", style "top" "300px" ] []
        , div [ class "overflow-hidden light_2", style "top" "300px" ] []
        , div [ id "app", class "relative flex flex-col p-0 container-fluid" ]
            [ div [ class "flex flex-col flex-grow" ]
                [ header model
                , div [ class "p-2 m-8 mt-24 text-center alert alert-warning", role "alert" ]
                    [ text "Withdraw and Staking are disabled while we are investigating a gas consumption issue. Check our "
                    , a [ class "font-bold alert-link", href "https://t.me/kometFinance" ] [ text "announcement channel" ]
                    , text " on telegram for updates."
                    ]
                , div [ id "dashboard", class "flex flex-col items-center flex-grow w-full pt-8" ]
                    [ div [ class "flex flex-col items-center justify-center flex-grow w-full" ]
                        [ let
                            connectButton =
                                button
                                    [ class "px-4 my-2 btn btn-primary my-sm-0"
                                    , onClick <| Connect
                                    ]
                                    [ text "Connect" ]
                          in
                          case wallet of
                            NotAsked ->
                                connectButton

                            Loading ->
                                defaultLoader

                            Failure SoftConnectFailed ->
                                div [ class "" ]
                                    [ text "Oh no! It looks like you have not connected your wallet."
                                    , connectButton
                                    ]

                            Failure MissingContracts ->
                                div [ class "" ]
                                    [ text "Oh no! It appears the contract are not deployed at the proper address on your network. You should probably try another network in metamask and retry."
                                    , connectButton
                                    ]

                            Failure _ ->
                                -- other types of failure: aka ContractNotDeployed or WrongJson
                                div [ class "flex items-center justify-center flex-column" ]
                                    [ connectButton
                                    ]

                            Success _ ->
                                dashboard model
                        ]
                    , modal
                        |> viewMaybe
                            (\justModal ->
                                case justModal of
                                    Model.MoneyDetail ->
                                        div []
                                            [ Html.Extra.nothing
                                            , div [ class "modal-backdrop fade show" ] []
                                            ]

                                    Model.StakingDetail stakingForm ->
                                        RemoteData.unwrap Html.Extra.nothing
                                            (\wallet_ ->
                                                div []
                                                    [ stakingModal images stakingForm wallet_
                                                    , div [ class "modal-backdrop fade show" ] []
                                                    ]
                                            )
                                            wallet

                                    Model.WithdrawDetail fees ->
                                        RemoteData.map2
                                            (\userStakingInfo_ rewardInfo_ ->
                                                div []
                                                    [ withdrawModal images fees userStakingInfo_ rewardInfo_
                                                    , div [ class "modal-backdrop fade show" ] []
                                                    ]
                                            )
                                            userStakingInfo
                                            rewardInfo
                                            |> RemoteData.withDefault Html.Extra.nothing
                            )
                    , appFooter images
                    ]
                ]
            ]
        ]
    }


header : Model -> Html.Html msg
header { images, wallet } =
    nav [ id "AppTopbar", class "pb-3 fixed-top bg_darknav" ]
        [ div [ class "flex justify-end" ]
            [ a [ class "mr-auto navbar-brand", href "#" ]
                [ img [ src images.appLogo, width 30, class "align-top d-inline-block", alt "Komet logo", attribute "loading" "lazy" ] []
                , span [ class "sr-only" ] [ text "Komet" ]
                ]
            , wallet
                |> RemoteData.toMaybe
                |> viewMaybe (viewAddress images)
            , wallet
                |> RemoteData.toMaybe
                |> viewMaybe
                    walletOverview
            ]
        ]


viewAddress : Images -> Wallet -> Html msg
viewAddress images { address } =
    div [ class "ml-auto mr-4 card" ]
        [ div [ class "py-1 align-items-center card-body d-flex" ]
            [ img [ alt "Metamask Fox Icon", class "mr-2", src images.metamaskFox, attribute "width" "26" ]
                []
            , a [ class "d-inline-block stretched-link", attribute "style" "max-width: 120px" ]
                [ text <| ellipseAddress address ]
            ]
        ]


walletOverview : Wallet -> Html msg
walletOverview { lpBalance, ethBalance, kometBalance, novaBalance } =
    ul [ class "mb-0 mr-2 list-inline list-unstyled align-items-center d-flex" ] <|
        List.map coinPull
            [ ( "lp", lpBalance, "LP" )
            , ( "komet", kometBalance, "KOMET" )
            , ( "nova", novaBalance, "NOVA" )
            , ( "eth", ethBalance, "ETH" )
            ]


coinPull : ( String, Balance, String ) -> Html msg
coinPull ( badgeSuffix, balance, moneyTag ) =
    li [ class "list-inline-item" ]
        [ button
            [ class "btn btn-sm btn-dark d-flex align-items-center"

            -- TODO replace that with a proper modal stuff
            , attribute "data-target" "#LPmodal"
            , attribute "data-toggle" "modal"
            , type_ "button"
            ]
            [ span [ class <| "mr-2 badge badge-" ++ badgeSuffix ]
                []
            , text <| humanReadableBalance 1 balance
            , small [ class "ml-2 text-muted" ]
                [ text moneyTag ]
            ]
        ]


ellipseAddress : String -> String
ellipseAddress address =
    [ String.left 6 address, String.right 4 address ] |> String.join "..."


appFooter : Images -> Html Msg
appFooter images =
    div [ class "container pt-2 mt-5 pt-md-5" ]
        [ footer [ class "col-12" ]
            [ div [ class "bottombar col-12" ]
                []
            , nav [ class "col-12 navbar navbar-expand-lg navbar-light" ]
                [ div [ class "ml-auto" ]
                    [ ul [ class "list-inline" ]
                        [ li [ class "mr-0 list-inline-item" ]
                            [ a [ class "nav-link text-primary", href "https://financekomet.medium.com", target "_blank" ]
                                [ img [ src images.medium, attribute "width" "26" ]
                                    []
                                , span [ class "sr-only" ]
                                    [ text "Medium" ]
                                ]
                            ]
                        , li [ class "mr-0 list-inline-item" ]
                            [ a [ class "nav-link text-primary", href "https://t.me/KometFinanceCommunit", target "_blank" ]
                                [ img [ src images.telegram, attribute "width" "26" ]
                                    []
                                , span [ class "sr-only" ]
                                    [ text "Télégram" ]
                                ]
                            ]
                        , li [ class "mr-0 list-inline-item" ]
                            [ a [ class "nav-link text-primary", href "https://twitter.com/FinanceKomet", target "_blank" ]
                                [ img [ src images.twitter, attribute "width" "26" ]
                                    []
                                , span [ class "sr-only" ]
                                    [ text "Twitter" ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
