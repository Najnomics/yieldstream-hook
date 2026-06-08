# Demo

Fast dry-run:

```bash
forge script script/DemoYieldStream.s.sol -vvv
```

Broadcast demo with transaction ids:

```bash
bash script/demo-with-txids.sh
```

The broadcast runner starts a local Anvil node if one is not already available at
`RPC_URL`, executes the YieldStream lifecycle as real transactions, and prints
the transaction id for every visible demo step. It uses a demo harness settlement
method so judges do not need to wait for 50,400 blocks.

Demo sequence:

1. Deploy demo token0/token1.
2. Deploy local YieldStream hook harness.
3. Alice deposits simulated liquidity.
4. Hook mints FYT and PT.
5. Alice transfers FYT to Bob.
6. The hook accrues simulated swap fees.
7. Epoch 0 settles through the demo harness.
8. Bob redeems FYT for fees.
9. Alice redeems PT for principal.

Frontend:

```bash
cd frontend
npm run dev -- --port 5173
```

Open `http://127.0.0.1:5173/`.

## Live Testnet Demo

The judge-facing testnet runner proves the deployed system on Base Sepolia or
Unichain Sepolia with Reactive settlement on Lasna:

```bash
YIELDSTREAM_E2E_NETWORK=base bash script/testnet-demo-with-txids.sh
YIELDSTREAM_E2E_NETWORK=unichain bash script/testnet-demo-with-txids.sh
```

The script prints each phase, every destination transaction id, every explorer
URL, the Lasna subscription proof, ReactVM observation txs, and the destination
`EpochSettled` callback tx when the callback lands.

Live workflow from a user and proof perspective:

1. Infrastructure proof: load `.env`, verify the deployed hook/RSC addresses,
   read the Lasna subscription, and confirm the RNK filter for
   `FeesAccrued(uint256,uint256,uint256)`.
2. LP onboarding: mint demo tokens to the LP/demo sender, approve the deployed
   hook, deposit hook-managed Uniswap v4 liquidity, and print the minted FYT/PT
   addresses and balances.
3. Yield stream creation: report backed demo fees into the hook and emit the
   subscribed `FeesAccrued` event.
4. Reactive observation: poll Lasna until the ReactVM transaction referencing
   the destination `FeesAccrued` tx is visible.
5. Epoch boundary: wait for the short demo epoch to advance, then emit a
   post-boundary `FeesAccrued` event for the original epoch.
6. Autonomous settlement: show the Lasna RVM transaction that queues the
   callback, then poll the destination chain for `EpochSettled`.
7. User outcome: print FYT/PT settlement state, accrued fees, balances, and
   append the full ledger to `docs/e2e.md`.

The live demo uses `epochLength = 20` blocks so judges can see the Reactive
callback during one session. The production default remains `50,400` blocks.
