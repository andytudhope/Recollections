# import ApproveAndCallFallBack as ApproveAndCallFallBackInterface

# implements: ApproveAndCallFallBackInterface

struct Data:
    developer: address
    id: bytes32
    dappBalance: int128
    rate: int128
    available: int128
    votes_minted: int128
    votes_cast: int128
    effective_balance: int128

contract MiniMeTokenInterface:
    # ERC20 methods
    def totalSupply() -> uint256: constant
    def balanceOf(_owner: address) -> uint256: constant
    def allowance(_owner: address, _spender: address) -> uint256: constant
    def transfer(_to: address, _value: uint256) -> bool: modifying
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: modifying
    def approve(_spender: address, _value: uint256) -> bool: modifying
    # MiniMe methods
    def approveAndCall(_spender: address, _amount: uint256, _extraData: bytes[132]) -> bool : modifying
    def createCloneToken(_cloneTokenName: string[64], _cloneDecimalUnits: uint256, _cloneTokenSymbol: string[32], _snapshotBlock: uint256, _transfersEnabled: bool) -> address: modifying
    def generateTokens(_owner: address, _amount: uint256) -> bool: modifying
    def destroyTokens(_owner: address, _amount: uint256) -> bool: modifying
    def enableTransfers(_transfersEnabled: bool): modifying
    def claimTokens(_token: address): modifying
    def balanceOfAt(_owner: address, _blockNumber: uint256) -> uint256 : constant
    def totalSupplyAt(_blockNumber: address) -> uint256: constant

# Events
DAppCreated: event({_id: bytes32, _amount: int128})
Upvote: event({_id: bytes32, _amount: int128, _newEffectiveBalance: int128})
Downvote: event({_id: bytes32, _cost: int128, _newEffectiveBalance: int128})
Withdraw: event({_id: bytes32, _amount: int128, _newEffectiveBalance: int128})

TOTAL_SNT: constant(int128) = 3470483788

dapps: map(uint256, Data)
idToIdx: map(bytes32, uint256)
currMax: public(uint256)

total: public(int128)
ceiling: public(int128)
maxStake: public(int128)

SNT: public(MiniMeTokenInterface)

#Constant functions
@public
@constant
def upvoteEffect(_id: bytes32, _amount: int128) -> int128:
    """
    @dev Used in UI to display effect on ranking of user's donation
    @param _id bytes32 unique identifier
    @param _amount Amount of SNT tokens to stake/"donate" to this DApp's ranking.
    @return effect of donation on DApp's effective_balance
    """
    dappIdx: uint256 = self.idToIdx[_id]
    dapp: Data = self.dapps[dappIdx]

    assert dapp.id == _id

    mBalance: int128 = dapp.dappBalance + _amount
    mRate: int128 = 1 - (mBalance / self.maxStake)
    mAvailable: int128 = mBalance * mRate
    mVMinted: int128 = mAvailable ** (1/mRate)
    mEBalance: int128 = mBalance - ((mVMinted * mRate) * (mAvailable / mVMinted))

    return (mEBalance - dapp.dappBalance)

@public
def downvoteCost(_id: bytes32) -> int128[3]:
    """
    @dev For simplicity, users can only downvote by 1% at a time.
    @param _id bytes32 unique identifier.
    @return Array [balanceDownBy, votesRequired, cost]
    """
    dappIdx: uint256 = self.idToIdx[_id]
    dapp: Data = self.dapps[dappIdx]

    assert dapp.id == _id

    balanceDownBy: int128 = dapp.effective_balance / 100
    votesRequired: int128 = (balanceDownBy * dapp.votes_minted * dapp.rate) / dapp.available
    cost: int128 = (dapp.available / (dapp.votes_minted - (dapp.votes_cast + votesRequired))) * (votesRequired / 1 / 100)

    return [balanceDownBy, votesRequired, cost]

#Constructor
@public
def __init__(_tokenAddr: address):
    self.SNT = MiniMeTokenInterface(_tokenAddr)
    self.total = TOTAL_SNT
    self.ceiling = 40
    self.maxStake = (self.total * self.ceiling) / 10000

#Private Functions
@private 
def _createDapp(_from: address, _id: bytes32, _amount: int128):
    """
    @dev private low level function for adding a dapp to the store
    @param _from Address of the dapp's developer
    @param _id Unique identifier for the dapp
    @param _amount Amount of SNT tokens to be staked
    """
    assert self.currMax < MAX_UINT256, "Reached maximum dapps limit for the DAppStore"
    assert _amount > 0, "You must spend some SNT to submit a ranking in order to avoid spam"
    assert _amount < self.maxStake, "You cannot stake more SNT than the ceiling dictates"
    assert self.SNT.allowance(_from, self) >= convert(_amount,uint256), "Not enough SNT allowance"
    assert self.SNT.transferFrom(_from, self, convert(_amount,uint256)), "Transfer failed"

    self.idToIdx[_id] = self.currMax
    newDapp: Data

    newDapp.developer = _from
    newDapp.id = _id
    newDapp.dappBalance = _amount 
    newDapp.rate = 1 - (newDapp.dappBalance / self.maxStake) 
    newDapp.available = newDapp.dappBalance * newDapp.rate
    newDapp.votes_minted = newDapp.available ** (1 / newDapp.rate)
    newDapp.votes_cast = 0
    newDapp.effective_balance = newDapp.dappBalance - ((newDapp.votes_cast * newDapp.rate) * (newDapp.available / newDapp.votes_minted))

    self.dapps[self.currMax] = newDapp
    self.currMax += 1

    log.DAppCreated(_id, newDapp.effective_balance)

@private
def _upvote(_from: address, _id: bytes32, _amount: int128):
    """
    @dev private low level function for upvoting a dapp by contributing SNT directly to a Dapp's balance
    @param _from Address of the upvoter
    @param _id Unique identifier for the dapp
    @param _amount Amount of SNT tokens to stake/"donate" to this DApp's ranking
    """
    assert _amount > 0, "You must send some SNT in order to upvote"

    dappIdx: uint256 = self.idToIdx[_id]
    dapp: Data = self.dapps[dappIdx]

    assert dapp.id == _id, "Error fetching correct data"
    assert dapp.dappBalance + _amount < self.maxStake, "You cannot stake more SNT than the ceiling dictates"
    assert self.SNT.allowance(_from, self) >= convert(_amount,uint256), "Not enough SNT allowance"
    assert self.SNT.transferFrom(_from, self, convert(_amount,uint256)), "Transfer failed"

    dapp.dappBalance += _amount
    dapp.rate = 1 - (dapp.dappBalance / self.maxStake)
    dapp.available = dapp.dappBalance * dapp.rate
    dapp.votes_minted = dapp.available ** (1 / dapp.rate)
    dapp.effective_balance = dapp.dappBalance - ((dapp.votes_cast * dapp.rate) * (dapp.available / dapp.votes_minted))

    self.dapps[dappIdx] = dapp

    log.Upvote(_id, _amount, dapp.effective_balance)

@private
def _downvote(_from: address, _id: bytes32):
    """
    @dev private low level function for downvoting a dapp by contributing SNT directly to a Dapp's balance
    @param _from Address of the downvoter
    @param _id Unique identifier for the dapp
    @param _percentDown The % of SNT staked on the DApp user would like "removed" from the rank
    """

    dappIdx: uint256 = self.idToIdx[_id]
    dapp: Data = self.dapps[dappIdx]

    assert dapp.id == _id, "Error fetching correct data"
    check: decimal = convert(dapp.votes_cast / dapp.votes_minted, decimal)
    assert check < 0.99, "All valid votes have already been cast"

    downvoteEffect: int128[3] = self.downvoteCost(_id)

    assert self.SNT.allowance(_from, dapp.developer) >= convert(downvoteEffect[2], uint256), "Not enough SNT allowance"
    assert self.SNT.transferFrom(_from, dapp.developer, convert(downvoteEffect[2], uint256)), "Transfer failed"

    dapp.available -= downvoteEffect[2]
    dapp.votes_cast += downvoteEffect[1]
    dapp.effective_balance -= downvoteEffect[0]

    self.dapps[dappIdx] = dapp

    log.Downvote(_id, downvoteEffect[2], dapp.effective_balance)

# Public Functions
@public 
def createDapp(_id: bytes32, _amount: int128):
    """
    @dev Anyone can create a DApp (i.e an arb piece of data this contract happens to care about)
    @param _id bytes32 unique identifier
    @param _amount Amount of SNT tokens to stake on initial ranking
    """
    self._createDapp(msg.sender, _id, _amount)

@public
def upvote(_id: bytes32, _amount: int128):
    """
    @dev Sends SNT directly to the contract, not the developer. This gets added to the DApp's balance, no curve required
    @param _id bytes32 unique identifier
    @param _amount Amount of tokens to stake on DApp's ranking. Used for upvoting + staking more
    """
    self._upvote(msg.sender, _id, _amount)

@public
def downvote(_id: bytes32):
    """
    @dev Sends SNT directly to the developer and lowers the DApp's effective balance in the Store
    @param _id bytes32 unique identifier.
    @param _percent_down The % of SNT staked on the DApp user would like "removed" from the rank
    """
    self._downvote(msg.sender, _id)

@public
def withdraw(_id: bytes32, _amount: int128):
    """
    @dev Developers can withdraw an amount not more than what was available of the
        SNT they originally staked minus what they have already received back in downvotes
    @param _id bytes32 unique identifier
    @param _amount Amount of tokens to withdraw from DApp's overall balance
    """
    dappIdx: uint256 = self.idToIdx[_id]
    dapp: Data = self.dapps[dappIdx]

    assert dapp.id == _id, "Error fetching correct data"
    assert msg.sender == dapp.developer, "Only the developer can withdraw SNT staked on this data"
    assert _amount <= dapp.available, "You can only withdraw a percentage of the SNT staked, less what you have already received"

    dapp.dappBalance -= _amount
    dapp.rate = 1 - (dapp.dappBalance / self.maxStake)
    dapp.available = dapp.dappBalance * dapp.rate
    dapp.votes_minted = dapp.available ** (1 / dapp.rate)
    if (dapp.votes_cast > dapp.votes_minted):
        dapp.votes_cast = dapp.votes_minted
    dapp.effective_balance = dapp.dappBalance - ((dapp.votes_cast * dapp.rate) * (dapp.available / dapp.votes_minted))

    self.dapps[dappIdx] = dapp
    assert self.SNT.transferFrom(self, dapp.developer, convert(_amount,uint256)), "Transfer failed"

    log.Withdraw(_id, _amount, dapp.effective_balance)

# Snipped: receiveApproval
