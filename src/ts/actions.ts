import Web3 from 'web3'
import { Addresses, getAccountInfo, monitorChanges } from './kometManager'
import * as KometManager from './kometManager'
import * as ports from './ports'

const connect = (app: any, web3: Web3, addresses: Addresses) => async (
  withRequest: boolean
) => {
  try {
    const info = await getAccountInfo(web3, addresses, withRequest)

    ports.updateWallet(app)({ ok: info })
  } catch (err) {
    ports.updateWallet(app)({
      err: withRequest // send the error on requested update
        ? err.message
        : 'SOFT_CONNECT_FAILED'
    })
  }
}

const requestUserStakingInfo = (
  app: any,
  web3: Web3,
  addresses: Addresses
) => async (userAddress: string) => {
  try {
    const info = await KometManager.requestUserStakingInfo(
      web3,
      addresses.universe,
      userAddress
    )
    ports.updateUserStakingInfo(app)({ ok: info })
  } catch (err) {
    ports.updateUserStakingInfo(app)({ err: 'COULD_NOT_FETCHED' })
  }
}

const requestReward = (app: any, web3: Web3, addresses: Addresses) => async (
  userAddress: string
) => {
  try {
    const info = await KometManager.requestReward(
      web3,
      addresses.universe,
      userAddress
    )
    if (info) {
      ports.updateReward(app)({ ok: info })
    } else {
      // already a request ongoing for that ... let's wait for the return
    }
  } catch (err) {
    ports.updateReward(app)({ err: 'COULD_NOT_FETCHED' })
  }
}

const requestGeneralStakingInfo = (
  app: any,
  web3: Web3,
  addresses: Addresses
) => async () => {
  try {
    const info = await KometManager.requestGeneralStakingInfo(
      web3,
      addresses.universe
    )
    ports.updateGeneralStakingInfo(app)({ ok: info })
  } catch (err) {
    ports.updateGeneralStakingInfo(app)({ err: 'COULD_NOT_FETCHED' })
  }
}

const askContractApproval = (
  app: any,
  web3: Web3,
  addresses: Addresses
) => async ({
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
    const result = await KometManager.askContractApproval({
      web3,
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

const deposit = (app: any, web3: Web3, addresses: Addresses) => async ({
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
      web3,
      universeAddress: addresses.universe,
      amount,
      userAddress
    })
    ports.depositResponse(app)({ ok: result })
  } catch (err) {
    ports.depositResponse(app)({ err: 'COULD_NOT_DEPOSIT' })
  }
}

const withdraw = (app: any, web3: Web3, addresses: Addresses) => async ({
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
      web3,
      universeAddress: addresses.universe,
      amount,
      userAddress
    })
    ports.withdrawResponse(app)({ ok: result })
  } catch (err) {
    ports.withdrawResponse(app)({ err: 'COULD_NOT_WITHDRAW' })
  }
}

export const hook = (addresses: Addresses, web3: Web3, app: any) => {
  ports.connectMetamask(app)(connect(app, web3, addresses))
  ports.requestUserStakingInfo(app)(
    requestUserStakingInfo(app, web3, addresses)
  )
  ports.poolReward(app)(requestReward(app, web3, addresses))
  ports.requestGeneralStakingInfo(app)(
    requestGeneralStakingInfo(app, web3, addresses)
  )
  ports.askContractApproval(app)(askContractApproval(app, web3, addresses))
  ports.sendDeposit(app)(deposit(app, web3, addresses))
  ports.withdraw(app)(withdraw(app, web3, addresses))

  // NOTE that should go in a better place but ...
  // let's listen to changes
  monitorChanges(web3, connect(app, web3, addresses))
}
