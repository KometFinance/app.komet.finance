module View.Commons exposing (defaultError, defaultLoader)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Html.Attributes.Extra exposing (role)


defaultError : Html msg
defaultError =
    div [ class "p-0 italic alert text-warning", role "alert" ] [ text "No connection" ]


defaultLoader : Html msg
defaultLoader =
    div [ class "spinner-border text-primary w-28 h-28" ] []
