import { Elm } from '../elm/Main.elm'
import images from './images'
import debug from './debug'
import * as actions from './actions'
import { provider } from 'web3-core'
import detectEthereumProvider from '@metamask/detect-provider'
import Web3 from 'web3'
import { Addresses } from './kometManager'

export const setup = async () => {
  // get the addresses
  const addresses: Addresses = debug.log('addresses? ', {
    komet: process.env.KOMET,
    lp: process.env.LP,
    nova: process.env.NOVA,
    universe: process.env.MU,
    oldNova: process.env.NOVA1,
    oldUniverse: process.env.MU1
  })
  console.log('addresses -> ', addresses)

  const app = Elm.Main.init({
    flags: images
  })

  const prov: provider = (await detectEthereumProvider()) as provider
  // now setup the ports
  const web3: Web3 = new Web3(prov)

  actions.hook(addresses, web3, app)
}
