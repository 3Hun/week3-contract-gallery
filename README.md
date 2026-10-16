# Week 3 Solidity Contract Gallery

Four contracts built and tested in Remix, deployed to Ethereum Sepolia, and source-verified on Etherscan with an **Exact Match**. These are educational contracts using test ETH.

## Contracts

### SimpleStorage

Stores a number that anyone can read. Only the deployer can change it, and each change emits an event.

[Verified on Etherscan](https://sepolia.etherscan.io/address/0x9662e2B7156F30C88a549899d30d79917E62E06e#code) · [Source code](contracts/SimpleStorage.sol)

### Faucet

Holds test ETH and pays a fixed amount per claim. Each address must wait 24 hours between claims; the owner can withdraw the remaining balance.

[Verified on Etherscan](https://sepolia.etherscan.io/address/0x2Fd46d044F1bAE58b8c855A508Bf36b9FD3B89b3#code) · [Source code](contracts/Faucet.sol)

### Ballot

Lets the owner register proposals and set a voting deadline. Each address can vote once. If the highest vote count is tied, the proposal with the lowest ID wins and the result reports the tie.

[Verified on Etherscan](https://sepolia.etherscan.io/address/0xDD7FfA0618f55DDB5dAF1F7bd56Bfb5c156DbE96#code) · [Source code](contracts/Ballot.sol)

### Escrow

Holds one buyer's deposit. The seller can mark the item as shipped, after which the buyer can release payment. If it remains unshipped past the deadline, the buyer can reclaim the deposit. An arbiter decides who receives the funds in a dispute.

[Verified on Etherscan](https://sepolia.etherscan.io/address/0x35A59C9f0eA1952885A340499d42cb429Bff1bC4#code) · [Source code](contracts/Escrow.sol)

## Testing

Manual Remix checks covered access restrictions, repeated Faucet claims, duplicate Ballot votes, and Escrow's release, timeout refund, and dispute resolution paths. Each Escrow ending was checked with a fresh deployment. See [DESIGN.md](DESIGN.md) for the rules and test steps.

The contracts were compiled with Solidity `0.8.37`, optimization disabled, and the default EVM version.

## ETH custody risks

- **Faucet:** A person can use multiple addresses to claim repeatedly because the cooldown is per address.
- **Faucet:** The owner can withdraw all remaining funds, leaving nothing for later claimants.
- **Escrow:** A seller can mark an item as shipped without proving delivery, blocking the automatic timeout refund.
- **Escrow:** The arbiter can award the deposit to either party and could make a dishonest decision.

SimpleStorage and Ballot are not designed to hold ETH. The Faucet owner's withdrawal and the arbiter's decision are intentional permissions and trust assumptions, not demonstrated code exploits.
