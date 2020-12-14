port module Ports exposing
    ( Contract(..)
    , connectMetamask
    , contractApprovalResponse
    , depositResponse
    , poolReward
    , requestContractApproval
    , requestEmergencyWithdrawal
    , requestGeneralStakingInfo
    , requestOldState
    , requestUserStakingInfo
    , sendDeposit
    , updateEmergencyWithdrawal
    , updateGeneralStakingInfo
    , updateOldState
    , updateReward
    , updateUserStakingInfo
    , updateWallet
    , withdraw
    , withdrawResponse
    )

import BigInt exposing (BigInt)
import Json.Decode
import Json.Encode
import Utils.BigInt


port connectMetamask : Bool -> Cmd msg


port updateWallet : (Json.Decode.Value -> msg) -> Sub msg


port requestUserStakingInfo : String -> Cmd msg


port updateUserStakingInfo : (Json.Decode.Value -> msg) -> Sub msg


port requestGeneralStakingInfo : () -> Cmd msg


port updateGeneralStakingInfo : (Json.Decode.Value -> msg) -> Sub msg


type Contract
    = LPToken
    | OldNova
    | MasterUniverse
    | NovaMigration


encodeContract : Contract -> Json.Encode.Value
encodeContract contract =
    case contract of
        LPToken ->
            Json.Encode.string "LPToken"

        OldNova ->
            Json.Encode.string "NOVA-V1"

        MasterUniverse ->
            Json.Encode.string "MasterUniverse"

        NovaMigration ->
            Json.Encode.string "NovaMigration"


requestContractApproval : { from : Contract, to : Contract, userAddress : String, amount : BigInt } -> Cmd msg
requestContractApproval { from, to, userAddress, amount } =
    askContractApproval <|
        Json.Encode.object
            [ ( "userAddress", Json.Encode.string userAddress )
            , ( "amount", Utils.BigInt.encode amount )
            , ( "from", encodeContract from )
            , ( "to", encodeContract to )
            ]


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


port requestEmergencyWithdrawal : String -> Cmd msg


port updateEmergencyWithdrawal : (Json.Decode.Value -> msg) -> Sub msg
