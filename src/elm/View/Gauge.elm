module View.Gauge exposing (view)

import Html exposing (Html, node, text)
import Html.Attributes exposing (attribute, id)
import Svg exposing (g, path, svg)
import Svg.Attributes exposing (d, fill, viewBox)


view : Int -> Int -> Html msg
view currentPower maxPower =
    svg
        [ viewBox "0 0 357 200"
        ]
        [ node "title"
            []
            [ text "diagram" ]
        , g [ fill "none", attribute "fill-rule" "evenodd", id "app", attribute "stroke" "none", attribute "stroke-width" "1" ]
            [ g [ id "PlasmaPower", attribute "transform" "translate(-341.000000, -252.000000)" ]
                [ g [ id "box", attribute "transform" "translate(292.000000, 90.500000)" ]
                    [ g [ id "diagram", attribute "transform" "translate(49.000000, 161.500000)" ]
                        [ path
                            [ d "M172.965116,0 C262.708461,0 335.823283,78.3770684 338.91014,176.345031 L331.566262,176.345031 C328.481729,82.8788581 258.653906,8.1496519 172.965116,8.1496519 C87.2763264,8.1496519 17.4485036,82.8788581 14.3639708,176.345031 L7.02009236,176.345031 C10.10695,78.3770684 83.2217717,0 172.965116,0 Z"
                            , fill "#76FFBA"
                            , id "Path"
                            ]
                            []
                        , path
                            [ d "M204.744929,37.5690548 L204.745278,180.543047 C207.571167,180.804641 209.790432,183.406919 209.790432,186.578541 C209.790432,189.923797 207.321524,192.635663 204.275972,192.635663 C201.23042,192.635663 198.761512,189.923797 198.761512,186.578541 C198.761512,183.515631 200.831248,180.983704 203.518285,180.578125 L203.519493,37.5690548 L204.744929,37.5690548 Z"
                            , id "arrow"
                            , attribute "stroke" "#76FFBA"
                            , attribute "transform" <| "translate(204.275972, 115.102359) rotate(-330.00000) translate(-204.275972, -115.102359) "
                            ]
                            []
                        , g [ attribute "font-family" "DMSans-Medium, DM Sans", attribute "font-weight" "400", id "texts", attribute "transform" "translate(0.000000, 89.158621)" ]
                            [ node "text"
                                [ fill "#CDFFE6", attribute "font-size" "10", id "0", attribute "letter-spacing" "0.2777778" ]
                                [ node "tspan"
                                    [ attribute "x" "3.96157622", attribute "y" "106.331034" ]
                                    [ text "0" ]
                                ]
                            , node "text"
                                [ fill "#CDFFE6", attribute "font-size" "10", id "3", attribute "letter-spacing" "0.2777778" ]
                                [ node "tspan"
                                    [ attribute "x" "334.529018", attribute "y" "106.331034" ]
                                    [ text "3" ]
                                ]
                            , node "text"
                                [ fill "#FFFFFF", attribute "font-size" "24", id "2/3", attribute "letter-spacing" "0.6666666" ]
                                [ node "tspan"
                                    [ attribute "x" "158.248977", attribute "y" "24" ]
                                    [ text <| String.fromInt currentPower ++ "/" ++ String.fromInt maxPower ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
