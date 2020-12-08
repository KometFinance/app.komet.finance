// global ethereum
import './tailwind-build.css'
import './main.scss'
import 'babel-polyfill'
import { setup } from './ts/setup'
import './ts/custom-elements/plasma'

// eslint-disable-next-line no-undef
console.log('ethereum ? ', window.ethereum, !!window.ethereum)
if (window.ethereum) {
  // eslint-disable-next-line no-undef
  window.ethereum.autoRefreshOnNetworkChange = false
  setup()
} else {
  document.getElementById('install-metamask').hidden = false
}
