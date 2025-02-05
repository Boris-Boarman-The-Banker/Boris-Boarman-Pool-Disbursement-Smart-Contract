# Testnet E2E Testing Guide

## Environment Setup

1. Initialize a new environment on testnet:

```bash
sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
```

2. Switch to the new environment:

```bash
sui client switch --env testnet
```

3. Get test tokens from faucet

   > Note: Discord seems to be the most reliable source

4. Set up addresses:
   - Make sure you have two addresses: one for the proposal creator and one for the recipient

```bash
sui client addresses
sui client new-address ed25519
```

5. Check balance:

```bash
sui client gas
```

## Package Deployment

1. Publish the package on testnet:

```bash
sui client publish --gas-budget 1000000
```

2. After publishing, note down:
   - Package ID
   - FundingProposals shared object ID (created during init)

## Creating a Proposal

Create a proposal for 0.1 SUI (100000000 MIST):

```bash
sui client call \
    --package <PACKAGE_ID> \
    --module "FundRelease" \
    --function "create_proposal" \
    --args \
    <FUNDING_PROPOSALS_OBJECT_ID> \
    <RECIPIENT_ADDRESS> \
    100000000 \
    --gas-budget 1000000 \
    --json
```

## Releasing Funds

1. Prepare the coin object:
   - Make sure you have a coin object with exactly the approved amount
   - Get a coin object with more than 100000000 SUI:

```bash
sui client objects <PROPOSAL_CREATOR_ADDRESS>
```

2. Split the coin to get exact amount:

```bash
sui client pay-sui \
    --input-coins <COIN_OBJECT_ID> \
    --recipients <PROPOSAL_CREATOR_ADDRESS> \
    --amounts 100000000 \
    --gas-budget 1000000 \
    --json
```

3. Release the funds:

```bash
sui client call \
    --package <PACKAGE_ID> \
    --module "FundRelease" \
    --function "release_funds" \
    --args \
    <FUNDING_PROPOSALS_OBJECT_ID> \
    <PROPOSAL_ID> \
    <COIN_OBJECT_ID> \
    --gas-budget 1000000 \
    --json
```

## Verification

Check balance on recipient address:

```bash
sui client switch --address <RECIPIENT_ADDRESS>
sui client gas
```
