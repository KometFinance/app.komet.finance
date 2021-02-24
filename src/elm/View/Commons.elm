module View.Commons exposing
    ( bugAlert
    , bugWarning
    , defaultError
    , defaultLoader
    , modal
    )

import Html exposing (Html, a, button, div, h5, p, span, text)
import Html.Attributes exposing (attribute, class, disabled, href, id, target, type_)
import Html.Attributes.Extra exposing (role)
import Html.Events exposing (onClick)
import Maybe.Extra
import RemoteData exposing (RemoteData(..))


defaultError : Html msg
defaultError =
    div [ class "p-0 italic alert text-warning", role "alert" ] [ text "No connection" ]


defaultLoader : Html msg
defaultLoader =
    div [ class "spinner-border text-primary w-28 h-28" ] []


type alias ModalConfig msg =
    { onClose : Maybe msg
    , progress : Int
    , content : Html msg
    }


modal : ModalConfig msg -> Html msg
modal { onClose, progress, content } =
    div
        [ attribute "aria-labelledby" "connect"
        , attribute "aria-modal" "true"
        , class "modal fade show"
        , id "StackingModal"
        , attribute "role" "dialog"
        , attribute "style" "display: block;"
        , attribute "tabindex" "-1"
        ]
        [ div [ class "modal-dialog" ]
            [ div [ class "bg-transparent modal-content" ]
                [ div [ class "modal-header" ]
                    [ button
                        [ attribute "aria-label" "Close"
                        , class "close"
                        , id "StackingModalButton"
                        , attribute "data-dismiss" "modal"
                        , type_ "button"
                        , Maybe.Extra.unwrap (disabled True) onClick onClose
                        ]
                        [ span [ attribute "aria-hidden" "true" ]
                            [ text "×" ]
                        ]
                    ]
                , div [ class "p-0 text-center modal-body" ]
                    [ div [ class "mx-auto card Appboard" ]
                        [ div [ class "progress" ]
                            [ div
                                [ attribute "aria-valuemax" "100"
                                , attribute "aria-valuemin" "0"
                                , attribute "aria-valuenow" <| String.fromInt progress
                                , class "progress-bar bg-primary"
                                , attribute "role" "progressbar"
                                , attribute "style" <| "width: " ++ String.fromInt progress ++ "%"
                                ]
                                []
                            ]
                        , div [ class "overflow-y-auto" ]
                            [ content
                            ]
                        ]
                    ]
                ]
            ]
        ]


bugAlert : Html msg
bugAlert =
    div [ class "mt-16 alert alert-danger", attribute "role" "alert" ]
        [ h5 [ class "mb-0 mr-3 alert-heading" ]
            [ text "Woops, we have an issue" ]
        , p [ class "text-justify" ]
            [ text "Due to an issue in our smart contract, if you stake without withdrawing LP for more than 60 days the fees are broken, and you can no longer claim your NOVAs. We are aware of this issue and if you end up stuck please bear with us for a bit longer. We are working on the next version of NOVA and you will get compensated for your wait. For more details, "
            , a [ href "https://kometcapital.medium.com/concerning-the-fee-issue-on-nova-714efe1139e0", target "blank_", class "text-black" ] [ text "check this article" ]
            , text "."
            ]
        ]


bugWarning : Html msg
bugWarning =
    div [ class "mt-16 alert alert-warning", attribute "role" "alert" ]
        [ h5 [ class "mb-0 mr-3 alert-heading" ]
            [ text "Beware, we have an issue" ]
        , p [ class "text-justify" ]
            [ text "Due to an error in our smart contract, if you stake for longer than 60 days your rewards will temporarily get stuck in the contract. We are aware of the issue and will provide you with a simple migration tool. You can read more about this issue "
            , a [ href "https://kometcapital.medium.com/concerning-the-fee-issue-on-nova-714efe1139e0", target "blank_", class "text-black" ] [ text "here" ]
            , text "."
            ]
        ]
