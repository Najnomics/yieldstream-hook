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
