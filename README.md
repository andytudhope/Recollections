# theStateOfUs

The beauty of Ethereum to me, can be summed up simply:

`By deploying immutable contracts to a shared, public computational surface - contracts whose data can be read deterministically by anyone with access to the internet - we can encode idealism into the way we run society.`

What's more, **what's different this time**, is that the idealism exists independently of the people who encoded it, who inevitably become corrupted in some way, because we are all human. And to be human is to be corruptible, in some very real and simple way. 

So, I have designed a pretty neat way to curate DApps in our registry, which I think represents a *general* solution to the problem of how best and most simply to curate information without any central form of authority *including the community*, because cryptoeconomics is not about egalitarianism, it is about designing systems with no central point of control. Decentralisation is the goal, egalitarianism is a great success metric. But not the way around.

In the hope that I am right about idealism, and that it doesn't matter where this comes from (within or outside of Status) because ideas are what are really most powerful over a long enough period of time, and in the spirit of open source code, you can check out the pseudo code and the way I calculated the curve used [here](https://docs.google.com/spreadsheets/d/1V1EMpDtAa7pP9F968VBb3dc2GUOT_BmS7-dK_0kwSDw/edit?usp=sharing).

Even better, I don't think this would work if it were run as a closed source project, as it would result in insane benefits to early token holders of that particular token, which violates the "egalitarianism as a success metric" clause. So, having done the leg work, making sure the idea starts out as open source is the last big piece to place.


## FAQs

**OK cool, explain it to me like I am 12. Basically you stake SNT that an app will be popular later, and the input & output of the staked SNT is controlled by 2 bonded curves?**

No, the Dapp Store rankings are done on how much SNT is staked by the developer, it is as simple as that. Pure price discovery mechanism.

Except there is one twist.

The more SNT you stake to get higher in the overall rankings, the easier and cheaper it is for other people to influence your ranking.

That is why we use a bonded curve (there is only one of them): to make minting votes progressively cheaper in an exponential way.

However, coding exponentials is hard and expensive, and means we have to store each interval, which is also hard and expensive.
So, we need to apply some factor that turns our exponential relationship between cost to mint and num votes minted into a linear one.
Linear relationships are easy to code: they are just arithmetic sequences.
So, we're looking for a factor that will turn exponential => linear.

Casting the rate and the interval as functions of Total SNT means we can exclude them as variables, and just use an interval of Total SNT x Y % = interval. Which makes Y that factor which can be used to turn the exponential linear, so that we can code it cheaply.
Which makes Y that factor which can be used to turn the exponential linear, so that we can code it cheaply.
The `curve_factor` is the other important concept to grasp, but it's somewhat mystical and has to do with boundary problems and the exact way the algorithm is put together.

**The need to linearize the exponential curves sounds like it comes only from that being hard to do in Ethereum? Aren't all of these things are just premature optimisations that we shouldn't need to be doing?**

This is not a premature optimisation, it is the thing itself which makes it all work, because the rate and interval are set as functions of TOTAL SNT and we just optimise the 2 constants parameterising things that way gives us.

**OK, explain the incentives to me on the contract in terms of 1.) the user of the app 2.) the developer**

1. The user of the app - NO INCENTIVES, this is the sociological factor that makes it all work. People are always saying "We need to get the community more involved! Let's incentivise them to curate information FOR us, so we don't have to do it".
No! That's not the point of mechanism design as applied to cryptoeconomics. The point is to create systems that use mathematics and/or cryptography so that NO-ONE has undue influence over the system.
It costs users to vote, so they would only do so to complain (if they feel really strongly), or donate to/protect an app that is being trolled. #EffectiveDirectCharity.

2. The developer is incentivised by appearing higher in the registry, and by being able to receive back at least 52% (in this curve) of the SNT they staked if they get trolled, 
do something the community doesn't like resulting in downvotes, OR do something awesome that the community likes, and wants to donate to.
Complaining and donating are the same economic signal with signs reversed, so we can treat them the same mathematically if we set things up correctly.

This is why this is not just a solution for a DappStore, but a general solution for curating information when there is some known bound to how that information is curated (here the Total SNT In Circulation).
PageRank's big insight when the web got going was that sorting information effectively was more important than displaying it well, which is what everyone else was trying to do. 
The big insight here is that, in the decentralized web, sorting information becomes hard because there is no central authority. 
So it's not about sorting, it's about curating, and we need to figure out the way to do that most optimally - which is what this curve and contract are. (Maybe not most optimally, but close anyway).

**I mean with a centralised authority bad apps get pulled immediately. If it's decentralised the curve has to kick in first, right? Isn't that a problem/too slow?**

The point is that the contract represents *contractual reality*, to which we as Status are not bound, if we do not wish to be. 
Code is *like* law, but even law is just the rules other people have made (people no better, nor any worse, than us).
Status does not have to show the exact rankings in the registry. We can reserve the right to ban a DApp for 2, very specific, and falsifiable reasons:

1. Malicious code. Requires a link to code and proof of why it is malicious.
2. Vote manipulation. Requires a blockchain proof of suspicious transactions.

**So in the current model only the developer can stake? Or is there an option for others to participate as well?**

Yeah, of course! Anyone can stake, and we provide the option in the UI. When you chose to upvote, it's either "Promote and protect" == staking more
or "Community love" meaning minting positive votes and sending a portion of that SNT to the developer. 
A portion that relies only on the params of the curve being used to protect the integrity of the store as a whole.

**Is it possible to pump and dump an app?**

Not really, because you're only using SNT, not a token linked to the market cap or value of that specific app.
Anyway, dropping the rankings just means the developer is getting potentially half their money back, which they can use to increase stake etc.

**Will our minimum stake for the developer be dynamic based on the total curve, or by some fixed _fiat_ value?**

No minimum stake if you look at the contract. Anyone can create a DApp, with or without tokens.
However, if you send tokens along with the call to create the Dapp (not sure how to do this yet, maybe a proxy with `approveAndTransfer` somehow?)
then that dapp is created with a starting balance, which is - again - what is used to rank it, whatever that starting balance is (even if 0).
This means the minimum cost to list a DApp (or any piece of information you might like) is only the gas costs of creating a new struct in a contract (i.e. very low)

**I'm a DApp developer. I'm going to stake my SNT, then buy back all the tokens I can and vote positively with them, for which I get the SNT used to vote as the developer anyway?**

Yip, that's true. So, we need to ask, what is the maximum cost to a developer? In this set up it's the curve factor, 0.52. That is, for 52% of what it would actually have cost in SNT, I can get to the top of the registry and ensure no-one can vote against me. Read on...
This is why there is no incentive to upvote (other than to protect or donate). Positive votes don't influence your "effective" stake, only negative votes count.

**Re-iterate:** upvoting is only a social signal for the UI, there is no contractual benefit. The only reason to upvote, other than protect/donate, is to increase how expensive it is (by decreasing % negative) to downvote your DApp by buying up tokens.
You could call the contract yourself manually with the right data, upvote yourself massively and have the SNT come right back to you (one reason why only, say, 52% is available). 
a) that's not actually optimal (because of the UI catch) and b) it's only about social signalling, so it's possible to prove that behaviour on the chain, and Status can block from the UI only 2 things: DApps that manipulate voting, or mailicious code.
Hence you run the risk of spending 52% of the SNT required to top the registry and STILL being blocked in the UI. 
Note "the SNT required to top the registry" above. This is the surest signal that the cryptoeconomic security of DApps on top of the registry is a purely a function of the total SNT staked

This is one way of casting the game being played: How much SNT is worth risking against the chance that the UI can divert from contractual reality under specific, well-defined conditions versus how much SNT do we need to return to make sure developers get back enough in order to make it worth their while to stake SNT in the first place? 

**Is there any contractual rule about voting for yourself?**

Even if that could be reliably identified, there's nothing to stop you voting for yourself in the actual contract. However, there is a social contract that Status upholds 
which says that manipulating more than - say - 50% of the votes unprovoked, or some more suitable param, gets you pulled from the UI.

Yes, one day I envision DApp store wars, where devs have to buy tokens to prevent themselves being downvoted which, neatly, corresponds to a donation in SNT to the whole community. 
So, if they're fighting a competitor/troll trying who is downvoting them, they can stake more, upvote themselves and/or fight back/apply for help. Or, if they did something that upset their customers or the wider community, 
they'll need to stake more and buy back votes too. Sounds like a better form of contrition to me. 

All the while, more SNT goes into the cryptoeconomic security of the dapp store as a whole - **this is the key insight here**.

Anti-social behaviour (trolling) and corporate competitiveness == community love in the form of both a more secure registry in this scheme and (potentially) higher SNT prices as there's less SNT in circulation ;)
