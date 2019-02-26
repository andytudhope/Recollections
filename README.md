# Recollections

The beauty of Ethereum to me, can be summed up simply:

`By deploying immutable contracts to a shared, public computational surface - contracts whose data can be read deterministically by anyone with access to the internet - we can encode idealism into the way we run society.`

What's more, **what's different this time**, is that the idealism exists independently of the people who encoded it, who inevitably become corrupted in some way, because we are all human. And to be human is to be corruptible, in some very real and simple way. 

My idealism arises out of cryptoeconomics, which is not about egalitarianism, but about designing systems with no central point of control. Decentralisation is the goal, egalitarianism is a great success metric. But not the way around, because egalitarianism is not a purely mathematical function that can be optimised.

1. Watch the [tech talk for a high-level overview here](https://youtu.be/82wMcgHSej0) (now a bit outdated). 

2. Play with a [live ObservableHQ notebook here](https://beta.observablehq.com/@andytudhope/dapp-store-snt-curation-mechanism).

3. Read the [contract in this repo](./DAppStore.sol).

3. Read the spec (WIP) [here](https://notes.status.im/rzuWBolLRzWgERjycKHP9Q).

## Can you give a maximally simple description of (1) who the participants are, (2) what actions the different categories of participants can take and (3) what the incentives are?

1. Participants are developers who want to see their DApp get ranked highly so people use it.

2. 
    1. Developers can stake SNT.
    2. Users can upvote or downvote their DApps, though I don’t see this happening too much, because it costs them and there is NO INCENTIVE for users, unless they’re feeling super motivated to make sure some DApp gets ranked less/more highly and are willing to pay to make that happen.
    3. Users simply benefit as a side-effect of the optimal curation of information, exactly like they do now.

The big difference here is that, instead of having limited insight into PageRank and what you are being shown on your search and why, you KNOW that the DApps that appear first are those who have paid the most.

People ask, “But, shouldn’t the DApps that appear the first be, the most useful or provide the most value to the community or something?” Yes, they absolutely should.

As we are all slowly figuring out though, the problem is with defining “value to the community”. Is that downloads, stars, usage metrics, customer feedback? All of these things are suboptimal and easy to manipulate.

The system I propose simply ranks the DApps that appear first by whichever ones provide most actual, *literal* value to the community. Staking to rank means less SNT is in circulation, which means that the value of each individual SNT goes up and that the developers who do pay to get their DApp ranked highly are - again, quite literally - providing economic value to the community of users and getting ranked appropriately on it. I believe it’s similar to what Vitalik wrote about [here](http://vitalik.ca/general/2017/10/17/moe.html).

3. 
    1. The user of the app - NO INCENTIVES. People are always saying “We need to get the community more involved! Let’s incentivise them to curate information for us, so we don’t have to do it”. No! That’s not the point of mechanism design as applied to cryptoeconomics. The point is to create systems that use mathematics and/or cryptography so that NO-ONE has undue influence over the system. It costs users to vote, so they would only do so to complain (if they feel really strongly), or donate to/protect an app that is being trolled. #EffectiveDirectCharity.

    2. The developer is incentivised by appearing higher in the Dapp store (which translates to more use, as it does now with AdWords or SEO etc.), and by being able to receive back some % of the SNT they staked if they do something awesome that the community likes, and wants to donate to. They can also withdraw their stake at any time, should they desire, so they are not locked in.

It’s worth re-iterating that I think this is a general system that could be used by any community/individual to curate information they are interested in (with the only requirement being that they have some fixed and fungible constant like TOTAL SNT to optimise against).

That is, though I have described it using the example of a DApp store above, this method of curating information does not have to be for developers/DApps only, though that’s a use case of particular interest to Status right now.