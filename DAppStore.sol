/* 

A pseudo-code decentralised solution to curating information is proposed here by solving the combination of:    
    
    1. An exponential bonded curve, which makes influencing the ranking of a product cheaper as a known entity pays more for that ranking.   
    2. A boundary value problem, which links the "expense to mint" (i.e to have your say) with the impact your say has on the ranking of that entity's product.    
    3. An optimisation problem, which removes the need for human judgement about the % staked that is available for you to have your say with.
    
When handled a certain way, all 3 problems can be cast as functions of the same 2 simple constants: a curve_factor and a percent_snt (of TOTAL_SNT). 
2 constants is really easy (and cheap) to code...

The spreadsheet with the curve calculations and simulations can be found here: https://docs.google.com/spreadsheets/d/1V1EMpDtAa7pP9F968VBb3dc2GUOT_BmS7-dK_0kwSDw/edit?usp=sharing

*/

pragma solidity 0.4.24^;

contract DAppStore {
    
    // Needed to send SNT used for voting back to developer
    address public _developer;
    
    // Consult spreadsheet for these 3 values
    uint256 public TOTAL_SNT = 3,470,483,788;
    uint256 public percent_snt = 0.000001;
    
    // You can only mint "votes" by expressing an opinion.
    // NB: with the curve I've designed, I'd rather use the word "vote" to play this game clearly with. 
    // "Token" implies it needs to go somewherwhere, be sent to someone as a reward etc., which it doesn't.
    // It just needs to be a structure with 2 props that we can do mathematical operations against.
    struct public Vote {
        uint256 NumberMinted;
        bool positive;
    };  
    
    // TODO: could we move this struct into an upgradeable library of sorts to make this into a totally general solution?
    struct public Dapp {
        bytes32 category;
        bytes32 name;
        bytes32 id;
        uint256 _SNTBalance;
        uint256 _effectiveBalance;
        Vote votes;
    }
    mapping (uint => Dapp) dapps;
    
    function createDApp(bytes32 _category, bytes32 _name, bytes32 _id) public {
        // I've written msg.data.tokens everywhere. Yes, I know that's not a thing.
        // It will have to be approveAndTransfers of SNT in the real contract, I just didn't want that mess here for now.
        // The id is shared out of band through the `Optimised for Status` program, along with the SNT to stake.
        require(msg.data.tokens > 0); // explained in the costToMint() function
        _developer = msg.sender;
        dapp.category = _category;
        dapp.name = _name;
        dapp.id = _id;
        // set the _SNTbalance in the mapping with msg.data.tokens
        // store the uint for mapping from dapps to this DApp with the id somehow, so that Status can identify legit dapps.
    }    
    
    // The rankings should be done externally, by reading from the chain. The Dapps with the highest 
    // (_SNTBalance - _effectiveBalance) are those displayed in Status. 
    // Each release post can have a report with data from the chain
    // and hopefully we can get to a place soon where we can automate it all, and maybe even make it dynamic.
    
    function numVotesToMint(uint256 _SNTBalance) internal returns(uint256) {
        
        if (_SNTBalance <= TOTAL_SNT * snt_percent) {
            // If there is less staked than the first interval, this needs to reflect F2
            // Needs to be interval / rate, but rate = interval * percent_snt
            var num_votes_to_mint_at_1 = (1 / percent_snt); 
            return num_votes_to_mint; 
        }
         
        if (_SNTBalance > TOTAL_SNT * snt_percent) {
            // We need to know the interval _SNTBalance is in and the number of tokens minted previously.
            // interval, for this curve, is just TOTAL_SNT * snt_percent, though.
            // This is why the interval and the rate must be functions only of the TOTAL_SNT.
            
             var current_interval_index = Math.round(_SNTBalance / (TOTAL_SNT * snt_percent));
             // The Math.round trick is why it is important that the interval is defined as an arithmetic sequence.
             
            // Get the previous number of tokens, i.e. (1) the exponential => linear optimisation problem
            // How we parameterize our linearization of the exponential really matters
            // Done well, it results in the below:
            // % available = curve,
            // % available =_SNTBalance * curve - % negative, and
            // % negative = _effectiveBalance
            // => _SNTBalance * curve - effectiveBalance = curve
            // =>_SNTBalance - (_effectiveBalance / curve) = 1
            // => _SNTBalance = _effectiveBalance * curve_factor
            // => or curve_factor = (_SNTBalance / _effectiveBalance)         
            return num_tokens_to_mint = num_votes_to_mint_at_1 + ((_SNTBalance / _effectiveBalance) / current_interval_index * num_votes_to_mint_at_1);
                     
            // Why are the curve and the current_interval_index inversely related?
            // One way of intuiting it is that we have to ask which of those two values, 
            // _SNTBalance or _effectivebalance will ever be zero. if either? And we know _effectiveBalance can be zero:
            // it's simply when there have been no negative votes. However, it does mean that 
            // _SNTBalance will need to be set to something, i.e. there is a need to set the balance, 
            // otherwise the code breaks at 0, not because we want to charge anything.
            // That's just a simple check in the contract, and it is just SNT > 0, 
            // to make it cheap for anyone to create a new struct in the DApp store, because the whole point is to be radically open, 
            // with no single point of control.
            // Therefore, we require that _effectiveBalance is the numerator, because it can be zero, and we don't want to be dividing by 0.
        }
    } 
    
    function costOfMinting(uint256 _SNT) public view returns(uint256) {
        // Used in UI to calculate fees
        return numVotesToMintCurve(_SNT);
    }
    
    function stake() public {
        // Anyone can stake further funds for this DApp!
        // We just handle that in the UI. You click upvote, it shows you 
        // 2 options: "Community Love" (buy DAppTokens through upvote())
        // or "Promote and Protect" (stake however much SNT you like directly).
        // You click downvote, you just downvote(), with an explanation
        // of why you have to pay for it.
        SNTbalance += msg.data.tokens;
        // No need to mint if curve works off SNTBalance
    }
    
    function upvote() public {
        // Needs to calculate first how many tokens to mint
        var dappvotes = numVotesToMint(msg.data.tokens);
        // Pay SNT to promote
        mint(dappvotes, true);
        // Send the SNT to the developer
        send(msg.data.tokens);
    }
    
    function downVote() public {
       // Needs to calculate first how many tokens to mint
        var dappvotes = numVotesToMint(msg.data.tokens);
        // Pay SNT to complain 
       mint(dappvotes, false);
       // Send the SNT to the developer
       send(msg.data.tokens);
       
       // Remove the same value from effective stake as we added to % negative votes
       // We need to calculate the effect these votes have on the % negative votes, 
       // then subtract the absolute value from _effectiveBalance.
       // i.e. (2) the boundary value problem
       var negative_votes_before = _effectiveBalance;
       var negative_votes_now = effectiveBalance + dappvotes;
       var negative_percent = ((negative_votes_now - negative_votes_before) / negative_votes_now ) * 100
       _effectiveBalance -= negative_percent;
       // See spreadsheet for proof.
       // We can read both _SNTBalance and _effectiveBalance ourselves from the chain anyway, no need to waste gas 
       // on further calculations here.
    }
    
    function withdrawStake(uint256 _amount) public {
        // This one gets hairy if dev keys are compromised, not just lost
        if(msg.sender == developer && _amount <= SNTBalance) {
            SNTBalance -= _amount;
            send(_amount);
        }
    }
    
    function mint(uint256 _amount, bool _positive) internal {
        // Mint the votes here
        votes.push(Vote(_amount, _positive));
    }
    
    function send(uint256 _amount) internal {
        // Called when upvotes or downvotes need to send SNT to the developer
        send(_developer, _amount);
    }
}