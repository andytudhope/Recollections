// var MiniMeTokenInterface = artifacts.require('./MiniMeTokenInterface.sol')
var MockContract = artifacts.require('./MockContract.sol')
var DAppStore = artifacts.require('./DAppStore.sol')
var BigNumber = require('bignumber.js')
let gasPrice = 1000000000 // 1GWEI

let _ = '        '

contract('DAppStore', async function(accounts) {
  let dAppStore

  before(done => {
    ;(async () => {
      try {
        var totalGas = new BigNumber(0)

        // Deploy MockContract.sol
        const mock = await MockContract.new()

        // Deploy DAppStore.sol
        dAppStore = await DAppStore.new(mock.address)
        var tx = await web3.eth.getTransactionReceipt(dAppStore.transactionHash)
        totalGas = totalGas.plus(tx.gasUsed)
        console.log(_ + tx.gasUsed + ' - Deploy dAppStore')
        dAppStore = await DAppStore.deployed()

        console.log(_ + '-----------------------')
        console.log(_ + totalGas.toFormat(0) + ' - Total Gas')
        done()
      } catch (error) {
        console.error(error)
        done(false)
      }
    })()
  })

  describe('DAppStore.sol', function() {
    it('should pass', async function() {
      assert(
        true === true,
        'this is true'
      )
    })

  })
})

function getBlockNumber() {
  return new Promise((resolve, reject) => {
    web3.eth.getBlockNumber((error, result) => {
      if (error) reject(error)
      resolve(result)
    })
  })
}

function increaseBlocks(blocks) {
  return new Promise((resolve, reject) => {
    increaseBlock().then(() => {
      blocks -= 1
      if (blocks == 0) {
        resolve()
      } else {
        increaseBlocks(blocks).then(resolve)
      }
    })
  })
}

function increaseBlock() {
  return new Promise((resolve, reject) => {
    web3.currentProvider.sendAsync(
      {
        jsonrpc: '2.0',
        method: 'evm_mine',
        id: 12345
      },
      (err, result) => {
        if (err) reject(err)
        resolve(result)
      }
    )
  })
}

function decodeEventString(hexVal) {
  return hexVal
    .match(/.{1,2}/g)
    .map(a =>
      a
        .toLowerCase()
        .split('')
        .reduce(
          (result, ch) => result * 16 + '0123456789abcdefgh'.indexOf(ch),
          0
        )
    )
    .map(a => String.fromCharCode(a))
    .join('')
}
