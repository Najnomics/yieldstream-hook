# YieldStream Testnet E2E Runs

This file is generated and extended by `script/testnet-demo-with-txids.sh`.

## 2026-06-05 - Base Sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x1C2A9aBe3d3a4FBaD2FA0c795c311E670CE792C6` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| Lasna RSC deploy | [`0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a`](https://lasna.reactscan.net/tx/0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a) |
| Lasna subscription | [`0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626`](https://lasna.reactscan.net/tx/0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Pool setup | Deploy reusable demo token0. Future script runs reuse this token. | `0x82ec1ee49bfd55a874c52798e8eafe337973cb98f0b2e22bb1348b9cd9c77b75` | https://base-sepolia.blockscout.com/tx/0x82ec1ee49bfd55a874c52798e8eafe337973cb98f0b2e22bb1348b9cd9c77b75 |
| Pool setup | Deploy reusable demo token1. Future script runs reuse this token. | `0x4eef4c4981f9e0002c6fc1f8c11f10ae3cc81b815d5cf38098fafd4e577c9124` | https://base-sepolia.blockscout.com/tx/0x4eef4c4981f9e0002c6fc1f8c11f10ae3cc81b815d5cf38098fafd4e577c9124 |
| Pool setup | Initialize the reusable Uniswap v4 pool. | `0x4be782d4b2e08143ccd3f972a8a05abbc12f585d5778c95166b7e00e3ef3afff` | https://base-sepolia.blockscout.com/tx/0x4be782d4b2e08143ccd3f972a8a05abbc12f585d5778c95166b7e00e3ef3afff |
| LP deposit | Deposit hook-managed liquidity and mint epoch PT/FYT. | `0xea770de40fca6f0013a4d4072dd976edf23aec7ed2028c104ab69be0a2823931` | https://base-sepolia.blockscout.com/tx/0xea770de40fca6f0013a4d4072dd976edf23aec7ed2028c104ab69be0a2823931 |
| Swap | Execute a v4 swap against the YieldStream pool. | `0x7e4ea3a2f1e2fd802a32774dd1d86f371c51ba7c94a680f1b4c88b33f68c8f2a` | https://base-sepolia.blockscout.com/tx/0x7e4ea3a2f1e2fd802a32774dd1d86f371c51ba7c94a680f1b4c88b33f68c8f2a |
| FeesAccrued | Emit the first fee event for Lasna observation. | `0xd48f80ea147266a765049bda8ec01cb76e48da08be302dc2b7394f6437741ecb` | https://base-sepolia.blockscout.com/tx/0xd48f80ea147266a765049bda8ec01cb76e48da08be302dc2b7394f6437741ecb |
| FeesAccrued | Emit the post-boundary fee event against the original epoch. | `0x2333eeb12a779d9867b522e278f705fde868affec738a9781c3d66e1691f5193` | https://base-sepolia.blockscout.com/tx/0x2333eeb12a779d9867b522e278f705fde868affec738a9781c3d66e1691f5193 |
| Reactive callback | Reactive Network submitted settlement; hook emitted `EpochSettled`. | `0xd2e7b1ab96caa1ebdc47abe557ff29fbb44a91919945b02528e4e58d651d3ed2` | https://base-sepolia.blockscout.com/tx/0xd2e7b1ab96caa1ebdc47abe557ff29fbb44a91919945b02528e4e58d651d3ed2 |

### Result

| Item | Value |
|------|-------|
| Epoch | `2122477` |
| FYT | `0x9bE473a26AF6B7609b183Df69F79Dc1c0fDBCd69` |
| PT | `0x9E25474044d4F12cEdecbbcdD9A04a503F91B783` |
| Fees0 | `4000000000000000` |
| Fees1 | `6000000000000000` |
| FYT settled | `true` |
| PT redeemable | `true` |

## 2026-06-05 - Unichain Sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `unichain-sepolia (1301)` |
| Hook | `0x4C7734FfB1C9F054E1b16f1BBdcD9aEa98E80640` |
| Lasna RSC | `0x49d0C37CFbEFc27994e784BA542E4F1f6A1a892A` |
| Demo token0 | `0x2b60F617B914d2b77fA7F39a50147ec703777045` |
| Demo token1 | `0xfC876fa12cA7266554B6DA07E9eE542B35a2fB10` |
| Lasna RSC deploy | [`0x91c82166c529d79f7543ffb8fc65faa9681f0cdd231ff58ce0d52e41111b5cfd`](https://lasna.reactscan.net/tx/0x91c82166c529d79f7543ffb8fc65faa9681f0cdd231ff58ce0d52e41111b5cfd) |
| Lasna subscription | [`0x8f73d1d3f29d9ed172e5ac189bef633e9771eab60e7a23fc4852774cb2c51d69`](https://lasna.reactscan.net/tx/0x8f73d1d3f29d9ed172e5ac189bef633e9771eab60e7a23fc4852774cb2c51d69) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Pool setup | Deploy reusable demo token0. Future script runs reuse this token. | `0x9ccd0e1639159149dca6c1c2fd3e562a7fde34cbe8e654f2462f629cb19fa939` | https://unichain-sepolia.blockscout.com/tx/0x9ccd0e1639159149dca6c1c2fd3e562a7fde34cbe8e654f2462f629cb19fa939 |
| Pool setup | Deploy reusable demo token1. Future script runs reuse this token. | `0x14384a19ac22c411c4d05989bb293aa2faae85b30859a24d4a6435e6f7026e7d` | https://unichain-sepolia.blockscout.com/tx/0x14384a19ac22c411c4d05989bb293aa2faae85b30859a24d4a6435e6f7026e7d |
| Pool setup | Initialize the reusable Uniswap v4 pool. | `0xa3d1fe45ecf28551f733269d2da80f3fad998309157d0b7e4156dfbab56d5d3c` | https://unichain-sepolia.blockscout.com/tx/0xa3d1fe45ecf28551f733269d2da80f3fad998309157d0b7e4156dfbab56d5d3c |
| LP deposit | Deposit hook-managed liquidity and mint epoch PT/FYT. | `0xa29851d13d46c084347faa5a2e9c7fa389d87b963c21a1ffebe3ac3de2f62b42` | https://unichain-sepolia.blockscout.com/tx/0xa29851d13d46c084347faa5a2e9c7fa389d87b963c21a1ffebe3ac3de2f62b42 |
| Swap | Execute a v4 swap against the YieldStream pool. | `0x96072025232f8fe056bcc49482c1831751185831a958e6f5db5796f78bde4fe4` | https://unichain-sepolia.blockscout.com/tx/0x96072025232f8fe056bcc49482c1831751185831a958e6f5db5796f78bde4fe4 |
| FeesAccrued | Emit the first fee event for Lasna observation. | `0x3735c8fd02bad1c7070812b7089762178aa6d78f9664b1a57c89b1027d3324d1` | https://unichain-sepolia.blockscout.com/tx/0x3735c8fd02bad1c7070812b7089762178aa6d78f9664b1a57c89b1027d3324d1 |
| FeesAccrued | Emit the post-boundary fee event against the original epoch. | `0x1415818108c2ef06cd3efd85b37006f0416b36fbad26b6023e3d74c40bd2dc62` | https://unichain-sepolia.blockscout.com/tx/0x1415818108c2ef06cd3efd85b37006f0416b36fbad26b6023e3d74c40bd2dc62 |
| Reactive callback | Reactive Network submitted settlement; hook emitted `EpochSettled`. | `0xe8ad288a766b2f4aa77e203118dec220d1e16776757362d4d6faada5a4e61d20` | https://unichain-sepolia.blockscout.com/tx/0xe8ad288a766b2f4aa77e203118dec220d1e16776757362d4d6faada5a4e61d20 |

### Result

| Item | Value |
|------|-------|
| Epoch | `2690773` |
| FYT | `0x764A81904ab7EE07b895aEa19dC87AC02C40c2bE` |
| PT | `0xC8B37c3b88E5E7F986ddA456bd3D471Be2597324` |
| Fees0 | `4000000000000000` |
| Fees1 | `6000000000000000` |
| FYT settled | `true` |
| PT redeemable | `true` |

## 2026-06-05 16:30:46 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x1C2A9aBe3d3a4FBaD2FA0c795c311E670CE792C6` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a](https://lasna.reactscan.net/tx/0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a) |
| Lasna subscription | [0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626](https://lasna.reactscan.net/tx/0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0xc7c2c74119930d183bc9f575882a678cdfc34b9cf2d8528794d2987db51e578c` | https://base-sepolia.blockscout.com/tx/0xc7c2c74119930d183bc9f575882a678cdfc34b9cf2d8528794d2987db51e578c |

## 2026-06-05 16:31:00 UTC - unichain-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `unichain-sepolia (1301)` |
| Hook | `0x4C7734FfB1C9F054E1b16f1BBdcD9aEa98E80640` |
| Lasna RSC | `0x49d0C37CFbEFc27994e784BA542E4F1f6A1a892A` |
| Demo token0 | `0x2b60F617B914d2b77fA7F39a50147ec703777045` |
| Demo token1 | `0xfC876fa12cA7266554B6DA07E9eE542B35a2fB10` |
| PoolManager | `0x00B036B58a818B1BC34d502D3fE730Db729e62AC` |
| Swap router | `0x9140A78c1a137c7Ff1c151eC8231272AF78A99A4` |
| Lasna RSC deploy | [0x91c82166c529d79f7543ffb8fc65faa9681f0cdd231ff58ce0d52e41111b5cfd](https://lasna.reactscan.net/tx/0x91c82166c529d79f7543ffb8fc65faa9681f0cdd231ff58ce0d52e41111b5cfd) |
| Lasna subscription | [0x8f73d1d3f29d9ed172e5ac189bef633e9771eab60e7a23fc4852774cb2c51d69](https://lasna.reactscan.net/tx/0x8f73d1d3f29d9ed172e5ac189bef633e9771eab60e7a23fc4852774cb2c51d69) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0x77f1794a42bf934ac833fab434dea9f545643e52c5947ff895ba0db262a42cdd` | https://unichain-sepolia.blockscout.com/tx/0x77f1794a42bf934ac833fab434dea9f545643e52c5947ff895ba0db262a42cdd |

## 2026-06-05 16:31:31 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x1C2A9aBe3d3a4FBaD2FA0c795c311E670CE792C6` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a](https://lasna.reactscan.net/tx/0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a) |
| Lasna subscription | [0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626](https://lasna.reactscan.net/tx/0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0xb7a0a90b7329258ad4f67988565a916e4cce90077cd7ffff209479df7e53bf14` | https://base-sepolia.blockscout.com/tx/0xb7a0a90b7329258ad4f67988565a916e4cce90077cd7ffff209479df7e53bf14 |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0x12c419ae9a9a887d94fd6be0eea69688507d4f8366ec3a2e45197ade8182ae1f` | https://base-sepolia.blockscout.com/tx/0x12c419ae9a9a887d94fd6be0eea69688507d4f8366ec3a2e45197ade8182ae1f |
| Approval | Approve the deployed YieldStream hook to pull 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0x9960e08eff6f6f3c94fa1729f57e0f7fdc88fe1124cfc3f6e9f101ca99c800aa` | https://base-sepolia.blockscout.com/tx/0x9960e08eff6f6f3c94fa1729f57e0f7fdc88fe1124cfc3f6e9f101ca99c800aa |
| Approval | Approve the deployed v4 swap test router to use 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0xf3fc748adad4d91e9a79b48ec2855fb81bdcbac9f89b2c2c7bd29bf7c6f48fbc` | https://base-sepolia.blockscout.com/tx/0xf3fc748adad4d91e9a79b48ec2855fb81bdcbac9f89b2c2c7bd29bf7c6f48fbc |
| Approval | Approve the deployed YieldStream hook to pull 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0xa8f2a2e3813fd471199982b472ec0fcdcb230f5e3bd1dcd86f79bc08c8651a5b` | https://base-sepolia.blockscout.com/tx/0xa8f2a2e3813fd471199982b472ec0fcdcb230f5e3bd1dcd86f79bc08c8651a5b |
| Approval | Approve the deployed v4 swap test router to use 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0x4a2ac7270238e163b3e5525b383a39edca1160c4d861bdfa2986b7213180d218` | https://base-sepolia.blockscout.com/tx/0x4a2ac7270238e163b3e5525b383a39edca1160c4d861bdfa2986b7213180d218 |
| LP deposit | Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch. | `0x73372b0cbf9d97903d1fae3be28196eea015c6701499aad9b4af7d8317dbd136` | https://base-sepolia.blockscout.com/tx/0x73372b0cbf9d97903d1fae3be28196eea015c6701499aad9b4af7d8317dbd136 |

## 2026-06-05 16:32:17 UTC - unichain-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `unichain-sepolia (1301)` |
| Hook | `0x4C7734FfB1C9F054E1b16f1BBdcD9aEa98E80640` |
| Lasna RSC | `0x49d0C37CFbEFc27994e784BA542E4F1f6A1a892A` |
| Demo token0 | `0x2b60F617B914d2b77fA7F39a50147ec703777045` |
| Demo token1 | `0xfC876fa12cA7266554B6DA07E9eE542B35a2fB10` |
| PoolManager | `0x00B036B58a818B1BC34d502D3fE730Db729e62AC` |
| Swap router | `0x9140A78c1a137c7Ff1c151eC8231272AF78A99A4` |
| Lasna RSC deploy | [0x91c82166c529d79f7543ffb8fc65faa9681f0cdd231ff58ce0d52e41111b5cfd](https://lasna.reactscan.net/tx/0x91c82166c529d79f7543ffb8fc65faa9681f0cdd231ff58ce0d52e41111b5cfd) |
| Lasna subscription | [0x8f73d1d3f29d9ed172e5ac189bef633e9771eab60e7a23fc4852774cb2c51d69](https://lasna.reactscan.net/tx/0x8f73d1d3f29d9ed172e5ac189bef633e9771eab60e7a23fc4852774cb2c51d69) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0x3f8111293975153308e65b3447ec0df4fd0a9605eee8270ef73449dca115471c` | https://unichain-sepolia.blockscout.com/tx/0x3f8111293975153308e65b3447ec0df4fd0a9605eee8270ef73449dca115471c |

## 2026-06-05 16:32:44 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x1C2A9aBe3d3a4FBaD2FA0c795c311E670CE792C6` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a](https://lasna.reactscan.net/tx/0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a) |
| Lasna subscription | [0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626](https://lasna.reactscan.net/tx/0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0x125dcb2a45b4582d5e48cd73d1bc60f4af926bfea83b7039b2e0a6e27db053cc` | https://base-sepolia.blockscout.com/tx/0x125dcb2a45b4582d5e48cd73d1bc60f4af926bfea83b7039b2e0a6e27db053cc |

## 2026-06-05 16:34:45 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x1C2A9aBe3d3a4FBaD2FA0c795c311E670CE792C6` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a](https://lasna.reactscan.net/tx/0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a) |
| Lasna subscription | [0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626](https://lasna.reactscan.net/tx/0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0x644a1c6f539ae569f912d230f93ab553e4620888ca07e10463983ef08706e4e1` | https://base-sepolia.blockscout.com/tx/0x644a1c6f539ae569f912d230f93ab553e4620888ca07e10463983ef08706e4e1 |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0x8c5019aff7563bff7c05cdcca1cae28107be1929601f66a49f0188d515a421b4` | https://base-sepolia.blockscout.com/tx/0x8c5019aff7563bff7c05cdcca1cae28107be1929601f66a49f0188d515a421b4 |
| Approval | Approve the deployed YieldStream hook to pull 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0x272d5652ac21a3a536a8a5de9df7fbe9cdf3f28dc21f094f3bba9d14eb719250` | https://base-sepolia.blockscout.com/tx/0x272d5652ac21a3a536a8a5de9df7fbe9cdf3f28dc21f094f3bba9d14eb719250 |
| Approval | Approve the deployed v4 swap test router to use 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0xb850c2dee420e0decac7277b12da493774b764398cc9ad148515fcbf995f5f62` | https://base-sepolia.blockscout.com/tx/0xb850c2dee420e0decac7277b12da493774b764398cc9ad148515fcbf995f5f62 |
| Approval | Approve the deployed YieldStream hook to pull 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0xbedd49b04b44c9dc13a1b84a21c67e6cb508a202db54e97d1799e79dd27e8f84` | https://base-sepolia.blockscout.com/tx/0xbedd49b04b44c9dc13a1b84a21c67e6cb508a202db54e97d1799e79dd27e8f84 |
| Approval | Approve the deployed v4 swap test router to use 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0xc5772702a42cad8b6137f22123db5991437f6c3d8e5799418b868e1d1040005d` | https://base-sepolia.blockscout.com/tx/0xc5772702a42cad8b6137f22123db5991437f6c3d8e5799418b868e1d1040005d |
| LP deposit | Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch. | `0xee647c240e0c3a615d6e3e4ded02e916dde4a875dc12e1f9c878571c0776ac72` | https://base-sepolia.blockscout.com/tx/0xee647c240e0c3a615d6e3e4ded02e916dde4a875dc12e1f9c878571c0776ac72 |

## 2026-06-05 16:36:02 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x1C2A9aBe3d3a4FBaD2FA0c795c311E670CE792C6` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a](https://lasna.reactscan.net/tx/0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a) |
| Lasna subscription | [0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626](https://lasna.reactscan.net/tx/0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0x3983f64bfdfacccd758e936480e1bfc2e430d685488daa3ce565e9aac42f541b` | https://base-sepolia.blockscout.com/tx/0x3983f64bfdfacccd758e936480e1bfc2e430d685488daa3ce565e9aac42f541b |

## 2026-06-05 16:36:16 UTC - unichain-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `unichain-sepolia (1301)` |
| Hook | `0x4C7734FfB1C9F054E1b16f1BBdcD9aEa98E80640` |
| Lasna RSC | `0x49d0C37CFbEFc27994e784BA542E4F1f6A1a892A` |
| Demo token0 | `0x2b60F617B914d2b77fA7F39a50147ec703777045` |
| Demo token1 | `0xfC876fa12cA7266554B6DA07E9eE542B35a2fB10` |
| PoolManager | `0x00B036B58a818B1BC34d502D3fE730Db729e62AC` |
| Swap router | `0x9140A78c1a137c7Ff1c151eC8231272AF78A99A4` |
| Lasna RSC deploy | [0x91c82166c529d79f7543ffb8fc65faa9681f0cdd231ff58ce0d52e41111b5cfd](https://lasna.reactscan.net/tx/0x91c82166c529d79f7543ffb8fc65faa9681f0cdd231ff58ce0d52e41111b5cfd) |
| Lasna subscription | [0x8f73d1d3f29d9ed172e5ac189bef633e9771eab60e7a23fc4852774cb2c51d69](https://lasna.reactscan.net/tx/0x8f73d1d3f29d9ed172e5ac189bef633e9771eab60e7a23fc4852774cb2c51d69) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0x4b69ffeca9bf6c53a4626695035816c052f310f1c73a15fd2ae7f10285fe5380` | https://unichain-sepolia.blockscout.com/tx/0x4b69ffeca9bf6c53a4626695035816c052f310f1c73a15fd2ae7f10285fe5380 |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0xacd2ff082f1876a5cca1bb169dd4b7dbb579ea766ac33a6b8c48f4e2430a63a0` | https://unichain-sepolia.blockscout.com/tx/0xacd2ff082f1876a5cca1bb169dd4b7dbb579ea766ac33a6b8c48f4e2430a63a0 |
| Approval | Approve the deployed YieldStream hook to pull 0x2b60F617B914d2b77fA7F39a50147ec703777045. | `0xfe513bc164ff461fd77e50f8ea62eae0c4fb7d37ac0bdf6f6faf1ef35bc9d27c` | https://unichain-sepolia.blockscout.com/tx/0xfe513bc164ff461fd77e50f8ea62eae0c4fb7d37ac0bdf6f6faf1ef35bc9d27c |
| Approval | Approve the deployed v4 swap test router to use 0x2b60F617B914d2b77fA7F39a50147ec703777045. | `0x2a1c56ec2c594bb9e64642b98c511b96777d1165bc32a464de0bc348248373e9` | https://unichain-sepolia.blockscout.com/tx/0x2a1c56ec2c594bb9e64642b98c511b96777d1165bc32a464de0bc348248373e9 |
| Approval | Approve the deployed YieldStream hook to pull 0xfC876fa12cA7266554B6DA07E9eE542B35a2fB10. | `0x6ef0c29f70e517461c06f46905f653a2598ed4bc89498d1b07b721eebb27a91b` | https://unichain-sepolia.blockscout.com/tx/0x6ef0c29f70e517461c06f46905f653a2598ed4bc89498d1b07b721eebb27a91b |
| Approval | Approve the deployed v4 swap test router to use 0xfC876fa12cA7266554B6DA07E9eE542B35a2fB10. | `0xf41d83ab2c722be784b7f5fabe7dfda981a34fbff7224dd96b4707893bbc7ff8` | https://unichain-sepolia.blockscout.com/tx/0xf41d83ab2c722be784b7f5fabe7dfda981a34fbff7224dd96b4707893bbc7ff8 |

## 2026-06-05 16:37:32 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x1C2A9aBe3d3a4FBaD2FA0c795c311E670CE792C6` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a](https://lasna.reactscan.net/tx/0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a) |
| Lasna subscription | [0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626](https://lasna.reactscan.net/tx/0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0x3a51e1f128f45924ab83c624c7e90e97356e4d3f6465ceb53229a7c2d1372b1a` | https://base-sepolia.blockscout.com/tx/0x3a51e1f128f45924ab83c624c7e90e97356e4d3f6465ceb53229a7c2d1372b1a |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0xae63c630776e1d6fa987d43ef1753a0b17eb43e68f2310daecdb279d66a58231` | https://base-sepolia.blockscout.com/tx/0xae63c630776e1d6fa987d43ef1753a0b17eb43e68f2310daecdb279d66a58231 |
| Approval | Approve the deployed YieldStream hook to pull 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0xa135777c4612f10a029405a76ca13c6c02d00bbccd2c86d22530c989c03efc48` | https://base-sepolia.blockscout.com/tx/0xa135777c4612f10a029405a76ca13c6c02d00bbccd2c86d22530c989c03efc48 |
| Approval | Approve the deployed v4 swap test router to use 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0xe0661c54d6302de4667effa3e0c2fb24a91c898d1b099b07576d6254e8fa5d75` | https://base-sepolia.blockscout.com/tx/0xe0661c54d6302de4667effa3e0c2fb24a91c898d1b099b07576d6254e8fa5d75 |
| Approval | Approve the deployed YieldStream hook to pull 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0x6ce6dc6058da16bdb930031992ce83a4ce9ecfcb5839664c5bbfb684c5d2b8d1` | https://base-sepolia.blockscout.com/tx/0x6ce6dc6058da16bdb930031992ce83a4ce9ecfcb5839664c5bbfb684c5d2b8d1 |
| Approval | Approve the deployed v4 swap test router to use 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0x10502f1a819a8241a6c6cbf6e3af896881b4ed122ec8bf4fbcc4df5db7e41696` | https://base-sepolia.blockscout.com/tx/0x10502f1a819a8241a6c6cbf6e3af896881b4ed122ec8bf4fbcc4df5db7e41696 |
| LP deposit | Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch. | `0xb429907c8d49b5c168df5529c9dca2b98b44a112f599a370ba2a14a2490ed45f` | https://base-sepolia.blockscout.com/tx/0xb429907c8d49b5c168df5529c9dca2b98b44a112f599a370ba2a14a2490ed45f |

## 2026-06-05 16:40:26 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x1C2A9aBe3d3a4FBaD2FA0c795c311E670CE792C6` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a](https://lasna.reactscan.net/tx/0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a) |
| Lasna subscription | [0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626](https://lasna.reactscan.net/tx/0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0x838962c4e9052c66354b993a189d07207235aa5398ff893458808d1e02319092` | https://base-sepolia.blockscout.com/tx/0x838962c4e9052c66354b993a189d07207235aa5398ff893458808d1e02319092 |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0x702149f8ca35dc24ae53a921c4aa468031efb735fa93005e7884b41dc81b93fa` | https://base-sepolia.blockscout.com/tx/0x702149f8ca35dc24ae53a921c4aa468031efb735fa93005e7884b41dc81b93fa |
| Approval | Approve the deployed YieldStream hook to pull 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0xc7a926fa6d7b3e2732924355119077dfc6101d34f07b826ff42342e87ee2f631` | https://base-sepolia.blockscout.com/tx/0xc7a926fa6d7b3e2732924355119077dfc6101d34f07b826ff42342e87ee2f631 |
| Approval | Approve the deployed v4 swap test router to use 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0x4df5957474bf4783873178891c41e95fb82f221bd378b6a964ee0e5a353af1a2` | https://base-sepolia.blockscout.com/tx/0x4df5957474bf4783873178891c41e95fb82f221bd378b6a964ee0e5a353af1a2 |
| Approval | Approve the deployed YieldStream hook to pull 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0xf8aea3395084f8b445dc6b90944fdc61836f71830fad389dd2c8004774f91d3f` | https://base-sepolia.blockscout.com/tx/0xf8aea3395084f8b445dc6b90944fdc61836f71830fad389dd2c8004774f91d3f |
| Approval | Approve the deployed v4 swap test router to use 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0x7d6522148b1e637749ec8366dc0517e5017b891c7115a2cf117e9325e014691f` | https://base-sepolia.blockscout.com/tx/0x7d6522148b1e637749ec8366dc0517e5017b891c7115a2cf117e9325e014691f |
| LP deposit | Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch. | `0x596332c0a1d3eab58a08bdba14dc2490f7aa39e29a2938908d2afc50a04389b7` | https://base-sepolia.blockscout.com/tx/0x596332c0a1d3eab58a08bdba14dc2490f7aa39e29a2938908d2afc50a04389b7 |

## 2026-06-05 16:41:39 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x1C2A9aBe3d3a4FBaD2FA0c795c311E670CE792C6` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a](https://lasna.reactscan.net/tx/0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a) |
| Lasna subscription | [0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626](https://lasna.reactscan.net/tx/0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0x520fd65b3e4cb0276c8d38fdf38a02c17baca255f16cf2f377749ff17bfa83d0` | https://base-sepolia.blockscout.com/tx/0x520fd65b3e4cb0276c8d38fdf38a02c17baca255f16cf2f377749ff17bfa83d0 |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0x879fa7a4e65b3e0b3dc8a5628093d21babc4827ee0fdd0f880a89e8e1a0c5308` | https://base-sepolia.blockscout.com/tx/0x879fa7a4e65b3e0b3dc8a5628093d21babc4827ee0fdd0f880a89e8e1a0c5308 |
| Approval | Approve the deployed YieldStream hook to pull 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0x48fae23a812f8881c7b628523cf3285233f2f581dd31dabef5bfbf6c8c5a085c` | https://base-sepolia.blockscout.com/tx/0x48fae23a812f8881c7b628523cf3285233f2f581dd31dabef5bfbf6c8c5a085c |
| Approval | Approve the deployed v4 swap test router to use 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0xa36440be6119c1038c3aeef5856e37df273ab4bfe0b88db9dc57426f59f346ce` | https://base-sepolia.blockscout.com/tx/0xa36440be6119c1038c3aeef5856e37df273ab4bfe0b88db9dc57426f59f346ce |

## 2026-06-05 16:42:29 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x1C2A9aBe3d3a4FBaD2FA0c795c311E670CE792C6` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a](https://lasna.reactscan.net/tx/0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a) |
| Lasna subscription | [0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626](https://lasna.reactscan.net/tx/0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0x8f733dab2c22ce5fdebaf820b9376139daf986a2126f7142a66aaeec083a3b95` | https://base-sepolia.blockscout.com/tx/0x8f733dab2c22ce5fdebaf820b9376139daf986a2126f7142a66aaeec083a3b95 |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0x1820a9806049eaed87c050992053835a645fa1ac844338b45b18203aab3b2c9b` | https://base-sepolia.blockscout.com/tx/0x1820a9806049eaed87c050992053835a645fa1ac844338b45b18203aab3b2c9b |
| Approval | Approve the deployed YieldStream hook to pull 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0x5aa376e0af596996ad38d21b14cfc2cdb46131c9018512d463ffa0f3e119302a` | https://base-sepolia.blockscout.com/tx/0x5aa376e0af596996ad38d21b14cfc2cdb46131c9018512d463ffa0f3e119302a |
| Approval | Approve the deployed v4 swap test router to use 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0x27b2aafcafca0f32bd9239796a97c944295d1c4cbf18d3baf8fcc50a31ecc75d` | https://base-sepolia.blockscout.com/tx/0x27b2aafcafca0f32bd9239796a97c944295d1c4cbf18d3baf8fcc50a31ecc75d |
| Approval | Approve the deployed YieldStream hook to pull 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0xd0a240ad9d99ba0fa3ba41a51876df276afe0758167cc90789f95af6bc41d04b` | https://base-sepolia.blockscout.com/tx/0xd0a240ad9d99ba0fa3ba41a51876df276afe0758167cc90789f95af6bc41d04b |
| Approval | Approve the deployed v4 swap test router to use 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0xb88307acef47a6789858cb8a17b9f26c7917b31ee69cd183ee8cb56f022a6741` | https://base-sepolia.blockscout.com/tx/0xb88307acef47a6789858cb8a17b9f26c7917b31ee69cd183ee8cb56f022a6741 |
| LP deposit | Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch. | `0x33be7f944f5a081158e0e49793fb364319fbecd85fab6b91295dcee4d267674e` | https://base-sepolia.blockscout.com/tx/0x33be7f944f5a081158e0e49793fb364319fbecd85fab6b91295dcee4d267674e |
| Swap | Execute a v4 swap against the reusable demo pool during the active epoch. | `0x85392bbf72dca659649538e60488f330c3859dda3fe57e1f042e8cecd294716d` | https://base-sepolia.blockscout.com/tx/0x85392bbf72dca659649538e60488f330c3859dda3fe57e1f042e8cecd294716d |
| FeesAccrued | Report active-epoch fees and emit the first FeesAccrued event observed by Lasna. | `0xb8e2e86f0ad1a35937c714cfbfeac948a8cb3a78bae1ddfbeca72de6f2fcac86` | https://base-sepolia.blockscout.com/tx/0xb8e2e86f0ad1a35937c714cfbfeac948a8cb3a78bae1ddfbeca72de6f2fcac86 |

## 2026-06-05 16:47:06 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x1C2A9aBe3d3a4FBaD2FA0c795c311E670CE792C6` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a](https://lasna.reactscan.net/tx/0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a) |
| Lasna subscription | [0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626](https://lasna.reactscan.net/tx/0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0xb8012f0099294db9c2769be75e59885b4804ea15a56b9ad3c927e1cd5c34d343` | https://base-sepolia.blockscout.com/tx/0xb8012f0099294db9c2769be75e59885b4804ea15a56b9ad3c927e1cd5c34d343 |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0x63ec51bf82b44ba6b0607f82872de31472d97bb6af60f9996849d742673d9c5e` | https://base-sepolia.blockscout.com/tx/0x63ec51bf82b44ba6b0607f82872de31472d97bb6af60f9996849d742673d9c5e |
| Approval | Approve the deployed YieldStream hook to pull 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0xb78930f180bb98ee1a585b5693949f7b843c07254ed067b2eecc73de527f2a46` | https://base-sepolia.blockscout.com/tx/0xb78930f180bb98ee1a585b5693949f7b843c07254ed067b2eecc73de527f2a46 |
| Approval | Approve the deployed v4 swap test router to use 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0xde7a42d3ac85c6910a86b5eb7a4aed80b2d1cb135883fb727253b5e9193a8e5e` | https://base-sepolia.blockscout.com/tx/0xde7a42d3ac85c6910a86b5eb7a4aed80b2d1cb135883fb727253b5e9193a8e5e |
| Approval | Approve the deployed YieldStream hook to pull 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0xf3a14bd177dbfffa28370f559fe0c8770886e023023111099a4c0d7614dc2f16` | https://base-sepolia.blockscout.com/tx/0xf3a14bd177dbfffa28370f559fe0c8770886e023023111099a4c0d7614dc2f16 |
| Approval | Approve the deployed v4 swap test router to use 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0x6fa7809c56d50df9353a9ad88a9b116ee9e3e13c0ce14e6a97b0c3a37c25b602` | https://base-sepolia.blockscout.com/tx/0x6fa7809c56d50df9353a9ad88a9b116ee9e3e13c0ce14e6a97b0c3a37c25b602 |
| LP deposit | Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch. | `0x88984d1ba55216eb34e1d36f0135b25476515d68f73d335caef2ace0604b98d3` | https://base-sepolia.blockscout.com/tx/0x88984d1ba55216eb34e1d36f0135b25476515d68f73d335caef2ace0604b98d3 |

## 2026-06-05 16:48:19 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x1C2A9aBe3d3a4FBaD2FA0c795c311E670CE792C6` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a](https://lasna.reactscan.net/tx/0x1f6066c381daeab5c65570670fc3223d2f8cb32cc5e68ce9421cd47f04738d5a) |
| Lasna subscription | [0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626](https://lasna.reactscan.net/tx/0xfd48837052fc5d517af4a871534733e3df971163e2aaa0058ce24bf6ff5e7626) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0xf0d94c7db3ec250eff3db2645e99a18d41ad72b5bb57c33fa0c4c02f11718fb3` | https://base-sepolia.blockscout.com/tx/0xf0d94c7db3ec250eff3db2645e99a18d41ad72b5bb57c33fa0c4c02f11718fb3 |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0x8f945d3849e4921dc6d3984afc5b49c943c2d0dd834c8408612db5725e79f62b` | https://base-sepolia.blockscout.com/tx/0x8f945d3849e4921dc6d3984afc5b49c943c2d0dd834c8408612db5725e79f62b |
| Approval | Approve the deployed YieldStream hook to pull 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0x2f21d3ed5aae3f3a0bd916720d8b0313d6b4b946130d405b68a77015237ec8bf` | https://base-sepolia.blockscout.com/tx/0x2f21d3ed5aae3f3a0bd916720d8b0313d6b4b946130d405b68a77015237ec8bf |
| Approval | Approve the deployed v4 swap test router to use 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0x94077119db0b498df6791ad01743e7e968205d7237284e9144ff252874c3a236` | https://base-sepolia.blockscout.com/tx/0x94077119db0b498df6791ad01743e7e968205d7237284e9144ff252874c3a236 |
| Approval | Approve the deployed YieldStream hook to pull 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0x1de321179eba3579ce3f447027d0afd902a0f1f44d0b0b657595a1ebb70c5b27` | https://base-sepolia.blockscout.com/tx/0x1de321179eba3579ce3f447027d0afd902a0f1f44d0b0b657595a1ebb70c5b27 |
| Approval | Approve the deployed v4 swap test router to use 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0xc909811d4573363c82c3e1caa227569517183f02ecb64ad424f1a7daf1244806` | https://base-sepolia.blockscout.com/tx/0xc909811d4573363c82c3e1caa227569517183f02ecb64ad424f1a7daf1244806 |
| LP deposit | Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch. | `0x40d8350e8637a115ce05b32d75402cd4f4b359315b166b407ba10acbbf105975` | https://base-sepolia.blockscout.com/tx/0x40d8350e8637a115ce05b32d75402cd4f4b359315b166b407ba10acbbf105975 |
| FeesAccrued | Report active-epoch fees and emit the first FeesAccrued event observed by Lasna. | `0x1f39e63deeda42720479f2b3b8eba9162b77fa04ac6ff5e3c007789e0ca9077b` | https://base-sepolia.blockscout.com/tx/0x1f39e63deeda42720479f2b3b8eba9162b77fa04ac6ff5e3c007789e0ca9077b |
| FeesAccrued | Report post-boundary fees against the original epoch, causing the RSC to queue settlement. | `0x7fa1d461426e254fa392b6c941f57fe26060c9629a7e64b52a0fdaab4fb7b7d9` | https://base-sepolia.blockscout.com/tx/0x7fa1d461426e254fa392b6c941f57fe26060c9629a7e64b52a0fdaab4fb7b7d9 |

## 2026-06-05 16:53:18 UTC - unichain-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `unichain-sepolia (1301)` |
| Hook | `0x4C7734FfB1C9F054E1b16f1BBdcD9aEa98E80640` |
| Lasna RSC | `0x49d0C37CFbEFc27994e784BA542E4F1f6A1a892A` |
| Demo token0 | `0x2b60F617B914d2b77fA7F39a50147ec703777045` |
| Demo token1 | `0xfC876fa12cA7266554B6DA07E9eE542B35a2fB10` |
| PoolManager | `0x00B036B58a818B1BC34d502D3fE730Db729e62AC` |
| Swap router | `0x9140A78c1a137c7Ff1c151eC8231272AF78A99A4` |
| Lasna RSC deploy | [0x91c82166c529d79f7543ffb8fc65faa9681f0cdd231ff58ce0d52e41111b5cfd](https://lasna.reactscan.net/tx/0x91c82166c529d79f7543ffb8fc65faa9681f0cdd231ff58ce0d52e41111b5cfd) |
| Lasna subscription | [0x8f73d1d3f29d9ed172e5ac189bef633e9771eab60e7a23fc4852774cb2c51d69](https://lasna.reactscan.net/tx/0x8f73d1d3f29d9ed172e5ac189bef633e9771eab60e7a23fc4852774cb2c51d69) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0xbfd89d7932d0b0709a4754c05de0a1ad32ee73a3419318de365b9a069cc57856` | https://unichain-sepolia.blockscout.com/tx/0xbfd89d7932d0b0709a4754c05de0a1ad32ee73a3419318de365b9a069cc57856 |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0x4b28e16722bb12b8cb1d1a67b873e8ad96f2b3ca4faa39e2250927715ae7132f` | https://unichain-sepolia.blockscout.com/tx/0x4b28e16722bb12b8cb1d1a67b873e8ad96f2b3ca4faa39e2250927715ae7132f |
| Approval | Approve the deployed YieldStream hook to pull 0x2b60F617B914d2b77fA7F39a50147ec703777045. | `0x9550d6c1fb41f35a4f8e45c5fd152eda87002943b9d42ed3711eb87072add430` | https://unichain-sepolia.blockscout.com/tx/0x9550d6c1fb41f35a4f8e45c5fd152eda87002943b9d42ed3711eb87072add430 |
| Approval | Approve the deployed v4 swap test router to use 0x2b60F617B914d2b77fA7F39a50147ec703777045. | `0x57e870371e796475294d87dd8cc51d58377c30c26be40adae8879f5d70c5d8da` | https://unichain-sepolia.blockscout.com/tx/0x57e870371e796475294d87dd8cc51d58377c30c26be40adae8879f5d70c5d8da |
| Approval | Approve the deployed YieldStream hook to pull 0xfC876fa12cA7266554B6DA07E9eE542B35a2fB10. | `0x0dc094576dc600ad76f53d17c0e9083cc34807301c4ae1ddb6247912fae0234f` | https://unichain-sepolia.blockscout.com/tx/0x0dc094576dc600ad76f53d17c0e9083cc34807301c4ae1ddb6247912fae0234f |
| Approval | Approve the deployed v4 swap test router to use 0xfC876fa12cA7266554B6DA07E9eE542B35a2fB10. | `0xd6cc0c8df2bf5ad0cb1dfb620ca6d5124323b1fa76faa5ddc97da6bf178ca32c` | https://unichain-sepolia.blockscout.com/tx/0xd6cc0c8df2bf5ad0cb1dfb620ca6d5124323b1fa76faa5ddc97da6bf178ca32c |
| LP deposit | Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch. | `0x7f4b9d7154b7da42b3e4def5c945e2c6644edb8cfcdf2f19a69d9ce2c8001147` | https://unichain-sepolia.blockscout.com/tx/0x7f4b9d7154b7da42b3e4def5c945e2c6644edb8cfcdf2f19a69d9ce2c8001147 |
| FeesAccrued | Report active-epoch fees and emit the first FeesAccrued event observed by Lasna. | `0x725453d62fb7dfb64aa84a612d7f669aa0e9ec62e8e87eab5c59c85736dfc82c` | https://unichain-sepolia.blockscout.com/tx/0x725453d62fb7dfb64aa84a612d7f669aa0e9ec62e8e87eab5c59c85736dfc82c |
| FeesAccrued | Report post-boundary fees against the original epoch, causing the RSC to queue settlement. | `0x975128199cea309ca55d5868fada98befc99cedf7025965ff004c3082dcc225d` | https://unichain-sepolia.blockscout.com/tx/0x975128199cea309ca55d5868fada98befc99cedf7025965ff004c3082dcc225d |

### Result

| Item | Value |
|------|-------|
| Epoch | `2691299` |
| FYT | `0x55E0a895Ff1A358D8D84C1a89C1345d350fE31c9` |
| PT | `0x120528D646C3ccb6F1b7152d262F5C878E774bE9` |
| Fees0 | `4000000000000000` |
| Fees1 | `6000000000000000` |

## 2026-06-05 17:37:49 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0x16323dCC10523ea95A6C300A19fc65F84beFDC47` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0xaf144a6a7b14baa11d20d54873a880a3e6dce524c874190e8c7d568af5d89dc2](https://lasna.reactscan.net/tx/0xaf144a6a7b14baa11d20d54873a880a3e6dce524c874190e8c7d568af5d89dc2) |
| Lasna subscription | [0x0ed0bb0212aae2480af7835884b84abe0c118e734ba05862ea20a60974677d16](https://lasna.reactscan.net/tx/0x0ed0bb0212aae2480af7835884b84abe0c118e734ba05862ea20a60974677d16) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0xf2b40738bad60cfcd8af09383dd391752a58f6e61365c620e853fd275464762f` | https://base-sepolia.blockscout.com/tx/0xf2b40738bad60cfcd8af09383dd391752a58f6e61365c620e853fd275464762f |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0x5669c40be6205a352ac60aed2eb32634cd4286f0ab8bb15cb7e5d9c67c3f410e` | https://base-sepolia.blockscout.com/tx/0x5669c40be6205a352ac60aed2eb32634cd4286f0ab8bb15cb7e5d9c67c3f410e |
| Approval | Approve the deployed YieldStream hook to pull 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0xa03be110033c317921972d53040e51dd87a031135e656e65600009c2c5ecf4d5` | https://base-sepolia.blockscout.com/tx/0xa03be110033c317921972d53040e51dd87a031135e656e65600009c2c5ecf4d5 |
| Approval | Approve the deployed v4 swap test router to use 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0x29298ea2d52a0df335bb3ffc27fe74c257a7a95201693bdf3ede0d747a80962c` | https://base-sepolia.blockscout.com/tx/0x29298ea2d52a0df335bb3ffc27fe74c257a7a95201693bdf3ede0d747a80962c |
| Approval | Approve the deployed YieldStream hook to pull 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0xfa608d7f4f0e9dcf80a965b040a911b0a92c74b50889fcce242e1449f11c9a01` | https://base-sepolia.blockscout.com/tx/0xfa608d7f4f0e9dcf80a965b040a911b0a92c74b50889fcce242e1449f11c9a01 |
| Approval | Approve the deployed v4 swap test router to use 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0x4a6ef115f1369fe54d52f459136f7da904b3926169cf1b69376a772ef075905c` | https://base-sepolia.blockscout.com/tx/0x4a6ef115f1369fe54d52f459136f7da904b3926169cf1b69376a772ef075905c |
| LP deposit | Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch. | `0x6fa0689d3bebc9a93562295ec83eaa1fc7cddb88dff0cb99a356e2bac68a2498` | https://base-sepolia.blockscout.com/tx/0x6fa0689d3bebc9a93562295ec83eaa1fc7cddb88dff0cb99a356e2bac68a2498 |
| FeesAccrued | Report active-epoch fees and emit the first FeesAccrued event observed by Lasna. | `0xe68d097dc971041fad10a9ad7bea46edccaeccd29fbf9addaa2c2409cd3689b3` | https://base-sepolia.blockscout.com/tx/0xe68d097dc971041fad10a9ad7bea46edccaeccd29fbf9addaa2c2409cd3689b3 |
| FeesAccrued | Report post-boundary fees against the original epoch, causing the RSC to queue settlement. | `0xf405e8b5549471724a06b1effef50a997128495d6b5fb8762d1cd8e2d8236695` | https://base-sepolia.blockscout.com/tx/0xf405e8b5549471724a06b1effef50a997128495d6b5fb8762d1cd8e2d8236695 |

### Result

| Item | Value |
|------|-------|
| Epoch | `2122820` |
| FYT | `0xF9059EDDBA622382ADBe2E162c80E71aFE28a901` |
| PT | `0xCE8169eaC0bc0d00A97d9BE0C9111cbd34958C8d` |
| Fees0 | `4000000000000000` |
| Fees1 | `6000000000000000` |


## 2026-06-05 17:57:18 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0xD4342b1B631a5a465E09b81d1b99E6438c61d453` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0xea30b8b2a89eb51a2dc4800664c0ab73cdbfd80fbbc2016e0498058730393725](https://lasna.reactscan.net/tx/0xea30b8b2a89eb51a2dc4800664c0ab73cdbfd80fbbc2016e0498058730393725) |
| Lasna subscription | [0x96bbdbbf7cccca3a7f5d4a8cb039ae508f4e511a7a8be768ed6eacc0ccb97405](https://lasna.reactscan.net/tx/0x96bbdbbf7cccca3a7f5d4a8cb039ae508f4e511a7a8be768ed6eacc0ccb97405) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0xcc53bf0afe4a87fe0754ad188eb66892ef16bcaa13876ce83543d63895be1e26` | https://base-sepolia.blockscout.com/tx/0xcc53bf0afe4a87fe0754ad188eb66892ef16bcaa13876ce83543d63895be1e26 |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0xa311e8132583990606cc8f6e71bc62f453d108c449a1b700fb594e0ba4bc833e` | https://base-sepolia.blockscout.com/tx/0xa311e8132583990606cc8f6e71bc62f453d108c449a1b700fb594e0ba4bc833e |
| Approval | Approve the deployed YieldStream hook to pull 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0xdfb33474f2fd6c5b115bf027676c74d124d83cb5e277e447d5a01d88aa038af3` | https://base-sepolia.blockscout.com/tx/0xdfb33474f2fd6c5b115bf027676c74d124d83cb5e277e447d5a01d88aa038af3 |
| Approval | Approve the deployed v4 swap test router to use 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0x098a54c2a9e24626b3039f4287b97f27008b863aab36b85a74ac2672c38e9c20` | https://base-sepolia.blockscout.com/tx/0x098a54c2a9e24626b3039f4287b97f27008b863aab36b85a74ac2672c38e9c20 |
| Approval | Approve the deployed YieldStream hook to pull 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0x647fad16cc2e3ef45ce73515482dd35ce672de552dece7c1e142422d8cb3c08b` | https://base-sepolia.blockscout.com/tx/0x647fad16cc2e3ef45ce73515482dd35ce672de552dece7c1e142422d8cb3c08b |
| Approval | Approve the deployed v4 swap test router to use 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0x854af1293a96fbabd5fc934a7c97b9d8c96da76ab75d63d0b51b91eb24fa18cf` | https://base-sepolia.blockscout.com/tx/0x854af1293a96fbabd5fc934a7c97b9d8c96da76ab75d63d0b51b91eb24fa18cf |
| LP deposit | Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch. | `0x2b80b1b193560a57febf75f34a422abcd523d168be137918751cf862928772fd` | https://base-sepolia.blockscout.com/tx/0x2b80b1b193560a57febf75f34a422abcd523d168be137918751cf862928772fd |
| FeesAccrued | Report active-epoch fees and emit the first FeesAccrued event observed by Lasna. | `0x8dde5c4d138bc959643719a46f2cd393fa72a701a0655ae0c5dd3277e242fd79` | https://base-sepolia.blockscout.com/tx/0x8dde5c4d138bc959643719a46f2cd393fa72a701a0655ae0c5dd3277e242fd79 |
| FeesAccrued | Report post-boundary fees against the original epoch, causing the RSC to queue settlement. | `0x725a0a56f99eff5415f0d299fe170eac870141c049d39186338d07e720b2b132` | https://base-sepolia.blockscout.com/tx/0x725a0a56f99eff5415f0d299fe170eac870141c049d39186338d07e720b2b132 |

### Result

| Item | Value |
|------|-------|
| Epoch | `2122849` |
| FYT | `0x4292992Ef16A8aFd3F1c976f3DE0596A15fb193C` |
| PT | `0xc3780a8e3BDB9e4B23A24fCfAED16666C44434b5` |
| Fees0 | `4000000000000000` |
| Fees1 | `6000000000000000` |


## 2026-06-05 18:04:12 UTC - base-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `base-sepolia (84532)` |
| Hook | `0x4DeEB34Db482d776e043539394Fa70b772890640` |
| Lasna RSC | `0xD4342b1B631a5a465E09b81d1b99E6438c61d453` |
| Demo token0 | `0x552930CBBD455987D23aC8F732bc8D01F7e084dC` |
| Demo token1 | `0x73b65096500dB2CACbB5d87545646B95c4ee425a` |
| PoolManager | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |
| Swap router | `0x8B5Bcc363ddE2614281aD875BaD385E0A785D3B9` |
| Lasna RSC deploy | [0xea30b8b2a89eb51a2dc4800664c0ab73cdbfd80fbbc2016e0498058730393725](https://lasna.reactscan.net/tx/0xea30b8b2a89eb51a2dc4800664c0ab73cdbfd80fbbc2016e0498058730393725) |
| Lasna subscription | [0x96bbdbbf7cccca3a7f5d4a8cb039ae508f4e511a7a8be768ed6eacc0ccb97405](https://lasna.reactscan.net/tx/0x96bbdbbf7cccca3a7f5d4a8cb039ae508f4e511a7a8be768ed6eacc0ccb97405) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0xba83d7cb13dd29e7776b2e2ac5364d71cf0dd58cb663d8948d05d6561748718c` | https://base-sepolia.blockscout.com/tx/0xba83d7cb13dd29e7776b2e2ac5364d71cf0dd58cb663d8948d05d6561748718c |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0x5ee8215a6d4de2e21bfed7bdc4ff9d5a1fd145936956ca44c359007464c58c94` | https://base-sepolia.blockscout.com/tx/0x5ee8215a6d4de2e21bfed7bdc4ff9d5a1fd145936956ca44c359007464c58c94 |
| Approval | Approve the deployed YieldStream hook to pull 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0x3b2202bee721a4c5f075f546778215c8aa9af7e1d4bda2ad699d8057dd01a88a` | https://base-sepolia.blockscout.com/tx/0x3b2202bee721a4c5f075f546778215c8aa9af7e1d4bda2ad699d8057dd01a88a |
| Approval | Approve the deployed v4 swap test router to use 0x552930CBBD455987D23aC8F732bc8D01F7e084dC. | `0x5c3f3036a6de486e54b1b8b33ca93b3db05732342ac6ee6158104e0a60aa4764` | https://base-sepolia.blockscout.com/tx/0x5c3f3036a6de486e54b1b8b33ca93b3db05732342ac6ee6158104e0a60aa4764 |
| Approval | Approve the deployed YieldStream hook to pull 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0x91f26ac691667745586d13e556e03e96014b9129ea8ffc7c92273bc0bb48d1b9` | https://base-sepolia.blockscout.com/tx/0x91f26ac691667745586d13e556e03e96014b9129ea8ffc7c92273bc0bb48d1b9 |
| Approval | Approve the deployed v4 swap test router to use 0x73b65096500dB2CACbB5d87545646B95c4ee425a. | `0xd504acff087d2bed64c6da3d1b9605a3253a4671678b93cef1dc8fa34839d26f` | https://base-sepolia.blockscout.com/tx/0xd504acff087d2bed64c6da3d1b9605a3253a4671678b93cef1dc8fa34839d26f |
| LP deposit | Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch. | `0x69c8fb75c48bdf08488bf5d87d0b81df9989586652de92e3c8c592e99ef02fbd` | https://base-sepolia.blockscout.com/tx/0x69c8fb75c48bdf08488bf5d87d0b81df9989586652de92e3c8c592e99ef02fbd |
| FeesAccrued | Report active-epoch fees and emit the first FeesAccrued event observed by Lasna. | `0x2fdd7fb41fd787f6b2a97612a0e64d37929ca1189c7464004a515a672298316a` | https://base-sepolia.blockscout.com/tx/0x2fdd7fb41fd787f6b2a97612a0e64d37929ca1189c7464004a515a672298316a |
| FeesAccrued | Report post-boundary fees against the original epoch, causing the RSC to queue settlement. | `0xaf0f052341722586a4114b40ab034e596db948916a2139bb0321eff432cd6b51` | https://base-sepolia.blockscout.com/tx/0xaf0f052341722586a4114b40ab034e596db948916a2139bb0321eff432cd6b51 |
| Reactive callback | Reactive Network submitted settleEpochFromReactive and the hook emitted EpochSettled. | `0x0444c396d5b1f47b49bc8cd350affb6fecb38de199fa587ed97b8b121bae5541` | https://base-sepolia.blockscout.com/tx/0x0444c396d5b1f47b49bc8cd350affb6fecb38de199fa587ed97b8b121bae5541 |

### Result

| Item | Value |
|------|-------|
| Epoch | `2122859` |
| FYT | `0xF0514a0f7820AD92A2ba08a58bF6D7CaAA8971EA` |
| PT | `0xE14929B80D5Ade6e8b63BC51fbaC6112E5993410` |
| Fees0 | `4000000000000000` |
| Fees1 | `6000000000000000` |


## 2026-06-05 18:06:49 UTC - unichain-sepolia

### Infrastructure

| Item | Value |
|------|-------|
| Destination chain | `unichain-sepolia (1301)` |
| Hook | `0x4C7734FfB1C9F054E1b16f1BBdcD9aEa98E80640` |
| Lasna RSC | `0xf9C557b4097f399dBa99EB1DB2caf5fc7ADfE786` |
| Demo token0 | `0x2b60F617B914d2b77fA7F39a50147ec703777045` |
| Demo token1 | `0xfC876fa12cA7266554B6DA07E9eE542B35a2fB10` |
| PoolManager | `0x00B036B58a818B1BC34d502D3fE730Db729e62AC` |
| Swap router | `0x9140A78c1a137c7Ff1c151eC8231272AF78A99A4` |
| Lasna RSC deploy | [0xcc18660955a35417e02a693d37e6a95540abf2271e650442f8902b967a0b8f27](https://lasna.reactscan.net/tx/0xcc18660955a35417e02a693d37e6a95540abf2271e650442f8902b967a0b8f27) |
| Lasna subscription | [0x434685da655bcbdc5b2e8b19a545f9fb37726bbeb2201cb5cb4e85a63b3a416b](https://lasna.reactscan.net/tx/0x434685da655bcbdc5b2e8b19a545f9fb37726bbeb2201cb5cb4e85a63b3a416b) |

### Transactions

| Phase | Description | Tx hash | URL |
|-------|-------------|---------|-----|
| Funding | Mint demo token0 to the deployer for deposits, swaps, and fee reports. | `0x2dcc35a1a9ea68b1d05515e3f3186fb0ee0bfaca404f6276a531253b41c14706` | https://unichain-sepolia.blockscout.com/tx/0x2dcc35a1a9ea68b1d05515e3f3186fb0ee0bfaca404f6276a531253b41c14706 |
| Funding | Mint demo token1 to the deployer for deposits, swaps, and fee reports. | `0x3d7ef7aea41cb4fea3c12c965e1f3487157abc78eb561dd9506d426d8bb4d77d` | https://unichain-sepolia.blockscout.com/tx/0x3d7ef7aea41cb4fea3c12c965e1f3487157abc78eb561dd9506d426d8bb4d77d |
| Approval | Approve the deployed YieldStream hook to pull 0x2b60F617B914d2b77fA7F39a50147ec703777045. | `0x3c90c27a4095c880b043c0afc7ee984f7cbf2f382d5228d3187a85029993ab14` | https://unichain-sepolia.blockscout.com/tx/0x3c90c27a4095c880b043c0afc7ee984f7cbf2f382d5228d3187a85029993ab14 |
| Approval | Approve the deployed v4 swap test router to use 0x2b60F617B914d2b77fA7F39a50147ec703777045. | `0x5fb7ea6478418789c2a440df3833214c6a38b1ddc8d8f762f3f9a87403615f59` | https://unichain-sepolia.blockscout.com/tx/0x5fb7ea6478418789c2a440df3833214c6a38b1ddc8d8f762f3f9a87403615f59 |
| Approval | Approve the deployed YieldStream hook to pull 0xfC876fa12cA7266554B6DA07E9eE542B35a2fB10. | `0x29594b6998602b5d606f6f3cc4d8b5b91de74b80eefed90b210f43d3a0966e4a` | https://unichain-sepolia.blockscout.com/tx/0x29594b6998602b5d606f6f3cc4d8b5b91de74b80eefed90b210f43d3a0966e4a |
| Approval | Approve the deployed v4 swap test router to use 0xfC876fa12cA7266554B6DA07E9eE542B35a2fB10. | `0x2fd455c4804785e939debb6b6bfaf52a963f7b17f2726a70eec11ea717bdfd72` | https://unichain-sepolia.blockscout.com/tx/0x2fd455c4804785e939debb6b6bfaf52a963f7b17f2726a70eec11ea717bdfd72 |
| LP deposit | Deposit hook-managed liquidity into the deployed YieldStream hook and mint PT/FYT for this epoch. | `0xa2247bdb86acbd764d504033a8783fe7877a28cb857749d07a584d126f46e886` | https://unichain-sepolia.blockscout.com/tx/0xa2247bdb86acbd764d504033a8783fe7877a28cb857749d07a584d126f46e886 |
| FeesAccrued | Report active-epoch fees and emit the first FeesAccrued event observed by Lasna. | `0x20686899687ae1014513aed573c4ae92e21fa39e57e906145642eafcf1a9a55f` | https://unichain-sepolia.blockscout.com/tx/0x20686899687ae1014513aed573c4ae92e21fa39e57e906145642eafcf1a9a55f |
| FeesAccrued | Report post-boundary fees against the original epoch, causing the RSC to queue settlement. | `0x792e873841ffacc1d4ad99a1ff25c528ec2ca5a87f430c41afc1620aa23546b4` | https://unichain-sepolia.blockscout.com/tx/0x792e873841ffacc1d4ad99a1ff25c528ec2ca5a87f430c41afc1620aa23546b4 |
| Reactive callback | Reactive Network submitted settleEpochFromReactive and the hook emitted EpochSettled. | `0x6b8a3f668ae2c0d8e6f5d106443f829933c3c7314671fd7182d9b29686623fbc` | https://unichain-sepolia.blockscout.com/tx/0x6b8a3f668ae2c0d8e6f5d106443f829933c3c7314671fd7182d9b29686623fbc |

### Result

| Item | Value |
|------|-------|
| Epoch | `2691520` |
| FYT | `0x380D359015Df909ee939918513c307EEF12DE183` |
| PT | `0xD3E5afC202Ed9469d01d79278Ce910A58E11d16D` |
| Fees0 | `4000000000000000` |
| Fees1 | `6000000000000000` |

