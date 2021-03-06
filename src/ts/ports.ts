// eslint-disable-next-line no-unused-vars
import debug from './debug'
import {
  AccountInfo,
  RewardData,
  StakingInfo,
  StakingState,
  OldState,
  Transaction
} from './kometManager'

export type Result<T> = { err: string } | { ok: T };

// from TS -> Elm
export const updateWallet = (app: any) => (payload: Result<AccountInfo>) => {
  app.ports.updateWallet.send(payload)
}

export const updateUserStakingInfo = (app: any) => (
  payload: Result<StakingInfo>
) => {
  app.ports.updateUserStakingInfo.send(payload)
}

export const updateGeneralStakingInfo = (app: any) => (
  payload: Result<StakingState>
) => {
  app.ports.updateGeneralStakingInfo.send(payload)
}

export const updateReward = (app: any) => (payload: Result<RewardData>) => {
  app.ports.updateReward.send(payload)
}

export const contractApprovalResponse = (app: any) => (
  payload: Result<Transaction>
) => {
  debug(payload)
  app.ports.contractApprovalResponse.send(payload)
}

export const depositResponse = (app: any) => (payload: Result<Transaction>) => {
  app.ports.depositResponse.send(payload)
}

export const withdrawResponse = (app: any) => (
  payload: Result<Transaction>
) => {
  app.ports.withdrawResponse.send(payload)
}

export const updateOldState = (app: any) => (payload: Result<OldState>) => {
  app.ports.updateOldState.send(payload)
}

export const updateEmergencyWithdrawal = (app: any) => (
  payload: Result<any>
) => {
  debug(payload)
  app.ports.updateEmergencyWithdrawal.send(payload)
}

export const reportExchange = (app: any) => (payload: Result<any>) => {
  debug(payload)
  app.ports.reportExchange.send(payload)
}

export const reportClaimRewards = (app: any) => (payload: Result<any>) => {
  debug(payload)
  app.ports.reportClaimRewards.send(payload)
}

// from Elm -> TS
export const connectMetamask = (app: any) => (
  onConnect: (withRequest: boolean) => void
) => {
  app.ports.connectMetamask.subscribe(onConnect)
}

export const requestUserStakingInfo = (app: any) => (
  onRequest: (address: string) => void
) => {
  app.ports.requestUserStakingInfo.subscribe(onRequest)
}

export const requestGeneralStakingInfo = (app: any) => (
  onRequest: () => void
) => {
  app.ports.requestGeneralStakingInfo.subscribe(onRequest)
}

export const poolReward = (app: any) => (
  onRequest: (userAddress: string) => void
) => {
  app.ports.poolReward.subscribe(onRequest)
}

export const askContractApproval = (app: any) => (
  onRequest: (request: {
    from: string;
    to: string;
    userAddress: string;
    amount: string;
  }) => void
) => {
  app.ports.askContractApproval.subscribe(onRequest)
}

export const sendDeposit = (app: any) => (
  onRequest: (request: { userAddress: string; amount: string }) => void
) => {
  app.ports.sendDeposit.subscribe(onRequest)
}

export const withdraw = (app: any) => (
  onRequest: (request: { userAddress: string; amount: string }) => void
) => {
  app.ports.withdraw.subscribe(onRequest)
}

export const requestOldState = (app: any) => (
  onRequest: (userAddress: string) => void
) => {
  app.ports.requestOldState.subscribe(onRequest)
}
export const requestEmergencyWithdrawal = (app: any) => (
  onRequest: (userAddress: string) => void
) => {
  app.ports.requestEmergencyWithdrawal.subscribe(onRequest)
}

export const exchangeNovaV1 = (app: any) => (
  onRequest: (request: { userAddress: string; amount: string }) => void
) => {
  app.ports.exchangeNovaV1.subscribe(onRequest)
}

export const claimRewards = (app: any) => (
  onRequest: (userAddress: string) => void
) => {
  app.ports.claimRewards.subscribe(onRequest)
}

export const copyToClipboard = (app: any) => (
  onRequest: (id: string) => void
) => {
  app.ports.copyToClipboard.subscribe(onRequest)
}
