# theStateOfUs

The beauty of Ethereum to me, can be summed up simply:

`By deploying immutable contracts to a shared, public computational surface - contracts whose data can be read deterministically by anyone with access to the internet - we can encode idealism into the way we run society.`

What's more, **what's different this time**, is that the idealism exists independently of the people who encoded it, who inevitably become corrupted in some way, because we are all human. And to be human is to be corruptible, in some very real and simple way. 

My idealism arises out of cryptoeconomics, which is not about egalitarianism, but about designing systems with no central point of control. Decentralisation is the goal, egalitarianism is a great success metric. But not the way around, because egalitarianism is not a purely mathematical function that can be optimised.

You can see the way I calculated the curve used [here](https://docs.google.com/spreadsheets/d/1WAxmOuBHN7R0StrIYV6L3UeJqaLRP3Cz_uSJEfowEo4/edit?usp=sharing) (Use the `copy_of_curve` sheet).

Watch the [tech talk here](https://youtu.be/82wMcgHSej0). 

# How It Works

DApps are ranked by whoever has staked the most, it is as simple as that. With one, small twist: the more you stake to get ranked highly, the easier it is for anyone to influence that position.

As a user, I go the DApp Store tab in Status and see the first page full of awesome DApps. I do not need SNT, I do not even need to know what SNT is, to do this.

Next to each DApp, I can see a `Staked SNT` amount, so I can tell exactly who has staked what to get that place in the rankings. I can also see a little upvote and downvote button, which I immediately recognise from sites like Reddit or Amazon etc. Clicking on these buttons costs me SNT, which I find surprising, but I am informed that, if I really wish to influence the position of the DApp, I need to pay a small cost - "put my money where my mouth is" in other words. I am also told that this cost goes directly back to the developer, which seems neat.  

Developer's already pay for SEO and AdWords, so paying to rank is not a new idea. However, in this system, how they rank is (a) totally transparent to the user, (b) can be influenced by that user if they feel strongly enough to pay a small cost and (c) whatever way a user votes, a good portion of the money that the developer initially staked to rank comes back to them.

They can also withdraw their stake and leave the store at any time they wish to.

1. Each downvote subtracts from the balance of the DApp in the rankings. Votes get progressively more expensive to mint, and only 62.5% of the SNT that the DApp staked to rank is available for voting. The cost to downvote is burnt, so that developer's are not directly incentivised to produce bad content that requires people to downvote it. 
2. Each upvote has one of 2 results, split up in the UI:
    1. I literally upvote, which has no effect on the balance of the DApp in the store, but makes it more expensive for others to downvote and acts as a "donation" to the developer.
    2. I stake some SNT to the DApp to "protect or promote" it (which is obviously much more expensive than just voting). Staking does effect the balance shown in the store.

And that's it. Developers know exactly what they need to stake to rank highly, users know exactly who has staked what to show up where they do AND they can choose to influence that position if they feel strongly enough to back that up with some value of their own. 

The SNT that it costs to downvote is burnt, so as not to create perverse incentives for developers to profit from putting up bad/malicious DApps, forcing the community to vote on them to move them down, and then withdrawing their stake.

The SNT it costs to upvote goes as a donation to the developer, so that they have further incentive (beyond just ranking highly) to participate in the DApp store ranking system.

## Can you give a maximally simple description of (1) who the participants are, (2) what actions the different categories of participants can take and (3) what the incentives are?

1. Participants are developers who want to see their DApp get ranked highly so people use it.

2. 
    1. Developers can stake SNT (really, this is a general solution that only requires some fixed, fungible limit against which to optimise, so it could be ANY fixed supply, fungible asset or thing that people value).
    2. Users can upvote or downvote their DApps, though I don’t see this happening too much, because it costs them and there is NO INCENTIVE for users, unless they’re feeling super motivated to make sure some DApp gets ranked less/more highly and are willing to pay to make that happen.
    3. Users simply benefit as a side-effect of the optimal curation of information, exactly like they do now.

The big difference here is that, instead of having limited insight into PageRank and what you are being shown on your search and why, you KNOW that the DApps that appear first are those who have paid the most.

People ask, “But, shouldn’t the DApps that appear the first be, the most useful or provide the most value to the community or something?” Yes, they absolutely should.

As we are all slowly figuring out though, the problem is with defining “value to the community”. Is that downloads, stars, usage metrics, customer feedback? All of these things are suboptimal and easy to manipulate.

The system I propose quite literally ranks the DApps that appear first by whichever ones provide most actual, *literal* value to the community, because a % of what is staked (defined by the curve I found, not by any human), stays staked as long as the DApp wishes to rank. This means there is less SNT in circulation, which means that the value of each individual SNT goes up and that the developers who do pay to get their DApp ranked highly are - again, quite literally - providing value to the community of users and getting ranked appropriately on it. I believe it’s similar to what Vitalik wrote about [here](http://vitalik.ca/general/2017/10/17/moe.html).

3. 
    1. The user of the app - NO INCENTIVES, this is the sociological factor that makes it all work. People are always saying “We need to get the community more involved! Let’s incentivise them to curate information FOR us, so we don’t have to do it”. No! That’s not the point of mechanism design as applied to cryptoeconomics. The point is to create systems that use mathematics and/or cryptography so that NO-ONE has undue influence over the system. It costs users to vote, so they would only do so to complain (if they feel really strongly), or donate to/protect an app that is being trolled. #EffectiveDirectCharity.

    2. The developer is incentivised by appearing higher in the Dapp store (which translates to more use, as it does now with AdWords or SEO etc.), and by being able to receive back some % of the SNT they staked if they do something awesome that the community likes, and wants to donate to. They can also withdraw their stake at any time, should they desire, so they are not locked in.

It’s worth re-iterating that I think this is a general system that could be used by any community/individual to curate information they are interested in (with the only requirement being that they have some fixed and fungible constant like TOTAL SNT to optimise against).

That is, though I have described it using the example of a DApp store above, this method of curating information does not have to be for developers/DApps only, though that’s a use case of particular interest to Status right now.