# Reactive Debug Notes

Date: 2026-06-04

## What Was Tested

I added an isolated Reactive ping probe so YieldStream's hook accounting and epoch
logic are not involved in the Reactive diagnosis.

Destination chain:

- Base Sepolia, chain ID `84532`
- Callback proxy: `0xa6eA49Ed671B8a4dfCDd34E36b7a75Ac79B8A5a6`

Reactive chain:

- Lasna omni, chain ID `5318007`
- RPC used for the first run: `https://lasna-omni-rpc.rnk.dev/`
- Follow-up check: `https://lasna-rpc.rnk.dev/` exposes some legacy RNK debug
  methods, but it did not expose the `reactive-lib-omni` deployed contract/state
  at the same address. The omni endpoint is still the relevant endpoint for this
  code path.

## Contracts

| Contract | Address |
| --- | --- |
| `ReactivePingOrigin` on Base Sepolia | `0x241f001d78899ef00ccb0cc75bdcb19255bae1dd` |
| `ReactivePingReceiver` on Base Sepolia | `0x2262d4ec9e6c826403955fd0eea975e5118fff75` |
| `ReactivePingRSC` on Lasna | `0xb17df07998c9480e2a55fa38fab2a875d7c7be86` |

## Transactions

| Action | Tx hash | URL |
| --- | --- | --- |
| Deploy `ReactivePingOrigin` | `0x67e441af5a037c966daf3af4910daf8b61b35b9a58066885e7e8e64202234931` | `https://base-sepolia.blockscout.com/tx/0x67e441af5a037c966daf3af4910daf8b61b35b9a58066885e7e8e64202234931` |
| Deploy `ReactivePingReceiver` | `0xe471a37ea6e92e1beff9aa3d9b8bde1bb2e1c5ca0fbbaa4210bb772c7d3065b4` | `https://base-sepolia.blockscout.com/tx/0xe471a37ea6e92e1beff9aa3d9b8bde1bb2e1c5ca0fbbaa4210bb772c7d3065b4` |
| Deploy `ReactivePingRSC` with constructor subscription | `0xe58eb0d2228ab92b6df8dec560062ef4ce45f2a89b7e6bf95173e1b67e89f0aa` | `https://lasna-omni.reactscan.net/tx/0xe58eb0d2228ab92b6df8dec560062ef4ce45f2a89b7e6bf95173e1b67e89f0aa` |
| Emit origin `Ping` | `0x6f95f1b9ef9c09fcc893c949f170227801ea58dd5eb1dd5d255565b780e65efc` | `https://base-sepolia.blockscout.com/tx/0x6f95f1b9ef9c09fcc893c949f170227801ea58dd5eb1dd5d255565b780e65efc` |

## Verified Facts

- The Lasna deployment receipt emitted a system subscription event.
- The RSC's own `SubscriptionConfigured` event emitted.
- `subscriptionConfigured()` on the RSC returns `true`.
- The RSC has funding: about `0.985` lREACT after deployment.
- System `debt(address)` for the RSC returns `0`.
- Base Sepolia `Ping` emitted:
  - origin: `0x241f001d78899ef00ccb0cc75bdcb19255bae1dd`
  - topic0: `0x55c5abc0e08371271c19ba299c1e8ed0f7448d6335c7f1001d2eda714d9531fb`
  - nonce topic: `1`
  - sender topic: `0x4b992F2Fbf714C0fCBb23baC5130Ace48CaD00cd`
- `rnk_getFilters` returns an active filter for:
  - chain ID `84532`
  - contract `0x241f001d78899ef00ccb0cc75bdcb19255bae1dd`
  - topic0 `0x55c5abc0e08371271c19ba299c1e8ed0f7448d6335c7f1001d2eda714d9531fb`
  - reactive contract `0xb17df07998c9480e2a55fa38fab2a875d7c7be86`
  - `RvmId`: `0x0000000000000000000000000000000000000000`
  - `Active`: `true`

## Current Failure

No `PingObserved` event was found on Lasna within 240 seconds after the Base
Sepolia `Ping` event.

No `PingCallbackReceived` event was found on the Base Sepolia receiver because no
Lasna `react()` proof/callback was observed.

## Questions For Reactive Team

1. For `reactive-lib-omni`, is `RvmId: 0x0000000000000000000000000000000000000000`
   expected in `rnk_getFilters`, or does it indicate the RSC is not associated
   with a ReactVM?
2. The failed run used `https://lasna-omni-rpc.rnk.dev/`. A later check against
   `https://lasna-rpc.rnk.dev/` showed different execution/debug surfaces: the
   non-omni endpoint returned RVM mapping methods, but did not expose the same
   omni-deployed contract code/state. Please clarify which endpoint should be
   used for `reactive-lib-omni` contracts specifically.
3. Are public Lasna logs from `react()` expected to be visible through
   `eth_getLogs`, or should we use `rnk_getBlockSequences` / another method?
4. The current docs conflict on callback identity:
   - `events-and-callbacks.md` says the first callback arg is the reactive
     contract address.
   - `debugging.md` says it is the deployer/RVM ID.
   Which value should the destination contract authorize for
   `requestCallbackV_1_0` on Lasna omni?
