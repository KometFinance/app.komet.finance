import { provider } from 'web3-core'
import debug from './debug'
import { Addresses, getAccountInfo, monitorChanges } from './kometManager'
import * as KometManager from './kometManager'
import * as ports from './ports'

const connect = (app: any, prov: provider, addresses: Addresses) => async (withRequest: boolean) => {
  try {
    const info = await getAccountInfo(prov, addresses, withRequest)

    ports.updateWallet(app)({ ok: info })
  } catch (err) {
    ports.updateWallet(app)({
      err: withRequest // send the error on requested update
        ? debug.log('error while connecting -> ', err.message)
        : 'SOFT_CONNECT_FAILED'
    })
  }
}

const requestUserStakingInfo = (app: any, prov: provider, addresses: Addresses) => async (userAddress: string) => {
  try {
    const info = await KometManager.requestUserStakingInfo(prov, addresses.universe, userAddress)
    ports.updateUserStakingInfo(app)({ ok: info })
  } catch (err) {
    ports.updateUserStakingInfo(app)({ err: 'COULD_NOT_FETCHED' })
  }
}

const requestReward = (app: any, prov: provider, addresses: Addresses) => async (userAddress: string) => {
  try {
    const info = await KometManager.requestReward(prov, addresses.universe, userAddress)
    if (info) {
      ports.updateReward(app)({ ok: info })
    } else {
      debug('there was already someone waiting for it ... get in line')
    }
  } catch (err) {
    ports.updateReward(app)({ err: 'COULD_NOT_FETCHED' })
  }
}

const requestGeneralStakingInfo = (app: any, prov: provider, addresses: Addresses) => async () => {
  try {
    const info = await KometManager.requestGeneralStakingInfo(prov, addresses.universe)
    ports.updateGeneralStakingInfo(app)({ ok: info })
  } catch (err) {
    ports.updateGeneralStakingInfo(app)({ err: 'COULD_NOT_FETCHED' })
  }
}

const askContractApproval = (app: any, prov: provider, addresses: Addresses) => async ({
  userAddress,
  amount
}: {
    userAddress: string;
    amount: string;
}) => {
  debug({ userAddress, amount })
  try {
    if (!amount) {
      throw new Error('MISSING_AMOUNT')
    }
    const result = await KometManager.askContractApproval({
      prov,
      lpAddress: addresses.lp,
      universeAddress: addresses.universe,
      amount,
      userAddress
    })
    ports.contractApprovalResponse(app)({ ok: result })
  } catch (err) {
    ports.contractApprovalResponse(app)({ err: 'COULD_NOT_CONFIRM' })
  }
}

const deposit = (app: any, prov: provider, addresses: Addresses) => async ({
  userAddress,
  amount
}: {
    userAddress: string;
    amount: string;
}) => {
  try {
    if (!amount) {
      throw new Error('MISSING_AMOUNT')
    }
    const result = await KometManager.deposit({
      prov,
      universeAddress: addresses.universe,
      amount,
      userAddress
    })
    ports.depositResponse(app)({ ok: result })
  } catch (err) {
    ports.depositResponse(app)({ err: 'COULD_NOT_DEPOSIT' })
  }
}

const withdraw = (app: any, prov: provider, addresses: Addresses) => async ({
  userAddress,
  amount
}: {
    userAddress: string;
    amount: string;
}) => {
  try {
    if (!amount) {
      throw new Error('MISSING_AMOUNT')
    }
    const result = await KometManager.withdraw({
      prov,
      universeAddress: addresses.universe,
      amount,
      userAddress
    })
    ports.withdrawResponse(app)({ ok: result })
  } catch (err) {
    ports.withdrawResponse(app)({ err: 'COULD_NOT_WITHDRAW' })
  }
}

const getBuffRate = (app: any, prov: provider, addresses: Addresses) => async (userAddress: string) => {
  try {
    const result = await KometManager.getBuffRate(prov, addresses.universe, userAddress)
    ports.updateBuffRate(app)({ ok: result })
  } catch (err) {
    debug('getBuffRate errorred out ... ', err)
    ports.updateBuffRate(app)({ err: 'COULD_NOT_FETCHED' })
  }
}

const calculateFees = (app: any, prov: provider, addresses: Addresses) => async (userAddress: string) => {
  try {
    const result = await KometManager.calculateFees(prov, addresses.universe, userAddress)
    ports.updateFees(app)({ ok: result })
  } catch (err) {
    debug('calculateFees error ... ', err)
    ports.updateFees(app)({ err: 'COULD_NOT_FETCHED' })
  }
}

export const hook = (addresses: Addresses, prov: provider, app: any) => {
  ports.connectMetamask(app)(connect(app, prov, addresses))
  ports.requestUserStakingInfo(app)(requestUserStakingInfo(app, prov, addresses))
  ports.poolReward(app)(requestReward(app, prov, addresses))
  ports.requestGeneralStakingInfo(app)(requestGeneralStakingInfo(app, prov, addresses))
  ports.askContractApproval(app)(askContractApproval(app, prov, addresses))
  ports.sendDeposit(app)(deposit(app, prov, addresses))
  ports.getBuffRate(app)(getBuffRate(app, prov, addresses))
  ports.calculateFees(app)(calculateFees(app, prov, addresses))
  ports.withdraw(app)(withdraw(app, prov, addresses))

  // NOTE that should go in a better place but ...
  // let's listen to changes
  monitorChanges(prov, connect(app, prov, addresses))
}
