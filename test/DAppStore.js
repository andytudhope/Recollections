const MiniMeTokenInterface = artifacts.require('./MiniMeTokenInterface.sol')
const MockContract = artifacts.require('./MockContract.sol')
const DAppStore = artifacts.require('./DAppStore.sol')
const BigNumber = require('bignumber.js')
const gasPrice = 1000000000 // 1GWEI

const _ = '        '
const emptyAdd = '0x' + '0'.repeat(40)

contract('DAppStore', async function(accounts) {
  let dAppStore, mockToken, mock

  before(done => {
    ;(async () => {
      try {
        let totalGas = new BigNumber(0)

        // Deploy MockContract.sol
        mock = await MockContract.new()
        mockToken = await MiniMeTokenInterface.at(mock.address)

        // Deploy DAppStore.sol
        dAppStore = await DAppStore.new(mock.address)
        let tx = await web3.eth.getTransactionReceipt(dAppStore.transactionHash)
        totalGas = totalGas.plus(tx.gasUsed)
        console.log(_ + tx.gasUsed + ' - Deploy dAppStore')


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
    it('should deploy simple dapp', async function() {

      const transferFrom = mockToken.contract.methods.transferFrom(emptyAdd, emptyAdd, 0).encodeABI()
      await mock.givenMethodReturnBool(transferFrom, true)

      const transfer = mockToken.contract.methods.transfer(emptyAdd, 0).encodeABI()
      await mock.givenMethodReturnBool(transfer, true)
      
      const balanceOf = mockToken.contract.methods.balanceOf(emptyAdd).encodeABI()
      await mock.givenMethodReturnUint(balanceOf, (1e18).toString(10))
      
      const allowance = mockToken.contract.methods.allowance(emptyAdd, emptyAdd).encodeABI()
      await mock.givenMethodReturnUint(allowance, (1e18).toString(10))

      const firstDapp = web3.utils.sha3('MyFirstDapp')

      let tx = await dAppStore.createDApp(firstDapp, (1e3).toString(10))
      console.log(tx.logs)

      assert(tx.receipt.status, 'tx failed')
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
