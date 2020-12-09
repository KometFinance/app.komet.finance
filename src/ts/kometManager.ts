import Web3 from 'web3'
import { provider } from 'web3-core'
import { AbiItem } from 'web3-utils'
import ERC20ABI from '../../abis/ERC20.json'
import UNIVERSE from '../../abis/MasterUniverse.json'
import debug from './debug'
// eslint-disable-next-line no-unused-vars

const MAX_TIMEOUT = 30 * 1000 // 30 seconds

export const getERC20Contract = (prov: provider, address: string) => {
  const web3 = new Web3(prov)
  const contract = new web3.eth.Contract(
    (ERC20ABI.abi as unknown) as AbiItem,
    address
  )
  return contract
}

export const getBalance = async (
  prov: provider,
  tokenAddress: string,
  userAddress: string
): Promise<string> => {
  try {
    const contract = getERC20Contract(prov, tokenAddress)
    const balance: string = await contract.methods
      .balanceOf(userAddress)
      .call()
    return balance
  } catch (_) {
    return '0'
  }
}

export type Addresses = {
  komet: string;
  lp: string;
  nova: string;
  universe: string;
};

export type AccountInfo = {
  account: string;
  eth: string;
  komet: string;
  lp: string;
  nova: string;
};

export const getAccountInfo = async (
  prov: provider,
  addresses: Addresses,
  withRequest: boolean
): Promise<AccountInfo> => {
  const web3 = new Web3(prov)

  const allAccounts = withRequest
    ? await web3.eth.requestAccounts()
    : await web3.eth.getAccounts()
  const userAddress = allAccounts[0]
  if (!userAddress) {
    throw new Error('NO_ACCOUNTS')
  }
  const response = await Promise.race([
    Promise.all([
      getBalance(prov, addresses.lp, userAddress),
      getBalance(prov, addresses.nova, userAddress),
      getBalance(prov, addresses.komet, userAddress),
      web3.eth.getBalance(userAddress)
    ]).then(([lp, nova, komet, eth]) => ({
      account: userAddress,
      eth,
      komet,
      lp,
      nova
    })),
    // eslint-disable-next-line promise/param-names
    new Promise((_, reject) => {
      setTimeout(() => reject(new Error('CONTRACT_NOT_FOUND')), MAX_TIMEOUT)
    })
  ])
  debug('yeah or neee', response)
  return response as AccountInfo
}

export const monitorChanges = (
  prov: provider,
  onAccountsChanged: (withRequest: boolean) => void
) => {
  const web3 = new Web3(prov)
  web3.currentProvider.on('chainChanged', (_) => {
    location.reload()
  })
  web3.currentProvider.on('accountsChanged', (accounts: any[]) => {
    if (accounts.length > 0) {
      onAccountsChanged(true)
    } else {
      // do nothing
    }
  })
}

export type StakingInfo = {
  lastStakedTime: string;
  amount: string;
  rewardDebt: string;
};

export const requestUserStakingInfo = async (
  prov: provider,
  universeAddress: string,
  userAddress: string
): Promise<StakingInfo> => {
  const web3 = new Web3(prov)
  const universeContract = new web3.eth.Contract(
    (UNIVERSE.abi as unknown) as AbiItem,
    universeAddress
  )
  return await universeContract.methods.userInfo('0', userAddress).call()
}

export type RewardData = { pending: string };

let isRunningAlready = false
export const requestReward = async (
  prov: provider,
  universeAddress: string,
  userAddress: string
): Promise<RewardData> => {
  if (isRunningAlready) {
    return
  }
  isRunningAlready = true
  const web3 = new Web3(prov)
  const universeContract = new web3.eth.Contract(
    (UNIVERSE.abi as unknown) as AbiItem,
    universeAddress
  )
  try {
    const pending = await universeContract.methods
      .pendingNova('0', userAddress)
      .call()
    isRunningAlready = false
    return { pending }
  } catch (err) {
    isRunningAlready = false
    throw err
  }
}

export type StakingState = { totalLpStaked: string };

export const requestGeneralStakingInfo = async (
  prov: provider,
  universeAddress: string
): Promise<StakingState> => {
  const web3 = new Web3(prov)
  const universeContract = new web3.eth.Contract(
    (UNIVERSE.abi as unknown) as AbiItem,
    universeAddress
  )
  return await universeContract.methods.poolInfo('0').call()
}

export type ContractApprovalArg = {
  prov: provider;
  universeAddress: string;
  lpAddress: string;
  userAddress: string;
  amount: string;
};

export type Transaction = {
  tx: string;
};

export const askContractApproval = async ({
  prov,
  lpAddress,
  universeAddress,
  userAddress,
  amount
}: ContractApprovalArg): Promise<Transaction> => {
  const lpContract = getERC20Contract(prov, lpAddress)
  return await lpContract.methods
    .approve(universeAddress, amount)
    .send({ from: userAddress })
}

export type DepositArg = {
  prov: provider;
  universeAddress: string;
  userAddress: string;
  amount: string;
};

export const deposit = async ({
  prov,
  universeAddress,
  userAddress,
  amount
}: DepositArg): Promise<Transaction> => {
  const web3 = new Web3(prov)
  const universeContract = new web3.eth.Contract(
    (UNIVERSE.abi as unknown) as AbiItem,
    universeAddress
  )
  return await universeContract.methods
    .deposit('0', amount)
    .send({ from: userAddress })
}

export type WithdrawArg = {
  prov: provider;
  universeAddress: string;
  userAddress: string;
  amount: string;
};

export const withdraw = async ({
  prov,
  universeAddress,
  userAddress,
  amount
}: WithdrawArg): Promise<Transaction> => {
  const web3 = new Web3(prov)
  const universeContract = new web3.eth.Contract(
    (UNIVERSE.abi as unknown) as AbiItem,
    universeAddress
  )
  return await universeContract.methods
    .withdraw('0', amount)
    .send({ from: userAddress })
}

export const getBuffRate = async (
  prov: provider,
  universeAddress: string,
  userAddress: string
) => {
  const web3 = new Web3(prov)
  const universeContract = new web3.eth.Contract(
    (UNIVERSE.abi as unknown) as AbiItem,
    universeAddress
  )
  const max = await universeContract.methods
    .maxBuffRate('0', userAddress)
    .call()
  const current = await universeContract.methods
    .calculateBuffRate('0', userAddress, Math.floor(Date.now() / 1000))
    .call()
  return { max, current }
}

export const calculateFees = async (
  prov: provider,
  universeAddress: string,
  userAddress: string
) => {
  const web3 = new Web3(prov)
  const universeContract = new web3.eth.Contract(
    (UNIVERSE.abi as unknown) as AbiItem,
    universeAddress
  )
  const fees = await universeContract.methods
    .calculateFeesPercentage('0', userAddress)
    .call()
  return fees
}
