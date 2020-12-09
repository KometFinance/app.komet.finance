module View.Commons exposing
    ( defaultError
    , defaultLoader
    , modal
    )

import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (attribute, class, disabled, id, type_)
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
                        , content
                        ]
                    ]
                ]
            ]
        ]
