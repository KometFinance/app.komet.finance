import Web3 from 'web3'
import { AbiItem } from 'web3-utils'
import ERC20ABI from '../../abis/ERC20.json'
import UNIVERSE from '../../abis/MasterUniverse2.json'
import OLD_UNIVERSE from '../../abis/MasterUniverse.json'
import MIGRATION from '../../abis/NovaMigrationV2.json'
import debug from './debug'

const MAX_TIMEOUT = 30 * 1000 // 30 seconds

export const getERC20Contract = (web3: Web3, address: string) => {
  const contract = new web3.eth.Contract(
    (ERC20ABI.abi as unknown) as AbiItem,
    address
  )
  return contract
}

export const getBalance = async (
  web3: Web3,
  tokenAddress: string,
  userAddress: string
): Promise<string> => {
  try {
    const contract = getERC20Contract(web3, tokenAddress)
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
  oldNova: string;
  oldUniverse: string;
  migration: string;
};

export type AccountInfo = {
  account: string;
  eth: string;
  komet: string;
  lp: string;
  nova: string;
};

export const getAccountInfo = async (
  web3: Web3,
  addresses: Addresses,
  withRequest: boolean
): Promise<AccountInfo> => {
  const allAccounts = withRequest
    ? await web3.eth.requestAccounts()
    : await web3.eth.getAccounts()
  const userAddress = allAccounts[0]
  if (!userAddress) {
    throw new Error('NO_ACCOUNTS')
  }
  const response = await Promise.race([
    Promise.all([
      getBalance(web3, addresses.lp, userAddress),
      getBalance(web3, addresses.nova, userAddress),
      getBalance(web3, addresses.komet, userAddress),
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
  return response as AccountInfo
}

export const monitorChanges = (
  web3: Web3,
  onAccountsChanged: (withRequest: boolean) => void
) => {
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
  web3: Web3,
  universeAddress: string,
  userAddress: string
): Promise<StakingInfo> => {
  const universeContract = new web3.eth.Contract(
    (UNIVERSE.abi as unknown) as AbiItem,
    universeAddress
  )
  return await universeContract.methods.userInfo('0', userAddress).call()
}

export type RewardData = { pending: string; fees: string };

let isRunningAlready = false
export const requestReward = async (
  web3: Web3,
  universeAddress: string,
  userAddress: string
): Promise<RewardData> => {
  if (isRunningAlready) {
    return
  }
  isRunningAlready = true
  const universeContract = new web3.eth.Contract(
    (UNIVERSE.abi as unknown) as AbiItem,
    universeAddress
  )
  try {
    const pending = await universeContract.methods
      .pendingNova('0', userAddress)
      .call()
    const fees = await universeContract.methods
      .calculateFeesPercentage('0', userAddress)
      .call()
    isRunningAlready = false
    return { pending, fees }
  } catch (err) {
    isRunningAlready = false
    throw err
  }
}

export type StakingState = { totalLpStaked: string };

export const requestGeneralStakingInfo = async (
  web3: Web3,
  lpAddress: string,
  universeAddress: string
): Promise<StakingState> => {
  const totalLpStaked = await getBalance(web3, lpAddress, universeAddress)
  return { totalLpStaked }
}

export type ContractApprovalArg = {
  web3: Web3;
  fromContractAddress: string;
  targetContractAddress: string;
  userAddress: string;
  amount: string;
};

export type Transaction = {
  tx: string;
};

export const askContractApproval = async ({
  web3,
  fromContractAddress,
  targetContractAddress,
  userAddress,
  amount
}: ContractApprovalArg): Promise<Transaction> => {
  const fromContract = getERC20Contract(web3, fromContractAddress)
  return await fromContract.methods
    .approve(targetContractAddress, amount)
    .send({ from: userAddress })
}

export type DepositArg = {
  web3: Web3;
  universeAddress: string;
  userAddress: string;
  amount: string;
};

export const deposit = async ({
  web3,
  universeAddress,
  userAddress,
  amount
}: DepositArg): Promise<Transaction> => {
  const universeContract = new web3.eth.Contract(
    (UNIVERSE.abi as unknown) as AbiItem,
    universeAddress
  )
  return await universeContract.methods
    .deposit('0', amount)
    .send({ from: userAddress })
}

export type WithdrawArg = {
  web3: Web3;
  universeAddress: string;
  userAddress: string;
  amount: string;
};

export const withdraw = async ({
  web3,
  universeAddress,
  userAddress,
  amount
}: WithdrawArg): Promise<Transaction> => {
  const universeContract = new web3.eth.Contract(
    (UNIVERSE.abi as unknown) as AbiItem,
    universeAddress
  )
  return await universeContract.methods
    .withdraw('0', amount)
    .send({ from: userAddress })
}

export type OldStateArg = {
  web3: Web3;
  oldUniverseAddress: string;
  oldNovaAddress: string;
  userAddress: string;
};
export type OldState = {
  oldStaking: string;
  oldNova: string;
};

export const requestOldState = async ({
  web3,
  oldUniverseAddress,
  oldNovaAddress,
  userAddress
}: OldStateArg): Promise<OldState> => {
  const oldUniverseContract = new web3.eth.Contract(
    (OLD_UNIVERSE.abi as unknown) as AbiItem,
    oldUniverseAddress
  )
  const { amount } = await oldUniverseContract.methods
    .userInfo('0', userAddress)
    .call()
  const oldNova = await getBalance(web3, oldNovaAddress, userAddress)
  return debug.log('requestOldState response -> ', {
    oldStaking: amount,
    oldNova
  })
}

export type EmergencyWithdrawalArg = {
  web3: Web3;
  oldUniverseAddress: string;
  userAddress: string;
};

export const emergencyWithdrawal = async ({
  web3,
  oldUniverseAddress,
  userAddress
}: EmergencyWithdrawalArg): Promise<any> => {
  const oldUniverseContract = new web3.eth.Contract(
    (OLD_UNIVERSE.abi as unknown) as AbiItem,
    oldUniverseAddress
  )
  debug('emergencyWithdraw -> ', userAddress, oldUniverseContract)
  const response = await oldUniverseContract.methods
    .emergencyWithdraw('0')
    .send({ from: userAddress })
  return debug.log('emergencyWithdraw response -> ', response)
}

export type ExchangeNovaV1Arg = {
  web3: Web3;
  migrationAddress: string;
  userAddress: string;
  amount: string;
};

export const exchangeNovaV1 = async ({
  web3,
  migrationAddress,
  userAddress,
  amount
}: ExchangeNovaV1Arg): Promise<any> => {
  const migrationContract = new web3.eth.Contract(
    (MIGRATION.abi as unknown) as AbiItem,
    migrationAddress
  )
  const response = await migrationContract.methods
    .swap(amount)
    .send({ from: userAddress })
  return debug.log('exchangeAnswer', response)
}

export type ClaimRewardsArg = {
  web3: Web3;
  migrationAddress: string;
  userAddress: string;
};

export const claimRewards = async ({
  web3,
  migrationAddress,
  userAddress
}: ClaimRewardsArg): Promise<any> => {
  const migrationContract = new web3.eth.Contract(
    (MIGRATION.abi as unknown) as AbiItem,
    migrationAddress
  )
  const response = await migrationContract.methods
    .claimRewards()
    .send({ from: userAddress })
  return debug.log('claimRewards', response)
}
