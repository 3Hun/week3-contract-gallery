# Week 3 contract design

This document fixes the rules for the four Solidity exercises before deployment. All ETH in this project must be Sepolia test ETH. The contracts are exercises, not audited production contracts.

Compiler: Solidity **0.8.37** (exact version in each source file). Keep Remix compiler settings unchanged between compilation, deployment, and source verification. No third-party imports.

## 1. SimpleStorage

**Roles and state:** The deployer is `owner`; `storedValue` starts at zero.

| Action | Caller | Allowed when | Result |
| --- | --- | --- | --- |
| `getValue()` | Anyone | Always | Returns stored number without a transaction. |
| `setValue(newValue)` | Owner | New value differs | Saves value and emits `ValueChanged(oldValue, newValue, owner)`. |

All other writers revert. Repeating the same value reverts and does not emit an event. This contract has no payable entry point and is not designed to hold ETH.

**Remix checks:** initial value is 0; owner can set 42; event contains 0 and 42; a different account cannot set; setting 42 again reverts.

## 2. Faucet

**Roles and state:** The deployer is `owner`. Deployment supplies one nonzero `dripAmountWei`, which is fixed forever. Anyone may send ETH to `receive()` to fund the faucet. `nextClaimAt[address]` starts at zero.

| Action | Caller | Allowed when | Result |
| --- | --- | --- | --- |
| Fund faucet | Anyone | Always | Receives ETH and emits `Funded`. |
| `claim()` | Any address | At or after its `nextClaimAt`, with at least one drip in the contract | Records next eligible time as `block.timestamp + 1 days`, then sends exactly one drip with `call` and emits `Claimed`. |
| `withdrawRemainder()` | Owner | Faucet has a positive balance | Sends the entire remaining ETH balance to owner with `call`. |

Failed ETH transfers revert the whole transaction, including the cooldown update. A user may claim again after 24 hours if the faucet still has sufficient funds. There is no per-human identity check: someone with many addresses can claim from each address. The owner can deliberately empty the faucet at any time; users have no guaranteed future claim.

**Remix checks:** zero drip deployment fails; fund then claim succeeds; an immediate second claim from the same address fails; another address can claim; unfunded claim fails; nonowner withdrawal fails; owner withdrawal empties the faucet. The successful second claim after 24 hours needs a time-controlled test environment (in Week 4) or a real 24-hour wait; do not shorten the rule in the submitted contract.

## 3. Ballot

**Roles and state:** The deployer is `owner`. Only owner can add proposals, at most 20, before starting a vote. Proposals get IDs 0, 1, ... in registration order. The owner starts voting once with a positive `durationSeconds` and at least two proposals. The deadline is fixed at `block.timestamp + durationSeconds`.

| Action | Caller | Allowed when | Result |
| --- | --- | --- | --- |
| `addProposal(name)` | Owner | Before vote starts; nonempty name; fewer than 20 proposals | Registers proposal and emits `ProposalAdded`. |
| `startVoting(durationSeconds)` | Owner | Before vote starts; at least two proposals; positive duration | Opens vote and emits `VotingStarted(deadline)`. |
| `vote(proposalId)` | Any address | Voting is open; valid ID; address has not voted | Adds one vote, marks address as used, emits `VoteCast`. |
| `winningProposal()` | Anyone | At or after deadline | Returns winning ID, name, count, and `tied`. |

**Tie rule:** The smallest proposal ID among those with the highest vote count wins. `tied` is true when multiple proposals have that count. If nobody votes, proposal 0 wins by this rule and `tied` is true because there are at least two proposals. This is one-address-one-vote, not one-person-one-vote. Proposal names and deadline cannot change after voting starts.

**Remix checks:** only owner can register/start; starting with fewer than two proposals fails; voting before start, twice from one address, with an invalid ID, or at/after deadline fails; winner cannot be read before deadline; tie chooses smallest ID. Start a short-lived separate instance to show the deadline and result.

## 4. Escrow

**Roles and state:** The buyer deploys the contract. Constructor supplies a distinct nonzero `seller`, a distinct nonzero `arbiter`, and a positive `shippingWindowSeconds`. One deployment covers exactly one purchase. Seller and arbiter addresses cannot be changed.

| Starting state | Action | Ending state |
| --- | --- | --- |
| AwaitingDeposit | Buyer deposits | Funded |
| Funded | Seller marks shipped before deadline | Shipped |
| Funded | Buyer reclaims after deadline | Refunded |
| Shipped | Buyer releases | Complete |
| Funded (before deadline) or Shipped | Buyer or seller opens dispute | Disputed |
| Disputed | Arbiter rules for buyer / seller | Refunded / Complete |

`deadline` starts when the buyer deposits and is the **seller's shipping deadline**. The buyer can reclaim only if the seller has not marked the item shipped by then. A late seller cannot open a dispute to block that refund. Once marked shipped, there is no automatic refund or seller payout: the buyer releases payment or either party requests arbitration. This makes the timeout path and dispute path separate and avoids permitting a buyer to reclaim automatically after an on-time shipment.

| Action | Caller | Allowed when | Result |
| --- | --- | --- | --- |
| `deposit()` with ETH | Buyer | AwaitingDeposit; nonzero amount | Records amount and deadline, enters Funded. |
| `markShipped()` | Seller | Funded; before deadline | Enters Shipped. |
| `release()` | Buyer | Shipped | Enters Complete and pays seller. |
| `claimRefund()` | Buyer | Funded; deadline reached | Enters Refunded and returns deposit. |
| `openDispute()` | Buyer or seller | Funded before deadline, or Shipped | Enters Disputed, freezing direct release/refund. |
| `resolveDispute(paySeller)` | Arbiter | Disputed | Pays seller if `true`, buyer if `false`; enters terminal state. |

Payouts use `call`, with state and amount changed before the external call. A failed payout reverts the state change. A recipient contract that refuses ETH can block its payout. Arbitration depends on the arbiter's judgment and availability; if the arbiter does not act after a dispute, funds remain locked. A seller's `markShipped()` is only a declaration, not proof of delivery. Direct unsolicited transfers have no normal payable entry point; forced ETH could remain outside the recorded deposit.

**Remix checks:** deploy with three distinct accounts; a zero deposit and deposit from another account fail; seller cannot mark shipped after deadline; buyer can reclaim if still Funded after deadline; a fresh instance can follow Funded -> Shipped -> Complete; separate instances can follow dispute -> buyer refund and dispute -> seller payout. The buyer cannot reclaim after Shipped, and a non-arbiter cannot resolve a dispute. A fresh instance is needed for each terminal path.

## Later Week 3 steps

After the local Remix checks, deploy each contract to Sepolia, verify its source on Sepolia Etherscan, publish a gallery with four verified links, and write two plausible ways each ETH-holding contract could lose funds. Record a short weekly defence in your own words. These later steps are not completed by the source files alone.
