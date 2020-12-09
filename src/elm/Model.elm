module Model exposing
    ( AmountInputForm
    , Images
    , Modal(..)
    , Model
    , StakingFormStage(..)
    , WithdrawInfo
    , defaultAmountInputForm
    , defaultWithdrawInfo
    )

import BigInt exposing (BigInt)
import Model.StakingInfo exposing (GeneralStakingInfo, RewardInfo, StakingInfoError, UserStakingInfo)
import Model.Wallet exposing (Wallet, WalletError)
import RemoteData exposing (RemoteData(..))


type alias Images =
    { appLogo : String
    , logo : String
    , kometToken : String
    , ethToken : String
    , metamaskFox : String
    , medium : String
    , telegram : String
    , twitter : String
    , stakingGem : String
    , externalLink : String
    }


type Modal
    = -- for now that will only be for the LP token but who knows.
      MoneyDetail
    | StakingDetail AmountInputForm
    | WithdrawDetail WithdrawInfo


type alias WithdrawInfo =
    { withdrawRequest : RemoteData () ()
    }


defaultWithdrawInfo : WithdrawInfo
defaultWithdrawInfo =
    { withdrawRequest = RemoteData.NotAsked }


type StakingFormStage
    = PendingApproval
    | PendingStaking


type alias AmountInputForm =
    { amountToStake : BigInt
    , amountInput : String
    , stage : StakingFormStage
    , stakingRequest : RemoteData () ()
    }


defaultAmountInputForm : AmountInputForm
defaultAmountInputForm =
    { amountToStake = BigInt.fromInt 0
    , amountInput = ""
    , stage = PendingApproval
    , stakingRequest = NotAsked
    }


type alias Model =
    { images : Images
    , wallet : RemoteData WalletError Wallet
    , modal : Maybe Modal
    , userStakingInfo : RemoteData StakingInfoError UserStakingInfo
    , rewardInfo : RemoteData StakingInfoError RewardInfo
    , generalStakingInfo : RemoteData StakingInfoError GeneralStakingInfo
    }
