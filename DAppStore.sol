pragma solidity >=0.4.22 <0.6.0;

import './token/MiniMeTokenInterface.sol';


contract DAppStore {
    
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
    uint8 ceiling = 0.4;
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
    
    
    /*
        Anyone can create a DApp (i.e an arb piece of data this contract happens to care about).
    */
    function createDApp(bytes32 _id, uint _amount) public { 
        require(_amount > 0, "You must spend some SNT to submit a DApp for ranking in order to avoid spam")
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
    
    
    /* 
        For use in the UI to show how the effective balance changes as a result of your donation.
        This does _not_ mean it uses the curve: funds donated in upvoting go directly
        to the Dapp's balance in the store, not the developer's pocket. It's just that actual
        ranking is done on e_balance, and this must still be recalculated, even for upvotes.
    */
    function upvoteEffect(bytes32 _id, uint _amount) public returns(uint effect) { 
        uint dappIdx = id2index[_id];
        Data memory d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct DApp");
        
        uint mBalance = d.balance + _amount;
        uint mRate = 1 - (mBalance/max);
        uint mAvailable = mBalance * mRate;
        uint mVMinted = mAvailable ** (1/mRate);
        uint mEBalance = mBalance - ((mVMinted/(1/mRate))*(mAvailable/mVMinted));
        
        return (mEBalance - d.e_balance);
    }
    
    
    /*
        Upvoting sends SNT directly to the contract, not to the developer and this gets
        added to the DApp's balance, no curve required.
    */
    function upvote(bytes32 _id, uint _amount) public { 
        require(_amount > 0, "You must send some SNT in order to upvote");
        require(SNT.allowance(msg.sender, address(this)) >= _amount);
        require(SNT.transferFrom(msg.sender, address(this), _amount));
        
        uint dappIdx = id2index[_id];
        Data storage d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct DApp");
        
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
    function downvoteCost(bytes32 _id, uint _percent_down) public returns(uint256 cost) { 
        require(0.01 <= _percent_down <= 0.99, "You must effect the DApp by more than 1, and less than 99, percent");
        
        uint dappIdx = id2index[_id];
        Data memory d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct DApp");
        
        uint balance_down_by = (_percent_down * d.e_balance);
        uint votes_required = (balance_down_by * d.v_minted * d.rate) / d.available;
        return cost = (d.available / (d.v_minted - (d.v_cast + votes_required))) * (votes_required / _percent_down / 100);
    }
    
    
    /*
        Downvoting sends SNT back to the developer of the DApp, while lowering the DApp's
        effective balance in the Store.
        The reason that _percent_down is still a param is because figuring out the effect on the
        effective balance without it requires integration, which is not nice in Solidity.
    */
    function downvote(bytes32 _id, uint8 _percent_down, uint _amount) public { 
        require(0.01 <= _percent_down <= 0.99, "You must effect the DApp by more than 1, and less than 99, percent");
        require(_amount > 0, "You must send some SNT in order to downvote");
         
        uint dappIdx = id2index[_id];
        Data storage d = dapps[dappIdx];
        require(d.id == _id, "Error fetching correct DApp");
        
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
            TODO: This implies users must grant allowance to the DApp store
            when upvoting, and then for each individual DApp they want to downvote. Could
            be an annoying UI feature if so. Is there a better way?
        */
        require(SNT.allowance(msg.sender, d.developer) >= cost);
        require(SNT.transferFrom(msg.sender, d.developer, cost));
        
        emit downvote(_id, cost, d.e_balance);
    }
    
    
    /*  
        Developers can withdraw an amount not more than what was available of the
        SNT they originally staked minus what they have already received back in downvotes.
    */
    function withdraw(bytes32 _id, uint _amount) public { 
        require(msg.sender == d.developer, "Only the developer can withdraw SNT staked on this DApp");
        
        uint dappIdx = id2index[_id];
        Data storage d = dapps[dappIdx];
        require(d.id == _id);
        
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
        SNT.allowance(address(this), d.developer) = _amount;
        SNT.transferFrom(address(this), d.developer, _amount);
        
        emit withdraw(_id, _amount, d.e_balance);
    }
}
