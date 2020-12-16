module View exposing (view)

import Browser exposing (Document)
import Html exposing (Html, a, br, button, div, footer, h1, h3, h4, i, img, li, nav, p, small, span, text, ul)
import Html.Attributes exposing (alt, attribute, class, disabled, href, id, src, style, target, type_, width)
import Html.Events exposing (onClick)
import Html.Extra exposing (viewMaybe)
import Model exposing (Images, Model, StakingFormStage(..))
import Model.Balance exposing (Balance, humanReadableBalance)
import Model.OldState exposing (MigrationState, MigrationStep(..), OldState)
import Model.Wallet exposing (Wallet, WalletError(..))
import RemoteData exposing (RemoteData(..))
import Update exposing (Msg(..))
import View.AmountForm exposing (confirmRewardClaimModal, stakingModal, withdrawModal)
import View.Commons exposing (defaultLoader, modal)
import View.Dashboard exposing (dashboard)


view : Model -> Document Msg
view ({ wallet, oldState, userStakingInfo, rewardInfo, images, modal } as model) =
    { title = "KOMET"
    , body =
        [ div [ class "overflow-hidden light_1", style "top" "300px" ] []
        , div [ class "overflow-hidden light_2", style "top" "300px" ] []
        , div [ id "app", class "relative flex flex-col p-0 container-fluid" ]
            [ div [ class "flex flex-col flex-grow" ]
                [ header model
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
                                div [ class "flex flex-col space-y-2" ]
                                    [ text "Oh no! It looks like you have not connected your wallet."
                                    , connectButton
                                    ]

                            Failure MissingContracts ->
                                div [ class "flex flex-col space-y-2" ]
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
                                                    [ stakingModal stakingForm wallet_ <|
                                                        RemoteData.toMaybe <|
                                                            RemoteData.map2 Tuple.pair
                                                                model.userStakingInfo
                                                                model.rewardInfo
                                                    , div [ class "modal-backdrop fade show" ] []
                                                    ]
                                            )
                                            wallet

                                    Model.WithdrawDetail form ->
                                        RemoteData.map2
                                            (\userStakingInfo_ rewardInfo_ ->
                                                div []
                                                    [ withdrawModal form userStakingInfo_ rewardInfo_
                                                    , div [ class "modal-backdrop fade show" ] []
                                                    ]
                                            )
                                            userStakingInfo
                                            rewardInfo
                                            |> RemoteData.withDefault Html.Extra.nothing

                                    Model.ConfirmRewardClaim request ->
                                        RemoteData.map2
                                            (\userStakingInfo_ rewardInfo_ ->
                                                div []
                                                    [ confirmRewardClaimModal request userStakingInfo_ rewardInfo_
                                                    , div
                                                        [ class "modal-backdrop fade show"
                                                        ]
                                                        []
                                                    ]
                                            )
                                            userStakingInfo
                                            rewardInfo
                                            |> RemoteData.withDefault Html.Extra.nothing

                                    Model.FeeExplanation ->
                                        div [ onClick <| ShowFeeExplanation False ]
                                            [ feeExplanationModal
                                            , div
                                                [ onClick <| ShowFeeExplanation False
                                                , class "modal-backdrop fade show"
                                                ]
                                                []
                                            ]

                                    Model.MigrationDetail state ->
                                        oldState
                                            |> RemoteData.unwrap Html.Extra.nothing
                                                (\oldStuff ->
                                                    div []
                                                        [ migrationModal oldStuff state
                                                        , div [ class "modal-backdrop fade show" ] []
                                                        ]
                                                )
                            )
                    , appFooter images
                    ]
                ]
            ]
        ]
    }


feeExplanationModal : Html Msg
feeExplanationModal =
    modal
        { onClose = Just <| ShowFeeExplanation False
        , progress = 0
        , content =
            div []
                [ p [ class "text-justify" ]
                    [ text "Fees only apply to withdrawing the NOVA you get as a reward for staking. "
                    , span [ class "text-primary" ]
                        [ text "We will never tax your KOMET/ETH LP tokens transactions!" ]
                    , br [] []
                    , text <| "Fees start at "
                    , span [ class "text-secondary" ] [ text "30%" ]
                    , text " and decrease by "
                    , span [ class "text-primary" ] [ text "1%" ]
                    , text " every second day until reaching "
                    , span [ class "text-prumary" ]
                        [ text
                            "1%"
                        ]
                    , text " (60 days after staking)."
                    ]
                , p [ class "text-justify" ]
                    [ span [ class "font-bold" ] [ text "Remember:" ]
                    , text " adding funds to your stake will not reset the fee counter. You will claim your NOVA rewards when adding to your stake but your fees won't reset to 30%."
                    , br [] []
                    , text "E.g.: if you have 10 NOVA waiting as rewards when adding to your stake and you have been staking for 10 days, your fee level will be at 25%. You will receive 7.5 NOVA but your fees will remain 25% and continue to decrease every day."
                    , br [] []
                    , text "The same applies if you use the button claim rewards, however if you elect to withdraw all or part of your stake, your fees will reset to 30%."
                    , br [] []
                    , text "E.g. you have been staking for 30 days, your fees are now at 15%, and you have 20 NOVA as a pending reward. Withdrawing any amount of your stake at this point means you will receive 17 NOVA, but your fees will then go back to 30%."
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


migrationModal : OldState -> MigrationState -> Html Msg
migrationModal { oldNova, oldStaking } ({ currentStep } as state) =
    modal
        { onClose =
            case currentStep of
                Start ->
                    Just <| ShowMigrationPanel False

                Done ->
                    Just <| ShowMigrationPanel False

                _ ->
                    Nothing

        --  TODO calculate the progress nicely based on what's required
        , progress = 0
        , content =
            let
                isRunning =
                    case currentStep of
                        Start ->
                            False

                        Done ->
                            False

                        _ ->
                            True
            in
            div [ class "p-5 card-body" ]
                [ h3 [ class "text-center card-title" ]
                    [ text "Migration to NOVA V2"
                    ]

                -- , h4 [ class "mt-4 mb-2 text-center gradient_lp display-3" ] [ text  ]
                , p [ class "mb-5 text-muted" ]
                    [ small [] [ text "This helper will run all the required steps to migrate your old assets to the new eco system" ] ]
                , div [ class "flex flex-col mt-8 mb-12" ]
                    [ h1 [ class "pl-4 text-xl text-left" ] [ text "Steps to migrate" ]
                    , div [ class "p-4 text-left card text-muted space-y-2" ]
                        [ Html.Extra.viewIf (Model.Balance.isPositive oldNova) <|
                            div [ class "flex flex-col space-y-2" ] <|
                                h4 [ class "pt-2 pb-0 mb-0 text-lg text-muted" ]
                                    [ text <| "Migrating " ++ Model.Balance.humanReadableBalance 2 oldNova ++ " NOVA V1 to "
                                    , span [ class "text-secondary" ] [ text <| Model.Balance.humanReadableBalance 2 oldNova ]
                                    , text " NOVA V2"
                                    ]
                                    :: List.map viewStep
                                        [ ( "requiring permission to transfer the NOVA V1", state.approvingNovaTransition )
                                        , ( "exchanging NOVA V1 with NOVA V2", state.transferingNova )
                                        ]
                        , Html.Extra.viewIf (Model.Balance.isPositive oldStaking) <|
                            div [ class "flex flex-col space-y-2" ] <|
                                h4 [ class "pt-2 pb-0 mb-0 text-lg text-muted" ]
                                    [ text "Migrating V1 staking to V2 stating" ]
                                    :: List.map viewStep
                                        [ ( "withdrawing LP token from Master Universe V1", state.withdrawal )
                                        , ( "claiming Rewards from the migration contract", state.claimRewards )
                                        , ( "depositing on Master Universe V2", state.approvingDeposit |> RemoteData.andThen (\_ -> state.deposit) )
                                        ]
                        ]
                    ]
                , button
                    [ class "flex flex-row items-center justify-center mb-0 space-x-8 btn btn-block btn-primary btn-lg"
                    , disabled isRunning
                    , onClick <|
                        case currentStep of
                            Start ->
                                StartMigration

                            Done ->
                                -- TODO check for retry
                                ShowMigrationPanel False

                            _ ->
                                NoOp
                    ]
                  <|
                    case currentStep of
                        Start ->
                            [ text "Start" ]

                        Done ->
                            [ text "Done" ]

                        _ ->
                            [ span [ class "spinner-border" ] []
                            , span [] [ text "Migrating..." ]
                            ]
                ]
        }


viewStep : ( String, RemoteData () () ) -> Html Msg
viewStep ( name, state ) =
    div [ class "flex flex-row items-center h-8 space-x-4" ]
        [ case state of
            NotAsked ->
                span [ class "w-4 text-secondary" ] [ i [ class "bi bi-check2" ] [] ]

            Loading ->
                span [ class "w-4 text-primary" ] [ span [ class "spinner-border spinner-border-sm" ] [] ]

            Failure () ->
                span [ class "w-4 text-danger" ] [ i [ class "bi bi-exclamation-circle" ] [] ]

            Success () ->
                span [ class "w-4 text-primary" ] [ i [ class "bi bi-check2-circle" ] [] ]
        , span
            [ if RemoteData.isLoading state then
                class "text-secondary"

              else
                class "text-muted"
            ]
            [ text name
            ]
        ]
