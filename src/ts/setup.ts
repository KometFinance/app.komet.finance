import { Elm } from '../elm/Main.elm'
import images from './images'
import debug from './debug'
import * as actions from './actions'
import { provider } from 'web3-core'
import detectEthereumProvider from '@metamask/detect-provider'
import Web3 from 'web3'

export const setup = async () => {
  // get the addresses
  const addresses = debug.log('addresses? ', {
    komet: process.env.KOMET,
    lp: process.env.LP,
    nova: process.env.NOVA,
    universe: process.env.MU
  })

  const app = Elm.Main.init({
    flags: images
  })

  const prov: provider = (await detectEthereumProvider()) as provider
  // now setup the ports
  const web3: Web3 = new Web3(prov)

  actions.hook(addresses, web3, app)
}
