// var MiniMeTokenInterface = artifacts.require('./MiniMeTokenInterface.sol')
var MockContract = artifacts.require('./MockContract.sol')
var DAppStore = artifacts.require('./DAppStore.sol')
let _ = '        '

module.exports = (deployer, helper, accounts) => {

  deployer.then(async () => {
    try {

      // Deploy MockContract.sol
      const mock = await MockContract.new()

      // Deploy DAppStore.sol
      await deployer.deploy(DAppStore, mock.address)
      let dappStore = await DAppStore.deployed()
      console.log(_ + 'DAppStore deployed at: ' + dappStore.address)

    } catch (error) {
      console.log(error)
    }
  })
}
