## FAQs

**OK cool, explain it to me like I am 12. Basically you stake SNT that an app will be popular later, and the input & output of the staked SNT is controlled by 2 bonded curves?**

No, the Dapp Store rankings are done on how much SNT is staked by the developer, it is as simple as that. Pure price discovery mechanism.

Except there is one twist.

The more SNT you stake to get higher in the overall rankings, the easier and cheaper it is for other people to influence your ranking.

That is why we use a bonded curve (there is only one of them): to make minting votes progressively cheaper in an exponential way.

However, coding exponentials is hard, and it means we have to store each interval, which is  expensive.
So, we need to apply some factor that turns our exponential relationship between cost to mint and num votes minted into a linear one.
Linear relationships are easy to code: they are just arithmetic sequences.
So, we're looking for a factor that will turn exponential => linear.

Casting the rate and the interval as functions of Total SNT means we can exclude them as variables, and just use an interval of Total SNT x Y % = interval. Which makes Y that factor which can be used to turn the exponential linear, so that we can code it cheaply.

The `curve_factor` is the other important concept to grasp, but it's somewhat mystical and has to do with boundary problems and the exact way the algorithm is put together.

**The need to linearize the exponential curves sounds like it comes only from that being hard to do in Ethereum? Aren't all of these things are just premature optimisations that we shouldn't need to be doing?**

Linearization is not a premature optimisation, it is the thing itself which makes it all work, because the rate and interval are set as functions of TOTAL SNT and we just optimise the 2 constants parameterising things that way gives us.

**OK, explain the incentives to me on the contract in terms of 1.) the user of the app 2.) the developer?**

1. The user of the app - NO INCENTIVES, this is the sociological factor that makes it all work. People are always saying "We need to get the community more involved! Let's incentivise them to curate information FOR us, so we don't have to do it".
No! That's not the point of mechanism design as applied to cryptoeconomics. The point is to create systems that use mathematics and/or cryptography so that NO-ONE has undue influence over the system.
It costs users to vote, so they would only do so to complain (if they feel really strongly), or donate to/protect an app that is being trolled. #EffectiveDirectCharity.

2. The developer is incentivised by appearing higher in the Dapp store, and by being able to receive back at least 52% (in this curve) of the SNT they staked if they get trolled, 
do something the community doesn't like resulting in downvotes, OR do something awesome that the community likes, and wants to donate to.
Complaining and donating are the same economic signal with signs reversed, so we can treat them the same mathematically if we set things up correctly.

This is why this is not just a solution for a DappStore, but a general solution for curating information when there is some known bound to how that information is curated (here the Total SNT In Circulation).
PageRank's big insight when the web got going was that sorting information effectively was more important than displaying it well, which is what everyone else was trying to do. 
The big insight here is that, in the decentralized web, the simple fact that there is, by definition, no central authority means it's not about sorting at all. 
It's about curating, and we need to figure out the way to do that most optimally - which is what this curve and contract are. (Maybe not most optimally, but close anyway).

**I mean with a centralised authority bad apps get pulled immediately. If it's decentralised the curve has to kick in first, right? Isn't that a problem/too slow?**

The point is that the contract represents *contractual reality*, to which we as Status are not bound, if we do not wish to be. 
Code is *like* law, but even law is just the rules other people have made (people no better, nor any worse, than us).
Status does not have to show the exact rankings in the Dapp store. We can reserve the right to ban a DApp for 2, very specific, and falsifiable reasons:

1. Malicious code. Requires a link to code and proof of why it is malicious.
2. Vote manipulation. Requires a blockchain proof of suspicious transactions.

**So in the current model only the developer can stake? Or is there an option for others to participate as well?**

Yeah, of course! Anyone can stake, and we provide the option in the UI. When you chose to upvote, it's either "Promote and protect" == staking more
or "Community love" == minting positive votes and sending a portion of that SNT to the developer. 
A portion that relies only on the params of the curve being used to protect the integrity of the store as a whole.

**Is it possible to pump and dump an app?**

Not really, because you're only using SNT, not a token linked to the market cap or value of that specific app.
Anyway, dropping the rankings just means the developer is getting potentially half their money back, which they can use to increase stake etc.

**Will our minimum stake for the developer be dynamic based on the total curve, or by some fixed _fiat_ value?**

There is no minimum stake if you look at the contract. Anyone can create a DApp, with or without tokens.
However, if you send tokens along with the call to create the Dapp (not sure how to do this yet, maybe a proxy with `approveAndTransfer` somehow?)
then that dapp is created with a starting balance, which is - again - what is used to rank it, whatever that starting balance is (even if 0).
This means the minimum cost to list a DApp (or any piece of information you might like) is only the gas costs of creating a new struct in a contract (i.e. very low)

**I'm a DApp developer. I'm going to stake my SNT, then buy back all the tokens I can and vote positively with them, for which I get the SNT used to vote, because I'm the developer?**

Yip, that's true. So, we need to ask, what is the maximum cost to a developer to rank first? In this set up it's ( 1 / `curve_factor` ), roughly 0.52. That is, for 52% of what it would actually have cost in SNT, I can get to the top of the DApp store and ensure no-one can vote against me. Read on...
This is why there is no incentive to upvote (other than to protect or donate). Positive votes don't influence your "effective" stake, only negative votes count.

**Re-iterate:** upvoting is only a social signal for the UI, there is no contractual benefit. The only reason to upvote, other than protect/donate, is to increase how expensive it is (by decreasing % negative) to downvote your DApp by buying up tokens.
You could call the contract yourself manually with the right data, upvote yourself massively and have the SNT come right back to you (one reason why only, say, 52% is available). 
a) that's not actually optimal (because of the UI catch) and b) it's only about social signalling, so it's possible to prove that behaviour on the chain, and Status can block from the UI only 2 things: DApps that manipulate voting, or mailicious code.
Hence you run the risk of spending 52% of the SNT required to top the DApp store and STILL being blocked in the UI. 
Note "the SNT required to top the dapp store" above. This is the surest signal that the cryptoeconomic security of DApps on top of the DApp store is a purely a function of the total SNT staked

This is one way of casting the game being played: How much SNT is worth risking against the chance that the UI can divert from contractual reality under specific, well-defined conditions versus how much SNT do we need to return to make sure developers get back enough in order to make it worth their while to stake SNT in the first place, which also effects how secure the DApp store is as a whole.? 

**Is there any contractual rule about voting for yourself?**

Even if that could be reliably identified, there's nothing to stop you voting for yourself in the actual contract. However, there is a social contract that Status upholds 
which says that manipulating more than - say - 50% of the votes unprovoked, or some more suitable param, gets you pulled from the UI.

Yes, one day I envision DApp store wars, where devs have to buy tokens to prevent themselves being downvoted which, neatly, corresponds to a donation in SNT to the whole community. 
So, if they're fighting a competitor/troll trying who is downvoting them, they can stake more, upvote themselves and/or fight back/apply for help. Or, if they did something that upset their customers or the wider community, 
they'll need to stake more and buy back votes too. Sounds like a better form of contrition to me. 

All the while, more SNT goes into the cryptoeconomic security of the dapp store as a whole - **this is the key insight here**.

Anti-social behaviour (trolling) and corporate competitiveness == community love in the form of both a more secure Dapp store in this scheme and (potentially) higher SNT prices as there's less SNT in circulation ;)


**It seems like the weakness here is not the math, but that the fact that the participants have no reasonable incentives. If developers have to stake and they don’t really get the bulk of those resouces back and the users don’t ever need to use it, what’s the point? The developers won’t stake if there’s no users, and no users will use it because there’s no incentive for them to vote on Dapps.**

Why do people pay for AdWords, SEO, etc. then? Or as users, do we use PageRank, even though there is no incentive to vote on which links appear first and why? This is exactly the same incentive structure when you really think about it, except the users have no influence at all over what they see, it's not transparent about who is at the top and why, and we all just have to trust Google "not to be evil"...

**I am still not clear on how this interacts with upvotes and downvotes. If dapp A has 2500 SNT staked with 10 upvotes and 0 downvotes, and dapp B has 2600 SNT staked with 2 upvotes and 4 downvotes, who gets ranked higher?**

If you look at the contract, there is an idea named `_effectiveBalance`, which is what the DApp actually gets ranked on. As it turns out, because of the boundary value problem solved on the curve_algo sheet in the spreadsheet above, we can subtract the same absolute value X from `_effectiveBalance` in SNT as the % effect on `staked_available` (cell H2 in the sheet) downvoting X times would have.

So, dapp A would have `_effectiveBalance` 2500 SNT, dapp B 2596 SNT, therefore DApp B ranks higher.

I think the SNT staked can be withdrawn at any time yes, also defined in the contract (though I worry about key management and developers getting compromised there). Open to suggestions on delays/restrictions that might make this more secure.

If you're asking how I got to those values, it's important to realise that **upvoting has NO EFFECT** on the `_effectiveBalance` on the DApp (it just makes it more expensive to mint future votes). This is important because there are already perverse incentives for developers to stake their app to the top of the rankings and then just buy all the votes available and use them to upvote, getting 52% of their money back and ensuring that no-one can move their DApp down (other than another developer staking more, obvs).

So, we implement a social contract that says Status does not have to honour the the contractual reality in 2 very specific, narrow and *falsifiable* conditions:

1. Malicious code: requires a link to the code and a proof of why it is malicious.
2. Vote manipulation: requires blockchain proof of suspicious transactions.

**What are the votes denominated in? Do the votes also involve staking SNT, or is it something else?**

Votes are not "denominated" in anything, there are just more and more of them "minted" as more SNT is staked, so that they have a bigger effect on _effectiveBalance, and therefore satisfy the condition that, the more someone stakes the get to the top of the store, the easier it is the influence that position.

Minting votes does cost SNT though, yes. A cost that is also calculated in the sheet above, based on the params explained.