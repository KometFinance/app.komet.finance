import { Elm } from '../elm/Main.elm'
import images from './images'
import debug from './debug'
import * as actions from './actions'
import { provider } from 'web3-core'
import detectEthereumProvider from '@metamask/detect-provider'

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

  actions.hook(addresses, prov, app)
}
