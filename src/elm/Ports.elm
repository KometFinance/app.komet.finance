port module Ports exposing
    ( askContractApproval
    , connectMetamask
    , contractApprovalResponse
    , depositResponse
    , poolReward
    , requestGeneralStakingInfo
    , requestOldState
    , requestUserStakingInfo
    , sendDeposit
    , updateGeneralStakingInfo
    , updateOldState
    , updateReward
    , updateUserStakingInfo
    , updateWallet
    , withdraw
    , withdrawResponse
    )

import Json.Decode
import Json.Encode


port connectMetamask : Bool -> Cmd msg


port updateWallet : (Json.Decode.Value -> msg) -> Sub msg


port requestUserStakingInfo : String -> Cmd msg


port updateUserStakingInfo : (Json.Decode.Value -> msg) -> Sub msg


port requestGeneralStakingInfo : () -> Cmd msg


port updateGeneralStakingInfo : (Json.Decode.Value -> msg) -> Sub msg


port askContractApproval : Json.Encode.Value -> Cmd msg


port contractApprovalResponse : (Json.Encode.Value -> msg) -> Sub msg


port sendDeposit : Json.Encode.Value -> Cmd msg


port depositResponse : (Json.Encode.Value -> msg) -> Sub msg


port withdraw : Json.Encode.Value -> Cmd msg


port withdrawResponse : (Json.Encode.Value -> msg) -> Sub msg


port updateReward : (Json.Decode.Value -> msg) -> Sub msg


port poolReward : String -> Cmd msg


port requestOldState : String -> Cmd msg


port updateOldState : (Json.Decode.Value -> msg) -> Sub msg
