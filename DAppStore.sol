pragma solidity >=0.4.22 <0.6.0;

import "./token/MiniMeTokenInterface.sol";


contract DAppStore {
    
    // Could be any EIP20/MiniMe token
    MiniMeTokenInterface SNT;

    constructor (MiniMeTokenInterface _SNT) public {
        SNT = _SNT;
    }
    
    // Total SNT in circulation
    uint total = 3470483788;
    /* 
        According to calculations here: https://beta.observablehq.com/@andytudhope/dapp-store-snt-curation-mechanism
        interesting choices for the ceiling are around 0.4, but this requires more research/modelling.
        
        Alternative to a static ceiling: create an `owner` of this contract, set it to a multisig, give that owner multisig
        permission to alter the ceiling and promise to do so based on the results of voting in https://vote.status.im
    */
    uint ceiling = 0.4;
    // The max amount of tokens it is possible to stake, as a percentage of the total in circulation
    uint max = total * (ceiling/100);
    
    // Whether we need more than an id param to identify arbitrary data must still be discussed.
    struct Data {
        address developer;
        bytes32 id;
        uint balance;
        uint rate;
        uint available;
        uint v_minted;
        uint v_cast;
        uint e_balance;
    }
    
    Data[] public dapps;
    mapping(bytes32 => uint) public id2index;
    
    event DAppCreated(bytes32 id, uint amount);
    event upvote(bytes32 id, uint amount, uint newEffectiveBalance);
    event downvote(bytes32 id, uint cost, uint newEffectiveBalance);
    event withdraw(bytes32 id, uint amount, uint newEffectiveBalance);
    
    /**
     * @dev Anyone can create a DApp (i.e an arb piece of data this contract happens to care about).
     * @param _id bytes32 unique identifier.
     * @param _amount of tokens to stake on initial ranking.
     */
    function createDApp(bytes32 _id, uint _amount) public { 
        require(_amount > 0, "You must spend some SNT to submit a ranking in order to avoid spam");
        require (_amount < max, "You cannot stake more SNT than the ceiling dictates");
        require(SNT.allowance(msg.sender, address(this)) >= _amount);
        require(SNT.transferFrom(msg.sender, address(this), _amount));
        
        uint dappIdx = dapps.length;
        
        dapps.length++;

        Data storage d = dapps[dappIdx];
        d.developer = msg.sender;
        d.id = _id;
        d.balance = _amount;
        d.rate = 1 - (d.balance/max);
        d.available = d.balance * d.rate;
        d.v_minted = d.available ** (1/d.rate);
        d.v_cast = 0;
        d.e_balance = d.balance - ((d.v_cast/(1/d.rate))*(d.available/d.v_minted));

        id2index[_id] = dappIdx;

        emit DAppCreated(_id, _amount);
    }

    /**
     * @dev Used in UI to display effect on ranking of user's donation
     * @param _id bytes32 unique identifier.
     * @param _amount of tokens to stake/"donate" to this DApp's ranking.
     * @return effect of donation on DApp's e_balance 
     */
    function upvoteEffect(bytes32 _id, uint _amount) public returns(uint effect) { 
        uint dappIdx = id2index[_id];
        Data memory d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct data");
        
        uint mBalance = d.balance + _amount;
        uint mRate = 1 - (mBalance/max);
        uint mAvailable = mBalance * mRate;
        uint mVMinted = mAvailable ** (1/mRate);
        uint mEBalance = mBalance - ((mVMinted/(1/mRate))*(mAvailable/mVMinted));
        
        return (mEBalance - d.e_balance);
    }
    
    /**
     * @dev Sends SNT directly to the contract, not the developer. This gets added to the DApp's balance, no curve required.
     * @param _id bytes32 unique identifier.
     * @param _amount of tokens to stake on DApp's ranking. Used for upvoting + staking more.
     */
    function upvote(bytes32 _id, uint _amount) public { 
        require(_amount > 0, "You must send some SNT in order to upvote");
        
        uint dappIdx = id2index[_id];
        Data storage d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct data");
        
        require(d.balance + _amount < max, "You cannot stake more SNT than the ceiling dictates");
        require(SNT.allowance(msg.sender, address(this)) >= _amount);
        require(SNT.transferFrom(msg.sender, address(this), _amount));
        
        d.balance = d.balance + _amount;
        d.rate = 1 - (d.balance/max);
        d.available = d.balance * d.rate;
        d.v_minted = d.available ** (1/d.rate);
        d.e_balance = d.balance - ((d.v_cast/(1/d.rate))*(d.available/d.v_minted));
        
        emit upvote(_id, _amount, d.e_balance);
    }
    
    /**
     * @dev Used in the UI along with a slider to let the user pick their desired % effect on the DApp's ranking.
     * @param _id bytes32 unique identifier.
     * @param _percent_down the % of SNT staked on the DApp user would like "remove" from the rank.
     * @return cost
     */
    function downvoteCost(bytes32 _id, uint _percent_down) public returns(uint cost) { 
        require(1/100 <= _percent_down <= 99/100, "You must effect the ranking by more than 1, and less than 99, percent");
        
        uint dappIdx = id2index[_id];
        Data memory d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct data");
        
        uint balance_down_by = (_percent_down * d.e_balance);
        uint votes_required = (balance_down_by * d.v_minted * d.rate) / d.available;
        return cost = (d.available / (d.v_minted - (d.v_cast + votes_required))) * (votes_required / _percent_down / 100);
    }
    
    /**
     * @dev Sends SNT directly to the developer and lowers the DApp's effective balance in the Store.
     * @param _id bytes32 unique identifier.
     * @param _percent_down the % of SNT staked on the DApp user would like "remove" from the rank.
     * @param _amount of SNT they estimate is needed to buy the required votes.
     */
    function downvote(bytes32 _id, uint _percent_down, uint _amount) public { 
        require(1/100 <= _percent_down <= 99/100, "You must effect the ranking by more than 1, and less than 99, percent");
        require(_amount > 0, "You must send some SNT in order to downvote");
         
        uint dappIdx = id2index[_id];
        Data storage d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct data");
        
        uint cost = downvoteCost(_id, _percent_down);
        // Not a good UI flow here, having to estimate the cost and then potentially 
        // have the state of the contract change before you actually downvote - any better solutions?
        require(_amount >= cost, "The contract state has changed and this is no longer a valid vote, please refresh");
        
        uint balance_down_by = (_percent_down * d.e_balance);
        uint votes_required = (balance_down_by * d.v_minted * d.rate) / d.available;
        
        d.available = d.available - cost;
        d.v_cast = d.v_cast + votes_required;
        d.e_balance = d.e_balance - balance_down_by;
        
        /*  
            TODO: Implement a different means of allowance/sends in line
            with https://github.com/status-im/ens-usernames/blob/04bd8921516584a25a0bd9af15ddec3c4830265a/contracts/registry/UsernameRegistrar.sol#L543
        */
        require(SNT.allowance(msg.sender, d.developer) >= cost);
        require(SNT.transferFrom(msg.sender, d.developer, cost));
        
        emit downvote(_id, cost, d.e_balance);
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
        
        d.balance = d.balance - _amount;
        d.rate = 1 - (d.balance/max);
        d.available = d.balance * d.rate;
        d.v_minted = d.available ** (1/d.rate);
        if (d.v_cast > d.v_minted) {
            d.v_cast = d.v_minted;
        }
        d.e_balance = d.balance - ((d.v_cast/(1/d.rate))*(d.available/d.v_minted));
        
        // TODO: Check this works!
        SNT.transferFrom(address(this), d.developer, _amount);
        
        emit withdraw(_id, _amount, d.e_balance);
    }
}
