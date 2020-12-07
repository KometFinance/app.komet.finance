// global ethereum
import './tailwind-build.css'
import './main.scss'
import 'babel-polyfill'
import { setup } from './ts/setup'
import './ts/custom-elements/plasma'

// eslint-disable-next-line no-undef
ethereum.autoRefreshOnNetworkChange = false

setup()
