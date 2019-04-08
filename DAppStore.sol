pragma solidity >=0.4.22 <0.6.0;

import "./token/MiniMeTokenInterface.sol";
import "./token/ApproveAndCallFallBack.sol";
import "./utils/SafeMath.sol";
import "./utils/BancorFormula.sol";

contract DAppStore is ApproveAndCallFallBack, BancorFormula {
    using SafeMath for uint;

    // Could be any EIP20/MiniMe token
    MiniMeTokenInterface SNT;

    // Total SNT in circulation
    uint total;
    
    // Parameter to calculate Max SNT any one DApp can stake
    uint ceiling;

    // The max amount of tokens it is possible to stake, as a percentage of the total in circulation
    uint max;

    // Decimal precision for this contract
    uint decimals;

    // Prevents overflows in votes_minted
    uint safeMax;
    
    // Whether we need more than an id param to identify arbitrary data must still be discussed.
    struct Data {
        address developer;
        bytes32 id;
        uint balance;
        uint rate;
        uint available;
        uint votes_minted;
        uint votes_cast;
        uint effective_balance;
    }
    
    Data[] public dapps;
    mapping(bytes32 => uint) public id2index;
    
    event DAppCreated(bytes32 indexed id, uint votes_mint, uint amount);
    event Upvote(bytes32 indexed id, uint newEffectiveBalance);
    event Downvote(bytes32 indexed id, uint newEffectiveBalance);
    event Withdraw(bytes32 indexed id, uint newEffectiveBalance);
    
    constructor(MiniMeTokenInterface _SNT) public {
        SNT = _SNT;
        
        total = 3470483788;

        ceiling = 588;   // 2 dec fixed pos,  ie: 5 == 0.05,  588 == 5.88,

        decimals = 1000000;
        
        max = (total * ceiling) / decimals; // 4 decimal points for %, 2 because we only use 1/100th of total in circulation

        safeMax = 98 * max / 100;
    }
    
    /**
     * @dev Anyone can create a DApp (i.e an arb piece of data this contract happens to care about).
     * @param _id bytes32 unique identifier.
     * @param _amount of tokens to stake on initial ranking.
     */
    function createDApp(bytes32 _id, uint _amount) public { 
        _createDApp(msg.sender, _id, _amount);
    }
    
    function _createDApp(address _from, bytes32 _id, uint _amount) internal {
        require(_amount > 0, "You must spend some SNT to submit a ranking in order to avoid spam");
        require (_amount < safeMax, "You cannot stake more SNT than the ceiling dictates");
        require(SNT.allowance(_from, address(this)) >= _amount, "Not enough SNT allowance");
        require(SNT.transferFrom(_from, address(this), _amount), "Transfer failed");
        
        uint dappIdx = dapps.length;
        
        dapps.length++;

        Data storage d = dapps[dappIdx];
        d.developer = msg.sender;
        d.id = _id;
        
        uint precision;
        uint result;
        
        d.balance = _amount;
        d.rate = decimals - (d.balance * decimals/max);
        d.available = d.balance * d.rate;
        
        (result, precision) = BancorFormula.power(d.available, decimals, uint32(decimals), uint32(d.rate));
        
        d.votes_minted = result >> precision;
        d.votes_cast = 0;
        d.effective_balance = _amount;

        id2index[_id] = dappIdx;

        emit DAppCreated(_id, d.votes_minted, d.effective_balance);
    }
    
    /**
     * @dev Used in UI to display effect on ranking of user's donation
     * @param _id bytes32 unique identifier.
     * @param _amount of tokens to stake/"donate" to this DApp's ranking.
     * @return effect of donation on DApp's effective_balance 
     */
    function upvoteEffect(bytes32 _id, uint _amount) public view returns(uint effect) { 
        uint dappIdx = id2index[_id];
        Data memory d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct data");
        require(d.balance + _amount < safeMax, "You cannot upvote by this much, try with a lower amount");

        uint precision;
        uint result;
        
        uint mBalance = d.balance + _amount;
        uint mRate = decimals - (mBalance * decimals/max);
        uint mAvailable = mBalance * mRate;
        
        (result, precision) = BancorFormula.power(mAvailable, decimals, uint32(decimals), uint32(mRate));
        
        uint mVMinted = result >> precision;
        uint mEBalance = mBalance - ((mVMinted*mRate)*(mAvailable/mVMinted));
        
        return (mEBalance - d.effective_balance);
    }
    
    /**
     * @dev Sends SNT directly to the contract, not the developer. This gets added to the DApp's balance, no curve required.
     * @param _id bytes32 unique identifier.
     * @param _amount of tokens to stake on DApp's ranking. Used for upvoting + staking more.
     */
    function upvote(bytes32 _id, uint _amount) public { 
        _upvote(msg.sender, _id, _amount);
    }
    
    function _upvote(address _from, bytes32 _id, uint _amount) internal { 
        require(_amount > 0, "You must send some SNT in order to upvote");
        
        uint dappIdx = id2index[_id];
        Data storage d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct data");
        
        require(d.balance + _amount < safeMax, "You cannot upvote by this much, try with a lower amount");
        require(SNT.allowance(_from, address(this)) >= _amount, "Not enough SNT allowance");
        require(SNT.transferFrom(_from, address(this), _amount), "Transfer failed");
        
        uint precision;
        uint result;

        d.balance = d.balance + _amount;
        d.rate = decimals - (d.balance * decimals/max);
        d.available = d.balance * d.rate;
        
        (result, precision) = BancorFormula.power(d.available, decimals, uint32(decimals), uint32(d.rate));
        
        d.votes_minted = result >> precision;
        d.effective_balance = d.balance - ((d.votes_cast*d.rate)*(d.available/d.votes_minted));
        
        emit Upvote(_id, d.effective_balance);
    }

    /**
     * @dev Downvotes always remove 1% of the current ranking.
     * @param _id bytes32 unique identifier. 
     * @return cost
     */
    function downvoteCost(bytes32 _id) public view returns(uint b, uint v_r, uint c) { 
        uint dappIdx = id2index[_id];
        Data memory d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct data");
        
        uint balance_down_by = (d.effective_balance / 100);
        uint votes_required = (balance_down_by * d.votes_minted * d.rate) / d.available;
        uint cost = (d.available / (d.votes_minted - (d.votes_cast + votes_required))) * (votes_required / 1 / 10000);
        return (balance_down_by, votes_required, cost);
    }
    
    /**
     * @dev Sends SNT directly to the developer and lower the DApp's effective balance by 1%
     * @param _id bytes32 unique identifier.
     */
    function downvote(bytes32 _id) public { 
        _downvote(msg.sender, _id);
    }
    
    function _downvote(address _from, bytes32 _id) internal { 
        uint dappIdx = id2index[_id];
        Data storage d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct data");
        
        (uint b, uint v_r, uint c) = downvoteCost(_id);

        require(SNT.allowance(_from, d.developer) >= c, "Not enough SNT allowance");
        require(SNT.transferFrom(_from, d.developer, c), "Transfer failed");
        
        d.available = d.available - c;
        d.votes_cast = d.votes_cast + v_r;
        d.effective_balance = d.effective_balance - b;
        
        emit Downvote(_id, d.effective_balance);
    }
    
    /**
     * @dev Developers can withdraw an amount not more than what was available of the
        SNT they originally staked minus what they have already received back in downvotes.
     * @param _id bytes32 unique identifier.
     * @param _amount of tokens to withdraw from DApp's overall balance.
     */
    function withdraw(bytes32 _id, uint _amount) public { 
        uint dappIdx = id2index[_id];
        Data storage d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct data");
        
        require(msg.sender == d.developer, "Only the developer can withdraw SNT staked on this data");
        require(_amount <= d.available, "You can only withdraw a percentage of the SNT staked, less what you have already received");
        
        uint precision;
        uint result;

        d.balance = d.balance - _amount;
        d.rate = decimals - (d.balance * decimals/max);
        d.available = d.balance * d.rate;
        
        (result, precision) = BancorFormula.power(d.available, decimals, uint32(decimals), uint32(d.rate));
        
        d.votes_minted = result >> precision;
        if (d.votes_cast > d.votes_minted) {
            d.votes_cast = d.votes_minted;
        }
        d.effective_balance = d.balance - ((d.votes_cast*d.rate)*(d.available/d.votes_minted));
        
        SNT.transferFrom(address(this), d.developer, _amount);
        
        emit Withdraw(_id, d.effective_balance);
    }
    
    /**
     * @notice Support for "approveAndCall".  
     * @param _from Who approved.
     * @param _amount Amount being approved, needs to be equal `_amount` or `cost`.
     * @param _token Token being approved, needs to be `SNT`.
     * @param _data Abi encoded data with selector of `register(bytes32,address,bytes32,bytes32)`.
     */
    function receiveApproval(
        address _from,
        uint256 _amount,
        address _token,
        bytes memory _data
    ) 
        public
    {
        require(_token == address(SNT), "Wrong token");
        require(_token == address(msg.sender), "Wrong account");
        require(_data.length <= 132, "Incorrect data");
        
        bytes4 sig;
        bytes32 id;
        uint256 amount;

        (sig, id, amount) = abiDecodeRegister(_data);
        
        require(_amount == amount, "Wrong amount");

        // TODO: check these function sigs!
        if(sig == bytes4(0xe4bb1695)) {
            _createDApp(_from, id, amount);
        } else if(sig == bytes4(0xfaa5fd03)) {
            _downvote(_from, id);
        } else if(sig == bytes4(0x0643e21b)) {
            _upvote(_from, id, amount);
        } else {
            revert("Wrong method selector");
        }
    }
    
    
    
    /**
     * @dev Decodes abi encoded data with selector for "functionName(bytes32,uint256)".
     * @param _data Abi encoded data.
     * @return Decoded registry call.
     */
    function abiDecodeRegister(
        bytes memory _data
    ) 
        private 
        pure 
        returns(
            bytes4 sig,
            bytes32 id,
            uint256 amount
        )
    {
        assembly {
            sig := mload(add(_data, add(0x20, 0)))
            id := mload(add(_data, 36))
            amount := mload(add(_data, 68))
        }
    }

}
