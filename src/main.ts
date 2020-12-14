// global ethereum
import './tailwind-build.css'
import './main.scss'
import 'bootstrap-icons/font/bootstrap-icons.css'
import 'babel-polyfill'
import { setup } from './ts/setup'
import './ts/custom-elements/plasma'

if (window.ethereum) {
  // eslint-disable-next-line no-undef
  (window.ethereum as any).autoRefreshOnNetworkChange = false
  setup()
} else {
  document.getElementById('install-metamask').hidden = false
}
