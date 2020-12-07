module Main exposing (main)

import Browser
import Model exposing (Model)
import Update exposing (Flags, Msg, init, subscriptions, update)
import View exposing (view)



-- if you think one file is not enough:
-- welcome to elm and have a watch https://www.youtube.com/watch?v=DoA4Txr4GUs
-- and while you're at it: https://www.youtube.com/watch?v=IcgmSRJHu_8
-- enjoy 🍿


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
