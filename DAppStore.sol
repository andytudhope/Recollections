pragma solidity >=0.4.22 <0.6.0;

import './token/MiniMeTokenInterface.sol';


contract DAppStore {
    
    MiniMeTokenInterface SNT;

    constructor (MiniMeTokenInterface _SNT) public {
        SNT = _SNT;
    }
    
    // Total SNT in circulation
    uint256 total = 3470483788;
    /* 
        According to calculations here: https://beta.observablehq.com/@andytudhope/dapp-store-snt-curation-mechanism
        interesting choices for the ceiling are around 0.4, but this requires more research/modelling.
    */
    uint8 ceiling = 0.4;
    uint256 max = total * (ceiling/100);
    
    // Whether we need more than an id param to identify arbitrary data must still be discussed.
    struct Data {
        address developer;
        bytes32 id;
        uint256 balance;
        uint256 rate;
        uint256 available;
        uint256 v_minted;
        uint256 v_cast;
        uint256 e_balance;
        uint256 received;
    }
    
    Data[] public dapps;
    mapping(bytes32 => uint) public id2index;
    
    event DAppCreated(bytes32 id, uint256 amount);
    event upvote(bytes32 id, uint256 amount, uint256 newEffectiveBalance);
    event downvote(bytes32 id, uint256 amount, uint256 votes_cast, uint256 newEffectiveBalance);
    event withdraw(bytes32 id, uint256 amount, uint256 newEffectiveBalance);
    
    
    /*
        Anyone can create a DApp (i.e an arb piece of data this contract happens to care about)
        and there is no need even to start off with a positive balance (i.e. you can stake 0).
    */
    function createDApp(bytes32 _id, uint256 _amount) public { 
        require(SNT.allowance(msg.sender, address(this)) >= _amountToStake);
        require(SNT.transferFrom(msg.sender, address(this), _amountToStake));
        
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
        d.received = 0;

        id2index[_id] = dappIdx;

        emit DAppCreated(_id, _amount);
    }
    
    
    /* 
        For use in the UI to show how the effective balance changes as a result of your donation.
        This does _not_ mean it uses the curve: funds donated in upvoting go directly
        to the Dapp's balance in the store, not the developer's pocket. It's just that actual
        ranking is done on e_balance, and this must still be recalculated, even for upvotes.
    */
    function upvoteEffect(bytes32 _id, uint256 _amount) public returns(uint256 effect) { 
        uint dappIdx = id2index[_id];
        Dapp storage d = dapps[dappIdx];
        require(d.id == _id);
        
        uint mBalance = d.balance + _amount;
        uint mRate = 1 - (mBalance/max);
        uint mAvailable = mBalance * mRate;
        uint mMinted = mAvailable ** (1/mRate);
        uint mEBalance = mBalance - ((mMinted/(1/mRate))*(mAvailable/mMinted));
        
        return (mEBalance - d.e_balance);
    }
    
    
    /*
        Upvoting sends SNT directly to the contract, not to the developer and this gets
        added to the DApp's balance, no curve required.
    */
    function upvote(bytes32 _id, uint256 _amount) public { 
        require(_amount != 0);
        require(SNT.allowance(msg.sender, address(this)) >= _amount);
        require(SNT.transferFrom(msg.sender, address(this), _amount));
        
        uint dappIdx = id2index[_id];
        Dapp storage d = dapps[dappIdx];
        require(d.id == _id);
        
        d.balance = d.balance + _amount;
        d.rate = 1 - (d.balance/max);
        d.available = d.balance * d.rate;
        d.v_minted = d.available ** (1/d.rate);
        d.e_balance = d.balance - ((d.v_cast/(1/d.rate))*(d.available/d.v_minted));
        
        emit upvote(_id, _amount, d.e_balance);
    }
    
    
    /*
        For use in the UI, along with a slider that allows you to pick the % effect
        you want to have on a DApp's rankings before calculating the cost to you.
        Designs here: https://www.figma.com/file/MYWmd1buvc2AMvUmFP9w42t5/Discovery?node-id=604%3A5110
    */
    function downvoteCost(bytes32 _id, uint8 _percent_down) public returns(uint256 cost) { 
        require(1 < _percent_down < 99);
        
        uint dappIdx = id2index[_id];
        Dapp storage d = dapps[dappIdx];
        require(d.id == _id);
        
        uint balance_down_by = (_percent_down * d.e_balance);
        uint votes_required = (balance_down_by * d.v_minted * d.rate) / d.available;
        return cost = (d.available / (d.v_minted - (d.v_cast + votes_required))) * (votes_required / _percent_down / 100);
    }
    
    
    /*
        Downvoting sends SNT back to the developer of the DApp, while lowering the DApp's
        effective balance in the Store.
        The reason that _percent_down is still a param is because firguring out the effect on the
        effective balance without it requires integration, which is not nice in Solidity.
    */
    function downvote(bytes32 _id, uint8 _percent_down, uint256 _amount) public { 
        require(1 < _percent_down < 99);
        require(_amount != 0);
         
        uint dappIdx = id2index[_id];
        Dapp storage d = dapps[dappIdx];
        require(d.id == _id);
        
        uint cost = downvoteCost(_id, _percent_down);
        /* 
            TODO: what happens when the amount is greater, or lesser, than the cost?
            Greater than should be returned to user,
            lesser than throw an error that says the parameters have changed.
            Not a good UI though - any better solutions?
        */
        require(_amount >= cost);
        
        uint balance_down_by = (_percent_down * d.e_balance);
        uint votes_required = (balance_down_by * d.v_minted * d.rate) / d.available;
        
        d.available = d.available - cost;
        d.v_cast = d.v_cast + votes_required;
        d.e_balance = d.e_balance - balance_down_by;
        d.received = d.received + _amount;
        
        /*  
            TODO: This implies users must grant allowance to the DApp store
            when upvoting, and then for each individual DApp they want to downvote. Could
            be an annoying UI feature if so. Is there a better way?
        */
        require(SNT.allowance(msg.sender, d.developer) >= _amount);
        require(SNT.transferFrom(msg.sender, d.developer, _amount));
        
        emit downvote(_id, _amount, votes_required, d.e_balance);
    }
    
    
    /*  
        Developers can withdraw an amount not more than what was available of the
        SNT they originally staked minus what they have already received back in downvotes.
    */
    function withdraw(bytes32 _id, uint256 _amount) public { 
        uint dappIdx = id2index[_id];
        Dapp storage d = dapps[dappIdx];
        
        require(d.id == _id);
        require(msg.sender == d.developer);
        require(_amount <= (d.available - d.received));
        
        d.balance -= _amount;
        d.rate = 1 - (d.balance/max);
        d.available = d.balance * d.rate;
        d.v_minted = d.available ** (1/d.rate);
        d.e_balance = d.balance - ((d.v_cast/(1/d.rate))*(d.available/d.v_minted));
        
        /*  
            TODO: Not sure how to actually send funds out of this contract and back
            to developers when they wish to withdraw?
        */
        require(SNT.allowance(address(this), d.developer) >= _amount);
        require(SNT.transferFrom(address(this), d.developer, _amount));
        
        emit withdraw(_id, _amount, d.e_balance);
    }
}
