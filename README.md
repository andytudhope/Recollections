# Recollections

The beauty of Ethereum to me, can be summed up simply:

`By deploying immutable contracts to a shared, public computational surface - contracts whose data can be read deterministically by anyone with access to the internet - we can encode idealism into the way we run society.`

What's more, **what's different this time**, is that the idealism exists independently of the people who encoded it, who inevitably become corrupted, because we are all human. And to be human is to be corruptible, in some very real and simple way. 

My idealism arises out of cryptoeconomics, which is not about egalitarianism, but about designing systems with no central point of control. Decentralisation is the goal, egalitarianism is a great success metric. But not the other way around, because egalitarianism is not something for which we can reasonably optimise.

1. Watch the [tech talk for a high-level overview here](https://youtu.be/82wMcgHSej0) (now a bit outdated). 

2. Play with a [live ObservableHQ notebook here](https://beta.observablehq.com/@andytudhope/dapp-store-snt-curation-mechanism).

3. Read the [contract in this repo](./DAppStore.sol).

4. Look at the [evolving designs](https://www.figma.com/file/MYWmd1buvc2AMvUmFP9w42t5/Discovery?node-id=35%3A420).


# DApp Store SNT Ranking

## Summary

In order to fulfill one of our whitepaper promises, we need a mechanism in the Status DApp Store that uses SNT to curate DApps. While this is not the only mechanism we will make available to users to find interesting and relevant DApps, it is one of the most important, both for SNT utility and because economic mechanisms are at the heart of how we buidl sustainable peer-to-peer networks.

## Abstract

We propose using an exponential [bonded curve](https://beta.observablehq.com/@andytudhope/dapp-store-snt-curation-mechanism), which operates only on downvotes, to implement a simple ranking game. It is the most radical market feasible: the more SNT a DApp stakes, the higher it ranks, with one caveat. The more SNT staked, the cheaper it is for the community to move that DApp down the rankings.

## Motivation

Token Curated Registries, and other bonded curve implementations try to incentivise the user with some kind of fungible reward token (often with governance rights/requirements attached to it) in order to decentralise the curation of interesting information. However, this creates mental overhead for users (who must manage multiple tokens, all with different on-chain transactions required) and is unlikely to see high adoption.

Making the ranking algorithm transparent - and giving users an ability to affect it at a small cost to them should they feel very strongly - is potentially a more effective way to achieve decentralised curation.

## User Stories

An effective economic ranking mechanism, selected with the option `Ranked by SNT` (one of many filters), answers the following user stories from our [swarm doc](https://github.com/status-im/swarms/blob/master/ideas/317-dapps-store.md).

1. **I want to be confident a DApp is usable / not a scam.**
    1. Having an economic mechanism ensures that the DApps which rank highly quite literally are those providing the "most value" to the community. This is because SNT staked to rank is locked out of circulation, meaning each SNT stakeholder's own holding of SNT should increase in value. Coincidentally, the more SNT staked in total in the store, the stronger the assurance that any given DApp which ranks highly is useful and not a scam.
2. **As an SNT stakeholder, I would like to signal using SNT that I find a listing useful.**
    1. Achieved by "upvoting" in the UI. Importantly, upvotes do not effect the bonded curve, users simply donate SNT 1-1 directly to the DApp's `balance`.
3. **As an SNT stakeholder, I would like to signal using SNT that I find a listing to be not useful/poor quality/etc.**
    1. Achieved, on an increasingly cheap basis the more well-resourced a DApp is, by "downvoting" in the UI. Uses an exponential bonded curve to mint downvotes.
4. **As a DApp developer, I want to be able to propose/vote my DApp for inclusion.**
    1. Anybody can submit a DApp for inclusion and "vote" on it by calling `upvote` and adding SNT to its `balance`.

## UI Mock-ups

Designs being worked on [here](https://www.figma.com/file/MYWmd1buvc2AMvUmFP9w42t5/Discovery?node-id=35%3A420)

1. The "free complain" feature in the Downvote screen is not included for now. 
2. The "Add a DApp" screen (ideally, imo, opened from a fab `+` button on the home screen) is not included either.

## Specification

#### Constructor
Instantiates the MiniMe (or EIP20) interface so that the contract can receive and send tokens as necessary.

#### Constants
1. `uint total == 3470483788` - total SNT in circulation.
2. `uint ceiling` - most influential parameter for [_shape_ of curves](https://beta.observablehq.com/@andytudhope/dapp-store-snt-curation-mechanism) (votes minted per DApp and cost to effect a DApp by some set percent for users). Potentially controlled dynamically by governance mechanism.
3. `uint max = total * (ceiling/100)` - max SNT that any one DApp can stake.

#### Data Struct
1. `address developer` - the developer of the DApp, used to send SNT to when `downvote` or `withdraw` is called. 
2. `bytes32 id` - a unique identifier for each DApp, potentially with other metadata associated with it, hence the `bytes32`.
1. `uint balance` - keep track of the total staked on each DApp.
2. `uint rate = 1 - (balance/max)` - used to calculate `available` and `v_minted`.
3. `uint available = balance * rate` - amount of SNT staked a developer can earn back. NB: this is equivalent the `cost` of all downvotes.
4. `uint v_minted = available ** (1/rate)` - total downvotes that are "minted".
5. `uint v_cast` - keep track of the downvotes already cast.
6. `uint e_balance = balance - ((v_cast/(1/rate))*(available/v_minted))`- the Effective Balance each DApp is actually ranked by in the UI.

#### Methods

1. **createData** 
    1. params: `(bytes32 _id, uint _amount)`
 
Accepts some nominal amount of tokens (> 0) and creates a new Data struct with the `_id` passed to it, setting the new struct's `balance` and using that to calculate `balance`, `rate`, `available`, `v_minted_` and `e_balance` (which is == `balance` at first).

Emit event containing new `e_balance`.

2. **upvoteEffect**
    1.  params: `(bytes32 _id, uint _amount)`

Mock add `_amount` to `balance`, calculate `mRate`, `mAvailable`, `mVMinted`, and `mEBalance`. Subtract this from the actual `e_balance` and return the difference to be displayed in the UI when a user is choosing how much to "donate" when upvoting.
 
3. **upvote**
    1.  params:`(bytes32 _id, uint _amount)`

Transfer SNT directly to the contract, which means donating directly to the DApp's `balance`, no curve used, no money to the developer. Then recalculate `rate`, `available`, `v_minted` and `e_balance`. 

Emit event containing new `e_balance`.

3. **downvoteCost**
    1. params: `(bytes32 _id, uint _percent_down)` 

Specifying the `_percent_down` allows us to calculate the `cost` without integrating anything. Calculate the `v_required` to effect the DApp by the specified % and the return `cost` for use in the UI.

NOTE: it's likely best to poll this method fairly often from Status and store the approx `cost` locally for a quicker, smoother UI and then double check that it's correct before the user confirms the transaction.

4. **downvote**
    1. params: `(bytes32 _id, uint _percent_down, uint _amount)` 

Send SNT from user directly to developer in order to downvote. Call `downvoteCost` and check that the vote is still valid, i.e. `_amount >= cost`. We actually send `cost` to the developer, not `_amount` which covers the `>` case, but need to throw an error if the state has changed and `amount < cost`.

Add `v_required` to `v_cast`, recalculate `e_balance`, and subtract `cost` from `available` so that `withdraw` works correctly. 

Emit event containing new `e_balance`.

5. **withdraw**
    1. params: `(bytes32 _id, uint _amount)` 

Allow developers to reduce thier stake/exit the store provided that `_amount <= available`. Recalculate `balance`, `rate`, `available` and `v_minted`. If `v_cast > v_minted`, then set them equal so the maths is future-proof, and recalculate `e_balance`. 

Emit event containing new `e_balance`.

6. **??? updateCeiling**
    1. params: `(uint _newCeiling)`

Potentially a simple multisig governance mechanism to change the ceiling dynamically in response to demand?

#### Notes

What metadata we need to identify each DApp uniquely is still a topic for research and discussion. Ideally, we want these contracts to be used for curation _in general_, not necessarily just for DApps, so it needs to be as general as possible. For now, only an `id` in `Data` is included.

## Potential Attacks

1. **Sybil resistance?**
    1. If I create a lot of accounts for one DApp, will that increase it's ranking?
    2. If I vote for one DApp from lots of different accounts, in small amounts, rather than in 1 big amount from a single account, what effect does it have?

Creating many accounts for one DApp is not possible - each DApp is uniquely identified and by its `id` and ranked only by the amount of SNT staked on it. In the same way, there is no quadratic effect in this set up, so staking for a DApp from lots of different accounts in small amounts has no greater/lesser effect on its ranking than staking 1 large amount from a single account.

2. **Incentives to stake bad DApps and "force" the community to spend SNT to downvote?**

Remember, you never get back more SNT than you stake, so this is also economically sub-optimal. In addition, there will be a free "complaint" feature as part of the "downvote" screen. There is an important difference between "contractual" and "social" (i.e. the Status UI) reality. Status reserves the right to remove from our UI any DApp that actively violates [our principles](https://status.im/contribute/our_principles.html), though anyone else is free to fork the software and implement different social/UI rules for the same contractual reality. This protects even further against any incentive to submit bad/damaging DApps.

However, at the beginning of the Store, this is an attack vector: ranking highly requires but a small stake, and this could conceivably result in a successful, cheap hype campaign. The "complain" feature is meant as social protection against this (though it depends on the responsiveness of the Status team, which is not optimal).

3. **Stake a damaging DApp, force some downvotes, and then withdraw my stake?**

You can still never earn back quite as much as you initially staked, enforced by the condition in the `withdraw` function: `require(_amount <= available)`.

4. **What is left in the store when a DApp withdraws the SNT it staked?**

Simply `balance - available`, i.e. some small amount of SNT not available to be withdrawn.

5. **The majority of the cost to downvote comes from the last ~5%, so moving a DApp down 80%, say, is not that expensive relative to the effect you have.**

Yeah, we need to play with the curve more to try and mitigate this.

6. **I'm worried about the behaviour of [the graph](https://beta.observablehq.com/@andytudhope/dapp-store-snt-curation-mechanism) for higher `v_cast` - things get very expensive.**

This is a result of how the data and sliders are structured. If you mock a high `v_cast`, then the graph, trying to show the effect of that on DApps with lower balances naturally spikes for `balance < v_cast`, which I have tried to exclude as best as possible.

## Rationale

This is a simple economic mechanism that

1. does not place high mental overheads on users and could conceivably be understood by a wider and non-technical audience and 
2. does not require a lot of screen real estate (important on mobile). All that is required is a balance for each DApp and up/downvote carrots to it's right or left, a pattern already well understood on sites like Reddit etc.

Moreover, having SNT is not required to see (and benefit from) a well-curated list of DApps; only if you want to effect the rankings on that list do you require tokens, which also makes the UX considerably easier for non-technical users.

From the perspective of DApp Developers - they must still spend some capital to rank well, just as they currently do with SEO and AdWords etc.,  but _they stand to earn most of that back_ if the community votes on their product/service, and they can withdraw their stake at any time. The algorithm is entirely transparent and they know where they stand and why at all times.

## Copyright
Copyright and related rights for this specification waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).


