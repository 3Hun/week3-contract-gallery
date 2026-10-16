# Week 3 Solidity contracts

Four independent Solidity exercises for the EVM Developer Programme. See [DESIGN.md](DESIGN.md) for the actors, rules, tie and timeout choices, manual checks, and limits.

## Files

- `contracts/SimpleStorage.sol` — owner-controlled number and change event.
- `contracts/Faucet.sol` — fixed ETH drip per address once every 24 hours.
- `contracts/Ballot.sol` — proposal registration, one vote per address, timed result.
- `contracts/Escrow.sol` — single-deal ETH escrow with a shipping deadline and arbiter.

## Open in Remix

1. Open [Remix](https://remix.ethereum.org/), create a workspace, and add the four files in `contracts/` (or open them one at a time).
2. In Solidity Compiler select **0.8.37**. Compile each file. Keep the same compiler settings for deployment and Etherscan verification.
3. In Deploy & Run, select **Remix VM**. Try the cases in `DESIGN.md` using several different VM accounts. To test each Escrow ending, deploy a fresh instance.
4. For a public testnet deployment, connect a programme-only wallet to **Sepolia** and select the injected browser wallet provider in Remix. Use test ETH only.
5. After deployment, verify all four source files on Sepolia Etherscan. Use the identical compiler and settings and the original constructor inputs.

Suggested **example** deployment inputs:

- SimpleStorage: no inputs; deployer is owner.
- Faucet: `1000000000000000` wei, which is 0.001 ETH per claim.
- Ballot: no constructor inputs; use `addProposal` twice and then `startVoting(durationSeconds)`.
- Escrow: `seller` address, `arbiter` address, `shippingWindowSeconds`. Deployer is buyer. Example test duration: `120`; allow enough time for the non-timeout paths on separate deployments.

The source has no third-party imports. The Solidity compiler was unavailable in the environment where these files were prepared, so **compile all four files in Remix before deployment** and resolve any compiler diagnostics there. Compilation alone does not prove correctness or security. The gallery, Etherscan links, threat notes, and defence recording are still to be supplied after testing and deployment.
