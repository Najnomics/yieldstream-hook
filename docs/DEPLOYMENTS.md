# Deployments

Updated: June 5, 2026

## Deployment Key

- Deployer / owner / RVM ID: `0x4b992F2Fbf714C0fCBb23baC5130Ace48CaD00cd`
- CREATE2 deployer used for hook mining: `0x4e59b44847b379578588920cA78FbF26c0B4956C`
- Lasna RPC: `https://lasna-rpc.rnk.dev/`
- Lasna chain ID: `5318007`
- Lasna currency: `lREACT`
- Reactive system contract: `0x0000000000000000000000000000000000fffFfF`
- Reactive library: `Reactive-Network/reactive-lib`
- Demo epoch length: `20` blocks
- Reactive callback gas limit: `1,500,000`

The hook authorizes Reactive callbacks with:

```text
msg.sender == callbackProxy && sender == reactiveSender
```

Reactive Network injects the first callback argument as the ReactVM ID, so `reactiveSender` is set to the deployer/RVM ID above.

## Base Sepolia Demo

Destination chain ID: `84532`

| Contract | Address |
|----------|---------|
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Callback proxy | `0xa6eA49Ed671B8a4dfCDd34E36b7a75Ac79B8A5a6` |
| YieldStreamTokenFactory | `0xF6E0AC636cDb1dacfE68D758CAa880b5A09f0a98` |
| MorphoAdapter | `0xDa24f7eaB509aad5EdE5aa6c762CefAbcdfF0f47` |
| YieldStreamHook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| YieldStreamRSC on Lasna | `0xD4342b1B631a5a465E09b81d1b99E6438c61d453` |
| Morpho Blue | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` |

Transactions:

| Action | Tx hash | URL |
|--------|---------|-----|
| Deploy token factory | `0xc824e7b23a8b54d39646b903b624aeb556b0da6a880d9ea0c4510c19f4c0366a` | https://base-sepolia.blockscout.com/tx/0xc824e7b23a8b54d39646b903b624aeb556b0da6a880d9ea0c4510c19f4c0366a |
| Deploy adapter | `0x0296d499cf4c83649e3d875efd139a49b29282e4400a24612baa37aec906c6a5` | https://base-sepolia.blockscout.com/tx/0x0296d499cf4c83649e3d875efd139a49b29282e4400a24612baa37aec906c6a5 |
| Deploy hook | `0x3c2f2adfbb9fc2bb7d95c9f7dddddb7c1b7c346377d798aa86f9659ab7883f8e` | https://base-sepolia.blockscout.com/tx/0x3c2f2adfbb9fc2bb7d95c9f7dddddb7c1b7c346377d798aa86f9659ab7883f8e |
| Set adapter hook | `0x4ced4ba24e6acddc0c2724dac8ba5e7bf2467dc91047d7f361a56d398e3f87d7` | https://base-sepolia.blockscout.com/tx/0x4ced4ba24e6acddc0c2724dac8ba5e7bf2467dc91047d7f361a56d398e3f87d7 |
| Set reactive sender | `0x6a337583598e9b4a3bc6d14e160a91e788e617383489885b8722bc704c76a22a` | https://base-sepolia.blockscout.com/tx/0x6a337583598e9b4a3bc6d14e160a91e788e617383489885b8722bc704c76a22a |
| Remove old Lasna subscription | `0x44c5ffa5e15d563e62f988fdfe996d385412610fc3ffda2c9dbdf2b2a74b5d0a` | https://lasna.reactscan.net/tx/0x44c5ffa5e15d563e62f988fdfe996d385412610fc3ffda2c9dbdf2b2a74b5d0a |
| Remove wrong-payload Lasna subscription | `0xbab697db95740a915b275e209f3a43fa6f1ea25733706738d7c8d8e10a94b0a5` | https://lasna.reactscan.net/tx/0xbab697db95740a915b275e209f3a43fa6f1ea25733706738d7c8d8e10a94b0a5 |
| Deploy Lasna RSC | `0xea30b8b2a89eb51a2dc4800664c0ab73cdbfd80fbbc2016e0498058730393725` | https://lasna.reactscan.net/tx/0xea30b8b2a89eb51a2dc4800664c0ab73cdbfd80fbbc2016e0498058730393725 |
| Configure Lasna subscription | `0x96bbdbbf7cccca3a7f5d4a8cb039ae508f4e511a7a8be768ed6eacc0ccb97405` | https://lasna.reactscan.net/tx/0x96bbdbbf7cccca3a7f5d4a8cb039ae508f4e511a7a8be768ed6eacc0ccb97405 |

Readback verified:

- Hook `epochLength()` returns `20`.
- Hook `callbackProxy()` returns the Base Sepolia callback proxy.
- Hook `reactiveSender()` returns the RVM ID.
- Hook `tokenFactory()` returns the deployed token factory.
- Adapter `hook()` returns the deployed hook.
- RSC `DESTINATION_CHAIN_ID()` returns `84532`.
- RSC `HOOK_ADDRESS()` returns the deployed hook.
- RSC `CALLBACK_GAS_LIMIT()` returns `1,500,000`.
- RSC `EPOCH_LENGTH()` returns `20`.
- RSC `subscriptionConfigured()` returns `true`.
- Explicit `configureSubscription()` emitted the Reactive system subscription log and RSC `SubscriptionConfigured`.

## Unichain Sepolia Demo

Destination chain ID: `1301`

| Contract | Address |
|----------|---------|
| PoolManager | `0x00B036B58a818B1BC34d502D3fE730Db729e62AC` |
| Callback proxy | `0x9299472A6399Fd1027ebF067571Eb3e3D7837FC4` |
| YieldStreamTokenFactory | `0x97bf008af093831Aa3CCde2565c2de89d52643a5` |
| MorphoAdapter | `0xf15CE9D5855CDFFeF4a9F9AbdC013Dc07cb3F0cD` |
| YieldStreamHook | `0x4C7734FfB1C9F054E1b16f1BBdcD9aEa98E80640` |
| YieldStreamRSC on Lasna | `0xf9C557b4097f399dBa99EB1DB2caf5fc7ADfE786` |
| Morpho Blue | `0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb` |

Transactions:

| Action | Tx hash | URL |
|--------|---------|-----|
| Deploy token factory | `0xc28a1d5673bb55fbfbc9e885ad40c0f3c4de51d0a4917defdaab8e1e21276d67` | https://unichain-sepolia.blockscout.com/tx/0xc28a1d5673bb55fbfbc9e885ad40c0f3c4de51d0a4917defdaab8e1e21276d67 |
| Deploy adapter | `0xefa0a651b753c1a872a7de26e61c4c9a99915c45e87e4586b9178dbce93a8ed5` | https://unichain-sepolia.blockscout.com/tx/0xefa0a651b753c1a872a7de26e61c4c9a99915c45e87e4586b9178dbce93a8ed5 |
| Deploy hook | `0x496b53ae7862ccb67bfceed2303f930a0cddf1b79b0dd13141c0f9b8f8316261` | https://unichain-sepolia.blockscout.com/tx/0x496b53ae7862ccb67bfceed2303f930a0cddf1b79b0dd13141c0f9b8f8316261 |
| Set adapter hook | `0x892b0ec62c70114148e27a9f53238d17e24b57f0376f58457c90455b91d9cff6` | https://unichain-sepolia.blockscout.com/tx/0x892b0ec62c70114148e27a9f53238d17e24b57f0376f58457c90455b91d9cff6 |
| Set reactive sender | `0x1ceef68a88abfdc38d051a3ba78770070ca3d0b3ddcd4b3c951735cf06d548c7` | https://unichain-sepolia.blockscout.com/tx/0x1ceef68a88abfdc38d051a3ba78770070ca3d0b3ddcd4b3c951735cf06d548c7 |
| Remove old Lasna subscription | `0x2350226a003116e8b1c5737d5998f2ae1e95530facded277949d015c6acb047b` | https://lasna.reactscan.net/tx/0x2350226a003116e8b1c5737d5998f2ae1e95530facded277949d015c6acb047b |
| Remove wrong-payload Lasna subscription | `0x52396030e0ab865a10dd97336fb7bc18c0e1adddd82938d279e5a5c94af3c7d4` | https://lasna.reactscan.net/tx/0x52396030e0ab865a10dd97336fb7bc18c0e1adddd82938d279e5a5c94af3c7d4 |
| Deploy Lasna RSC | `0xcc18660955a35417e02a693d37e6a95540abf2271e650442f8902b967a0b8f27` | https://lasna.reactscan.net/tx/0xcc18660955a35417e02a693d37e6a95540abf2271e650442f8902b967a0b8f27 |
| Configure Lasna subscription | `0x434685da655bcbdc5b2e8b19a545f9fb37726bbeb2201cb5cb4e85a63b3a416b` | https://lasna.reactscan.net/tx/0x434685da655bcbdc5b2e8b19a545f9fb37726bbeb2201cb5cb4e85a63b3a416b |

Readback verified:

- Hook `epochLength()` returns `20`.
- Hook `callbackProxy()` returns the Unichain Sepolia callback proxy.
- Hook `reactiveSender()` returns the RVM ID.
- Hook `tokenFactory()` returns the deployed token factory.
- Adapter `hook()` returns the deployed hook.
- RSC `DESTINATION_CHAIN_ID()` returns `1301`.
- RSC `HOOK_ADDRESS()` returns the deployed hook.
- RSC `CALLBACK_GAS_LIMIT()` returns `1,500,000`.
- RSC `EPOCH_LENGTH()` returns `20`.
- RSC `subscriptionConfigured()` returns `true`.
- Explicit `configureSubscription()` emitted the Reactive system subscription log and RSC `SubscriptionConfigured`.

## Operational Notes

- The current deployable hook uses a separate `YieldStreamTokenFactory` to keep the hook below the EIP-170 runtime size limit.
- `MorphoAdapter` remains deployed and independently tested, but Morpho routing is not in the live hook settlement path for this demo build.
- The deployable hook uses token factory extraction and currently has a `YieldStreamHook` runtime size of `18,866` bytes.
- Lasna RSC deployment uses the legacy Reactive endpoint/library. For the patched demo RSCs, the old filters were removed first, then the RSCs were deployed with constructor subscription disabled and explicitly configured on Lasna with `configureSubscription()`.
- The patched RSC queues settlement for the epoch carried by the post-boundary `FeesAccrued` event. This keeps demo callbacks deterministic after idle gaps and avoids stale missed-epoch callback queues.
- Legacy Reactive callbacks do not rewrite the callback payload. `YieldStreamRSC` therefore encodes the RVM ID/deployer address as the first `settleEpochFromReactive(address,uint256)` argument.

## Latest Testnet E2E Proofs

### Base Sepolia E2E

Epoch: `2122859`

| Step | Tx hash | URL |
|------|---------|-----|
| Hook-managed liquidity deposit | `0x69c8fb75c48bdf08488bf5d87d0b81df9989586652de92e3c8c592e99ef02fbd` | https://base-sepolia.blockscout.com/tx/0x69c8fb75c48bdf08488bf5d87d0b81df9989586652de92e3c8c592e99ef02fbd |
| FeesAccrued event 1 | `0x2fdd7fb41fd787f6b2a97612a0e64d37929ca1189c7464004a515a672298316a` | https://base-sepolia.blockscout.com/tx/0x2fdd7fb41fd787f6b2a97612a0e64d37929ca1189c7464004a515a672298316a |
| Lasna RVM observed event 1 | `0xea60015f0c65c364f88a9075b32b728b6b632a2e18334617f8af03a185a6c637` | https://lasna.reactscan.net/tx/0xea60015f0c65c364f88a9075b32b728b6b632a2e18334617f8af03a185a6c637 |
| FeesAccrued boundary event | `0xaf0f052341722586a4114b40ab034e596db948916a2139bb0321eff432cd6b51` | https://base-sepolia.blockscout.com/tx/0xaf0f052341722586a4114b40ab034e596db948916a2139bb0321eff432cd6b51 |
| Lasna RVM queued callback | `0x87a7ace4028833c752a319d79f3676fd360d54fae436a013f04a8f55b0f9ff52` | https://lasna.reactscan.net/tx/0x87a7ace4028833c752a319d79f3676fd360d54fae436a013f04a8f55b0f9ff52 |
| Reactive destination callback / EpochSettled | `0x0444c396d5b1f47b49bc8cd350affb6fecb38de199fa587ed97b8b121bae5541` | https://base-sepolia.blockscout.com/tx/0x0444c396d5b1f47b49bc8cd350affb6fecb38de199fa587ed97b8b121bae5541 |

Epoch tokens:

| Token | Address |
|-------|---------|
| FYT | `0xF0514a0f7820AD92A2ba08a58bF6D7CaAA8971EA` |
| PT | `0xE14929B80D5Ade6e8b63BC51fbaC6112E5993410` |

### Unichain Sepolia E2E

Epoch: `2691520`

| Step | Tx hash | URL |
|------|---------|-----|
| Hook-managed liquidity deposit | `0xa2247bdb86acbd764d504033a8783fe7877a28cb857749d07a584d126f46e886` | https://unichain-sepolia.blockscout.com/tx/0xa2247bdb86acbd764d504033a8783fe7877a28cb857749d07a584d126f46e886 |
| FeesAccrued event 1 | `0x20686899687ae1014513aed573c4ae92e21fa39e57e906145642eafcf1a9a55f` | https://unichain-sepolia.blockscout.com/tx/0x20686899687ae1014513aed573c4ae92e21fa39e57e906145642eafcf1a9a55f |
| Lasna RVM observed event 1 | `0xd53475e95c4658874a0eafa7159bc6175c66ac2dff6ed9d4c160d9d0395f4387` | https://lasna.reactscan.net/tx/0xd53475e95c4658874a0eafa7159bc6175c66ac2dff6ed9d4c160d9d0395f4387 |
| FeesAccrued boundary event | `0x792e873841ffacc1d4ad99a1ff25c528ec2ca5a87f430c41afc1620aa23546b4` | https://unichain-sepolia.blockscout.com/tx/0x792e873841ffacc1d4ad99a1ff25c528ec2ca5a87f430c41afc1620aa23546b4 |
| Lasna RVM queued callback | `0x87c79b9f2dac613a8ceff9ec5d2a48fce55bb71ca4c90eef0fe23abe6d5eea79` | https://lasna.reactscan.net/tx/0x87c79b9f2dac613a8ceff9ec5d2a48fce55bb71ca4c90eef0fe23abe6d5eea79 |
| Reactive destination callback / EpochSettled | `0x6b8a3f668ae2c0d8e6f5d106443f829933c3c7314671fd7182d9b29686623fbc` | https://unichain-sepolia.blockscout.com/tx/0x6b8a3f668ae2c0d8e6f5d106443f829933c3c7314671fd7182d9b29686623fbc |

Epoch tokens:

| Token | Address |
|-------|---------|
| FYT | `0x380D359015Df909ee939918513c307EEF12DE183` |
| PT | `0xD3E5afC202Ed9469d01d79278Ce910A58E11d16D` |
