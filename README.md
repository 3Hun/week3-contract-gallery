# Week 3 Solidity Contract Gallery

Four Solidity contracts built and tested in Remix for the EVM Developer Programme. Each contract is deployed to Ethereum Sepolia, and its source code is verified on Etherscan with an **Exact Match**.

These contracts are educational exercises and have not been audited for production use. All ETH used during testing is Sepolia test ETH.

## Contracts

### SimpleStorage

SimpleStorage stores a `uint256` value that anyone can read through `getValue()`. Only the account that deployed the contract can change it. A successful change emits a `ValueChanged` event containing the old value, the new value, and the caller. Attempting to write from another account or set the value to its current value reverts.

- **Sepolia address:** `0x9662e2B7156F30C88a549899d30d79917E62E06e`
- **[Verified source on Etherscan](https://sepolia.etherscan.io/address/0x9662e2B7156F30C88a549899d30d79917E62E06e#code)**
- **[Solidity source](contracts/SimpleStorage.sol)**

### Faucet

Faucet holds test ETH and sends a fixed amount to an address when it calls `claim()`. Each address must wait 24 hours between successful claims, and the contract must have enough ETH to cover a claim. Anyone can fund it by sending ETH to the contract. The owner can withdraw the remaining balance.

- **Sepolia address:** `0x2Fd46d044F1bAE58b8c855A508Bf36b9FD3B89b3`
- **[Verified source on Etherscan](https://sepolia.etherscan.io/address/0x2Fd46d044F1bAE58b8c855A508Bf36b9FD3B89b3#code)**
- **[Solidity source](contracts/Faucet.sol)**

### Ballot

Ballot lets the owner register proposals and open voting for a fixed duration. Each address can cast one vote before the deadline. After voting ends, anyone can read the winning proposal. If multiple proposals have the highest vote count, the proposal with the lowest ID wins and the result reports that there was a tie.

- **Sepolia address:** `0xDD7FfA0618f55DDB5dAF1F7bd56Bfb5c156DbE96`
- **[Verified source on Etherscan](https://sepolia.etherscan.io/address/0xDD7FfA0618f55DDB5dAF1F7bd56Bfb5c156DbE96#code)**
- **[Solidity source](contracts/Ballot.sol)**

### Escrow

Escrow handles one purchase between a buyer and a seller, with an arbiter available for disputes. The buyer deploys the contract and deposits ETH; the seller can mark the item as shipped before the shipping deadline. Once marked shipped, the buyer can release payment to the seller. If the seller has not marked the item as shipped by the deadline, the buyer can reclaim the deposit. Either party can open a dispute while eligible, after which the arbiter decides whether the buyer receives a refund or the seller receives payment.

- **Sepolia address:** `0x35A59C9f0eA1952885A340499d42cb429Bff1bC4`
- **[Verified source on Etherscan](https://sepolia.etherscan.io/address/0x35A59C9f0eA1952885A340499d42cb429Bff1bC4#code)**
- **[Solidity source](contracts/Escrow.sol)**

## Compilation and verification

| Setting | Value |
| --- | --- |
| Network | Ethereum Sepolia |
| Solidity compiler | `v0.8.37+commit.f401782d` |
| Optimizer | Disabled |
| EVM version | Default compiler setting |
| Source verification | Etherscan Exact Match for all four contracts |

The contracts were compiled and deployed using Remix. `SimpleStorage` and `Ballot` have no constructor inputs. `Faucet` takes a fixed drip amount in wei. `Escrow` takes the seller address, arbiter address, and shipping window in seconds.

## Manual testing in Remix

The contracts were checked with multiple Remix VM accounts to exercise both successful calls and expected reverts:

| Contract | Checks |
| --- | --- |
| SimpleStorage | Read the initial value, update it as the owner, inspect the event, and confirm that an unauthorized write and an unchanged value revert. |
| Faucet | Fund the contract, make a claim, confirm that an immediate second claim from the same address reverts, claim from another address, and check owner-only withdrawal. |
| Ballot | Register proposals, start voting, cast votes from separate addresses, reject a duplicate vote, and read the result after the deadline, including the tie rule. |
| Escrow | Check the normal deposit → shipped → release path, the unshipped timeout → refund path, and dispute → arbiter resolution. Each terminal outcome requires a fresh Escrow deployment. |

The contract rules, roles, and additional manual checks are described in [DESIGN.md](DESIGN.md).

## Security and trust considerations

The two contracts designed to hold ETH are Faucet and Escrow. The following are ways their funds could be claimed or paid contrary to a participant's expectations:

1. **Faucet — multiple addresses:** The cooldown applies to an address, not a person. Someone controlling many addresses can claim once from each address and deplete the faucet more quickly than a single address could.
2. **Faucet — owner withdrawal:** The owner can withdraw the entire remaining balance at any time. This is an intentional permission in the code, so future claimants cannot rely on funds remaining available.
3. **Escrow — false shipping declaration:** `markShipped()` records the seller's declaration; it cannot prove that an item was delivered. Marking an item as shipped prevents the automatic timeout refund, leaving the buyer dependent on their own release decision or arbitration.
4. **Escrow — arbiter decision:** In a dispute, the arbiter can direct the full deposit to either the buyer or the seller. A dishonest or mistaken arbiter can therefore pay the party who should not receive it.

These are design limitations and trust assumptions, not claims that an unauthorized code exploit has been demonstrated. SimpleStorage and Ballot are not designed to custody ETH.

## Repository structure

```text
.
├── README.md
├── DESIGN.md
└── contracts
    ├── SimpleStorage.sol
    ├── Faucet.sol
    ├── Ballot.sol
    └── Escrow.sol
```
