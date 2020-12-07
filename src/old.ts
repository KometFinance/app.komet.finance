// main.js
import $ from 'jquery/dist/jquery.slim.min.js'
import 'bootstrap/dist/js/bootstrap.min.js'
import 'regenerator-runtime/runtime'
import './main.scss'
const Web3 = require('web3')

$('#copied').hide(0)

window.copyToClip = () => {
  const text = $('#contract-address').text().trim()
  writeText(text)
  $('#copied').show(0)
  setTimeout(() => {
    $('#copied').hide('slow')
  }, 2000)
}

function writeText (str) {
  return new Promise(function (resolve, reject) {
    let success = false
    function listener (e) {
      e.clipboardData.setData('text/plain', str)
      e.preventDefault()
      success = true
    }
    document.addEventListener('copy', listener)
    document.execCommand('copy')
    document.removeEventListener('copy', listener)
    success ? resolve() : reject(new Error('failure to copy the text'))
  })
}

// eslint-disable-next-line no-unused-vars
class web3Manager {
  constructor () {
    this.showPresaleBalance()
  }

  showPresaleBalance () {
    this.web3 = new Web3(
      new Web3.providers.HttpProvider('https://mainnet.infura.io/v3/f4b608003e1346798ed273657623e8ab')
    )
    this.web3.eth.getBalance('0x0F143e285356C8B79a8DfF049e25a832fCD3a8AF', (error, result) => {
      if (error) {
        console.error(error)
        return
      }

      this.calculateLiquidity(result)
    })
  }

  calculateLiquidity (result) {
    this.ETHRaised = this.web3.utils.fromWei(result, 'ether')
    this.ETHLiquidity = (this.ETHRaised - 15).toFixed(2)
    this.KOMETLiquidity = (this.ETHLiquidity * 22).toFixed(0)
    // console.log(`Current Uniswap liquidity ${this.KOMETLiquidity} $KOMET for ${this.ETHLiquidity}ETH`);
    this.updateLiquidityInfo()
  }

  updateLiquidityInfo () {
    document.getElementById('liquidityKomet').textContent = this.KOMETLiquidity
    document.getElementById('liquidityETH').textContent = this.ETHLiquidity
  }
}

// For now we do not need the web3Manager
// new web3Manager();
