module Model exposing
    ( AmountInputForm
    , Images
    , Modal(..)
    , Model
    , StakingFormStage(..)
    , WithdrawInputForm
    , defaultAmountInputForm
    , defaultWithdrawInfo
    )

import BigInt exposing (BigInt)
import Browser.Events
import Model.OldState exposing (MigrationState, OldState)
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
    | WithdrawDetail WithdrawInputForm
    | ConfirmRewardClaim (RemoteData () ())
    | FeeExplanation
    | MigrationDetail MigrationState


type alias WithdrawInputForm =
    { amount : BigInt
    , amountInput : String
    , request : RemoteData () ()
    }


defaultWithdrawInfo : WithdrawInputForm
defaultWithdrawInfo =
    { amount = BigInt.fromInt 0
    , amountInput = ""
    , request = RemoteData.NotAsked
    }


type StakingFormStage
    = PendingApproval
    | PendingStaking


type alias AmountInputForm =
    { amount : BigInt
    , amountInput : String
    , stage : StakingFormStage
    , request : RemoteData () ()
    }


defaultAmountInputForm : AmountInputForm
defaultAmountInputForm =
    { amount = BigInt.fromInt 0
    , amountInput = ""
    , stage = PendingApproval
    , request = NotAsked
    }


type alias Model =
    { images : Images
    , wallet : RemoteData WalletError Wallet
    , modal : Maybe Modal
    , userStakingInfo : RemoteData StakingInfoError UserStakingInfo
    , rewardInfo : RemoteData StakingInfoError RewardInfo
    , generalStakingInfo : RemoteData StakingInfoError GeneralStakingInfo
    , oldState : RemoteData () OldState
    , visibility : Browser.Events.Visibility
    }
