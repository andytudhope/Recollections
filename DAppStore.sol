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
    uint256 public curve = (1/1.91);
    uint256 public interval = TOTAL_SNT / percent_snt;
    
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
        uint256 _effectOnBalance;
        Vote votes;
    }
    mapping (uint => Dapp) dapps;
    
    function createDApp(bytes32 _category, bytes32 _name, bytes32 _id) public {
        // I've written msg.data.tokens everywhere. Yes, I know that's not a thing.
        // It will have to be approveAndTransfers of SNT in the real contract, I just didn't want that mess here for now.
        // The id is shared out of band through the `Optimised for Status` program, along with the SNT to stake.
        _developer = msg.sender;
        dapp.category = _category;
        dapp.name = _name;
        dapp.id = _id;
        // set the _SNTbalance in the mapping with msg.data.tokens
        // store the uint for mapping from dapps to this DApp with the id somehow, so that Status can identify legit dapps.
    }    
    
    // The rankings should be done externally, by reading from the chain. The Dapps with the highest 
    // (_SNTBalance * _effectOnBalance) are those displayed in Status. 
    // Each release post can have a report with data from the chain
    // and hopefully we can get to a place soon where we can automate it all, and maybe even make it dynamic.
    
    function numVotesToMint(uint256 _SNTamount) internal returns(uint256) {
        
        if (_SNTamount == 0) {
            return num_votes_to_mint = 0;
        }

        // We need to return num_votes_minted per SNT in the first interval (K2)
        // This is the rate per SNT, multiplied by the % SNT actually available, 
        // to give the final number of votes minted per SNT in the first interval.
        // (_SNTamount / rate) * (% available - % negative)
        // (_SNTamount * curve) * (curve - _effectOnBalance)
        var num_votes_minted_in_1 = (_SNTamount * curve) * (curve - effectOnBalance);
         
        // We need to know the interval _SNTBalance + _SNTamount is in for the arithmetic sequence.
        // interval, for this curve, is just TOTAL_SNT * snt_percent, though.
            
        var current_interval_index = Math.round(_SNTBalance + _SNTamount / (interval));
        // The Math.round trick is why it is important that the interval is defined as an arithmetic sequence.
             
        // Because the curve is now linear based on how we have parameterised it, we can code
        // it easily as an arithmetic sequence based on the num_votes_minted_in_1:
        var num_votes_to_mint_per_snt = (_SNTamount * curve) * (curve - effectOnBalance) + (current_interval_index * (_SNTamount * curve) * (curve - effectOnBalance))
        // Still not right, but getting closer.

        return num_votes_to_mint = num_votes_to_mint_per_snt * _SNTamount;

    } 
    
    function costOfMinting(uint256 _SNT) public view returns(uint256) {
        // Used in UI to calculate fees
        var votes = numVotesToMint(_SNT);
        return votes/_SNT;
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
        // Upvoting == donating to the developer, and makes it more expensive to vote further
        send(msg.data.tokens);
    }
    
    function downVote() public {
       // Needs to calculate first how many tokens to mint
        var dappvotes = numVotesToMint(msg.data.tokens);
        // Pay SNT to complain 
       mint(dappvotes, false);
       // Downvoting affects the _effectiveBalance, and it's important to burn the SNT
       // Otherwise devs could stake bad/malicious apps, get money back as the community
       // downvotes them and then withdraw their stake having made a tidy profit.
       burn(msg.data.tokens);
       // We need to calculate the effect these votes have on the % negative votes, 
       // then add that to _effectOnBalance.
       var negative_votes_before = _effectOnBalance * _SNTBalance;
       var negative_votes_now = negative_votes_before + dappvotes;
       var negative_percent = ((negative_votes_now - negative_votes_before) / negative_votes_now ) * 100
       _effectOnBalance += negative_percent;
    }
    
    function withdrawStake(uint256 _amount) public {
        // This one gets hairy if dev keys are compromised, not just lost
        if(msg.sender == developer && _amount <= SNTBalance) {
            SNTBalance -= _amount;
            send(_developer, _amount);
        }
    }
    
    function mint(uint256 _amount, bool _positive) internal {
        // Mint the votes here
        votes.push(Vote(_amount, _positive));
    }
    
    function burn(uint256 _amount) internal {
        // Called when upvotes or downvotes need to send SNT to the developer
        send(0x0, _amount);
    }

    function send(uint256 _amount) internal {
        send(_developer, _amount);
    }
}