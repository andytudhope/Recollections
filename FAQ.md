## FAQs

**OK cool, explain it to me like I am 12. Basically you stake SNT that an app will be popular later, and the input & output of the staked SNT is controlled by a bonded curve?**

No, the Dapp Store rankings are done on how much SNT is staked by the developer, it is as simple as that. Pure price discovery mechanism.

Except there is one twist.

The more SNT you stake to get higher in the overall rankings, the easier and cheaper it is for other people to influence your ranking.

That is why we use a bonded curve: to make minting votes progressively cheaper in an exponential way.

**OK, explain the incentives to me on the contract in terms of 1.) the user of the app 2.) the developer?**

1. The user of the app - NO INCENTIVES, this is the sociological factor that makes it all work. People are always saying "We need to get the community more involved! Let's incentivise them to curate information FOR us, so we don't have to do it".
No! That's not the point of mechanism design as applied to cryptoeconomics. The point is to create systems that use mathematics and/or cryptography so that NO-ONE has undue influence over the system.
It costs users to vote, so they would only do so to complain (if they feel really strongly), or donate to/protect an app that is being trolled. #EffectiveDirectCharity.

2. The developer is incentivised by appearing higher in the Dapp store, and by being able to receive back some % of the SNT they staked if they do something awesome that the community likes, and wants to donate to.

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

(potentially (3): a DApp that would get Status banned from the App Store, until we figure out alternative distribution mechanisms.)

**So in the current model only the developer can stake? Or is there an option for others to participate as well?**

Yeah, of course! Anyone can stake, and we provide the option in the UI. When you chose to upvote, it's either "Donate" == staking more or "Protect" == minting positive votes and sending a portion of that SNT to the developer.

A portion that relies only on the params of the curve being used to protect the integrity of the store as a whole.

**Is it possible to pump and dump an app?**

Not really, because you're only using SNT, not a token linked to the market cap or value of that specific app.

Anyway, dropping in the rankings just means the developer is getting a significant portion of their money back, which they can use to increase stake etc.

**Will our minimum stake for the developer be dynamic based on the total curve, or by some fixed _fiat_ value?**

There is no minimum stake if you look at the contract. Anyone can create a DApp, with or without tokens.

This means the minimum cost to list a DApp (or any piece of information you might like) is only the gas costs of creating a new struct in a contract (i.e. very low).

**I'm a DApp developer. I'm going to stake my SNT, then buy back all the tokens I can and vote positively with them, for which I get the SNT used to vote, because I'm the developer?**

Yip, that's true. That is, I can ensure no-one can vote against me while receiving back 62.5% of the SNT I staked at first. 

1. This is why there is no incentive in terms of an increased ranking to upvote. Positive votes don't influence your "effective" stake, only negative votes count.
2. We're back to point about _contractual reality_ versus the Status UI, though. As one implementation of an open contract, Status can still block from our UI two things: DApps that manipulate voting, or mailicious code (as both of these can be fairly objectively verified). Because such an action would require on chain actions, we could prove to a reasonable degree such vote mainpulation and block the DApp, which - once again - severely alters their incentive structure.

This is one way of casting the game being played: How much SNT is worth risking against the chance that the UI can divert from contractual reality under specific, well-defined conditions? This must be balanced in the design against how much SNT we need to return to make sure developers get back enough in order to make it worth their while to stake SNT in the first place (which also effects how secure the DApp store is as a whole)? 

**Is there any contractual rule about voting for yourself?**

Even if that could be reliably identified, there's nothing to stop you voting for yourself in the actual contract. However, there is a social contract that Status upholds which says that manipulating more than - say - 50% of the votes unprovoked, or some more suitable param, gets you pulled from the UI.

Yes, one day I envision DApp store wars, where devs have to stake more to prevent themselves moving down the rankings which, neatly, corresponds to a donation in SNT to the whole community. 

So, if they're fighting a competitor/troll trying who is downvoting them, they can stake more, upvote themselves and/or fight back/apply for help. Or, if they did something that upset their customers or the wider community, they'll need to stake more too. Sounds like a better form of contrition to me. 

All the while, more SNT goes into the cryptoeconomic security of the dapp store as a whole - **this is the key insight here**.

Anti-social behaviour (trolling) and corporate competitiveness == community love in the form of both a more secure Dapp store in this scheme and (potentially) higher SNT prices as there's less SNT in circulation ;)

**It seems like the weakness here is not the math, but that the fact that the participants have no reasonable incentives. If developers have to stake and they don’t really get the bulk of those resouces back and the users don’t ever need to use it, what’s the point? The developers won’t stake if there’s no users, and no users will use it because there’s no incentive for them to vote on Dapps.**

Why do people pay for AdWords, SEO, etc. then? Or as users, do we use PageRank, even though there is no incentive to vote on which links appear first and why? This is exactly the same incentive structure when you really think about it, except the users have no influence at all over what they see, it's not transparent about who is at the top and why, and we all just have to trust Google "not to be evil"...

**I am still not clear on how this interacts with upvotes and downvotes. If dapp A has 2500 SNT staked with 10 upvotes and 0 downvotes, and dapp B has 2600 SNT staked with 2 upvotes and 4 downvotes, who gets ranked higher?**

If you look at the contract, there is an idea named `_effectiveBalance`, which is what the DApp actually gets ranked on. As it turns out, because of the boundary value problem solved on the curve_algo sheet in the spreadsheet above, we can subtract the same absolute value X from `_effectiveBalance` in SNT as the % effect on `staked_available` (cell H2 in the sheet) downvoting X times would have.

So, dapp A would have `_effectiveBalance` 2500 SNT, dapp B 2596 SNT, therefore DApp B ranks higher.

I think the SNT staked can be withdrawn at any time yes, also defined in the contract (though I worry about key management and developers getting compromised there). Open to suggestions on delays/restrictions that might make this more secure.

If you're asking how I got to those values, it's important to realise that **upvoting has NO EFFECT** on the `_effectiveBalance` on the DApp (it just makes it more expensive to mint future votes). This is important because there are already perverse incentives for developers to stake their app to the top of the rankings and then just buy all the votes available and use them to upvote, getting some % of their money back and ensuring that no-one can move their DApp down (other than another developer staking more, obvs).

So, we implement a social contract that says Status does not have to honour the the contractual reality in 2 very specific, narrow and *falsifiable* conditions:

1. Malicious code: requires a link to the code and a proof of why it is malicious.
2. Vote manipulation: requires blockchain proof of suspicious transactions.

**What are the votes denominated in? Do the votes also involve staking SNT, or is it something else?**

Votes are not "denominated" in anything, there are just more and more of them "minted" as more SNT is staked, so that they have a bigger effect on _effectiveBalance, and therefore satisfy the condition that, the more someone stakes the get to the top of the store, the easier it is the influence that position.

Minting votes does cost SNT though, yes. A cost that is also calculated in the sheet above, based on the params explained.

**I think in terms of the staking by the app creators, this can be done via the Harberger tax. In terms of the up votes and down votes, this can be done via voice credits that are generated by the staking and activated using quadratic voting (QV) so that people can express intensity of up votes and down votes by showing with real stake.**

I like the ideas a lot, but my concern is less from an economic standpoint than from a User Interface and User Experience perspective. It introduces a fair degree of complexity into things, which comes with higher mental overheads than I _think_ most people are willing to deal with in addition to all the other various problems and concerns and daily headaches of life.

In my proposal, it's all very simple.

The developer **knows** that, in order to get onto the first page, they need to stake X amount, of which they can receive back a % defined only by the curve (i.e. the abstract mathematical structure) on which the game is based. 

The user **knows** that the information/products/services they are seeing are those that have provided most *literal* value to the system in which they're being ranked, because staking funds locks up a certain % of those funds (for as long as that info/product/service is ranked), which decreases the total amount of tokens in circulation, driving up demand and prices, and - again, quite literally - providing value to the community of token holders.

That is, using the system (I mean this as in simply using it to search, as we currently use Google) IS THE INCENTIVE for users, because they get to hold tokens that BOTH tend to go up in value the more value is used to rank information AND which can be used to influence directly the actual rankings. (But, only if they really choose to hold those tokens - using the system in no way requires it, which is also important.)

**The QV thing is a lot of fun because it creates a nice trade-off that makes people think about how strongly they feel about things.**

I think that we may disagree a little on the psychological question of whether people like having to think about how strongly they feel about things or not. (He said, blithely taking a plunge into yet another field he was no expert in ;)