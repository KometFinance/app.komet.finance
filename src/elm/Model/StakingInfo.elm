module Model.StakingInfo exposing
    ( GeneralStakingInfo
    , RewardInfo
    , StakingInfoError(..)
    , UserStakingInfo
    , decoderApproval
    , decoderDeposit
    , decoderGeneralInfo
    , decoderReward
    , decoderUserInfo
    , decoderWithdraw
    , isStaking
    , minStaking
    )

import BigInt exposing (BigInt)
import Json.Decode exposing (Decoder)
import Json.Decode.Extra
import Json.Decode.Pipeline exposing (required)
import Model.Balance exposing (Balance, Fees)
import Time exposing (Posix)


minStaking : BigInt
minStaking =
    BigInt.pow (BigInt.fromInt 10) (BigInt.fromInt 17)


type alias UserStakingInfo =
    { lastStakedTime : Posix
    , amount : Balance
    }


type alias GeneralStakingInfo =
    { totalLpStaked : Balance
    }


type alias RewardInfo =
    { reward : Balance
    , fees : Fees
    }


type StakingInfoError
    = WrongJson Json.Decode.Error
    | SNAFU


isStaking : UserStakingInfo -> Bool
isStaking { lastStakedTime, amount } =
    Model.Balance.isPositive amount && lastStakedTime /= Time.millisToPosix 0


decoderUserInfo : Decoder UserStakingInfo
decoderUserInfo =
    Json.Decode.field "ok"
        (Json.Decode.succeed UserStakingInfo
            |> required "lastStakedTime"
                (Json.Decode.Extra.parseInt |> Json.Decode.map Time.millisToPosix)
            |> required "amount" Model.Balance.decoder
        )


decoderGeneralInfo : Decoder GeneralStakingInfo
decoderGeneralInfo =
    Json.Decode.field "ok"
        (Json.Decode.succeed GeneralStakingInfo
            |> required "totalLpStaked" Model.Balance.decoder
        )


decoderApproval : Decoder ()
decoderApproval =
    Json.Decode.field "ok"
        (Json.Decode.succeed ())


decoderDeposit : Decoder ()
decoderDeposit =
    Json.Decode.field "ok"
        (Json.Decode.succeed ())


decoderWithdraw : Decoder ()
decoderWithdraw =
    Json.Decode.field "ok"
        (Json.Decode.succeed ())


decoderReward : Decoder RewardInfo
decoderReward =
    Json.Decode.field "ok"
        (Json.Decode.succeed RewardInfo
            |> required "pending" Model.Balance.decoder
            |> required "fees" Json.Decode.Extra.parseInt
        )
