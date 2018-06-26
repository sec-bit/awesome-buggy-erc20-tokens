# Awesome Buggy ERC20 Tokens
[![Join the chat at https://gitter.im/sec-bit/Lobby](https://badges.gitter.im/sec-bit/Lobby.svg)](https://gitter.im/sec-bit/Lobby)
[![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

A Collection of Vulnerabilities in ERC20 Smart Contracts With Tokens Affected

Read the docs in Chinese: <https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/README_CN.md>

## Navigation

- Visit [`bad_tokens_all.csv`](bad_tokens_all.csv) for a summary of all Token contracts affected
- Visit [`bad_tokens_top.csv`](bad_tokens_top.csv) for a summary of top ranking Token contracts affected
- Visit [`ERC20_token_issue_list.md`](ERC20_token_issue_list.md) for a detailed description of all bugs and Token contracts affected
- [Click here](#how-to-contribute) if you find a mistake or anything missed in this repo

## Recent Updates

- [2018-06-25, TFD, a16-custom-call-abuse](ERC20_token_issue_list.md#a16-custom-call-abuse)
- Add info of totalSupply, decimals, exchanges into Token lists
- [2018-06-20, ATN, a15-custom-fallback-bypass-ds-auth](ERC20_token_issue_list.md#a15-custom-fallback-bypass-ds-auth)
- [2018-06-22, MORPH, a14-constructor-case-insentive](ERC20_token_issue_list.md#a14-constructor-case-insensitive)
- [2018-06-16, ICX, a11-pausetransfer-anyone](ERC20_token_issue_list.md#a11-pausetransfer-anyone)
- [2018-06-12, PKT, a8-excess-mint-token-by-overflow](ERC20_token_issue_list.md#a8-excess-mint-token-by-overflow)
- [2018-06-08, ITC, b1-transfer-no-return](ERC20_token_issue_list.md#b1-transfer-no-return)

## Problems in ERC20 Token Contracts

[ERC20 standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md) is one of the most popular Ethereum token standards [[1]](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md). As of June 20th, 2018, more than 90,000 ERC20 token smart contracts have been deployed according to [statistics from Etherscan](https://etherscan.io/tokens). Here is a daily trend chart of ERC20 contracts created according to our statistics:

![ERC20 Contracts Created on main Ethereum network every day](img/erc20-creation.jpeg)

### Security Incidents in Smart Contracts

ERC20 Token specification has gone through challenges and improvements during its growth. Lots of critical security issues have been revealed,  some of which have led to severe financial losses [2-11] for developers, investors, even Ethereum community as well.

On June 18th, 2016, the DAO hack caused a total loss of over 3,600,000 ethers(ETH) worth over a billion dollars, and the Ethereum hard-fork afterwards led to the Ethereum community breaking apart [[2]](https://medium.com/@pullnews/understanding-the-dao-hack-for-journalists-2312dd43e993).

On April 22th, 2018, the attack on BeautyChain(BEC) contract hardly decreased the token price to zero via pouring astronomical tokens to exchanges through an integer overflow [[3]](https://medium.com/secbit-media/a-disastrous-vulnerability-found-in-smart-contracts-of-beautychain-bec-dbf24ddbc30e).

On April 25th, 2018, a similar integer overflow got uncovered in SMT. Hackers minted and dumped a tremendous amount of tokens, resulting in SMT's collapse [[4]](https://smartmesh.io/2018/04/25/smartmesh-announcement-on-ethereum-smart-contract-overflow-vulnerability/).

On May 20th, 2018, another integer overflow problem was found in EDU along with other three Token contracts, causing that anyone could transfer out other accounts' balance [[5]](https://mp.weixin.qq.com/s/lf9vXcUxdB2fGY2YVTauRQ). After further analysis, we caught this bug in at least 81 contracts (CVE-2018–11397, CVE-2018–11398) [[6]](https://mp.weixin.qq.com/s/9FMt_TBSb9avL78KEAXHuA).

On June 12, 2018, a series of overflow bug in ERC20 smart contracts got uncovered (CVE-2018-11687, CVE-2018-11809, CVE-2018-11810, CVE-2018-11811, CVE-2018-11812) [[7]](https://www.secrss.com/articles/3289). We have revealed more than 800 contracts with the same problem after scanning over 20,000 contracts deployed on Etherscan [[8]](http://www.chaindd.com/3083754.html).

### Failure of Satisfying ERC20 in Many ERC20 contracts

Lots of ERC20 token contracts do not follow the ERC20 standard strictly, which is troublesome to developers of DApps on ERC20 tokens [12-14].

Thousands of deployed Token contracts referred to incorrect example code on Ethereum official website and OpenZeppelin, resulting in several functions failing to meet ERC20 standard. After upgrading Solidity compiler to 0.4.22, incompatibilities would arise and these contracts could not perform normal transactions on decentralized exchanges (DEX) or DApp in most cases [[12]](https://medium.com/loopring-protocol/an-incompatibility-in-smart-contract-threatening-dapp-ecosystem-72b8ca5db4da), whereas a majority of DApp developing teams were off guard and unaware of such a problem.

Several Token contracts added redundant checks in standard `approve()`, requiring that the approved \_amount smaller or equal to the current balance. However, it makes DEX employing protocols like 0x hard to finish `approve()` in advance, asking the Token developing team transfer a huge amount of tokens to the exchange's intermediate account ahead which violates the target of employing ERC20 standard and brings about inconvenience.

Since it is defined optional to set common querying interfaces like `name()`, `symbol()` and `decimals()` in ERC20 specification [[1]](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md), many Token contracts left them out or named them differently, such as `NAME()`, `SYMBOL()` and `DECIMALS()`, making it harder for DEX and DApp developing.

Another point worth mentioning is that two events - `Transfer` and `Approval` should get fired under certain circumstances described by ERC20 specification [[1]](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md). In fact, many Token contracts left out `Approval` event referring to Ethereum official website [[14]](https://github.com/ethereum/ethereum-org/pull/865). This omission causes great difficulty for developers listening to relevant events, undermining the development of DApp ecosystem.

### One Solution: Collecting Buggy Token Contracts

Statistical summaries from security organizations and experts indicate that critical vulnerabilities are hiding in smart contracts, taking the '*TOP 10 in 2018*' by NCC group [[15]](https://www.dasp.co/) as an example:

- Reentrancy
- Access Control
- Integer Overflow
- Unchecked Return Values For Low Level Calls
- Denial of Service
- Bad Randomness
- Front-Running
- Time manipulation
- Short Address Attack
- Unknown Unknowns

This might be just the tip of an iceberg. Recent research together with the aforementioned point of view state clearly that the scale of problems in smart contracts deployed on Ethereum may go beyond our imagination.

We made a collection of past bugs and vulnerabilities, including:

1. vulnerabilities in Token contracts
2. incompatibilities due to inconsistency with ERC20
3. excessive authorities of Token administrators [[16]](https://medium.com/@peckshield/highly-manipulatable-erc20-tokens-identified-in-multiple-top-exchanges-including-binance-d158deab4b9a)

## Why This Repo?

There are many projects in Ethereum community contributing to the ecosystem of smart contracts, such as '*A guide to smart contract security best practices*' [[17]](https://github.com/ConsenSys/smart-contract-best-practices) maintained by Consensys and '*OpenZeppelin, a framework to build secure smart contracts on Ethereum*' [[18]](https://github.com/OpenZeppelin/openzeppelin-solidity) developed by OpenZeppelin.

However, we found the fact that a majority of issues in buggy Token contracts come from referring, copying and modifying code without caution. Also, using incorrect example code is an origin of bugs. It is difficult for beginners and developers of smart contracts to determine whether a contract snippet from main net contains bugs and identify these issues in seconds.

In the belief that human-beings are good at learning from mistakes, we created this repo and would keep collecting known bugs and vulnerabilities in ERC20 token contracts, along with those got affected.

We created and would maintain this collection to:

- provide a reference and learning materials of common bugs in ERC20 token contracts
- help ERC20 token contract developers to develop correct and secure contracts
- notice DApp developers of incompatible/buggy/vulnerable ERC20 token contracts
- warn exchanges and investors of potential risks in incompatible/buggy/insecure ERC20 tokens

## What We Collect?

+ Descriptions of common vulnerabilities
+ List of deployed buggy token contracts
+ List of incompatible token contracts

## Repo Structure

```bash
awesome-buggy-erc20-tokens
├── TOKEN_DICT.json
├── TOKEN_DETAIL_DICT.json
├── ERC20_token_issue_list_CN.md
├── issues.json
├── bad_tokens_all.csv
├── bad_tokens_all.json
├── bad_tokens_top.csv
├── bad_tokens_top.json
├── raw/
├── csv/
├── json/
├── gen_token_detail_dict.py
└── gen_list_from_raw.py
```
- [`TOKEN_DICT.json`](TOKEN_DICT.json) lists addresses and basic information of ERC20 contracts collected by [CoinMarketCap](https://coinmarketcap.com/tokens/)
- [`TOKEN_DETAIL_DICT.json`](TOKEN_DETAIL_DICT.json) lists addresses and detailed information of ERC20 contracts collected by [CoinMarketCap](https://coinmarketcap.com/tokens/)
- [`ERC20_token_issue_list.md`](ERC20_token_issue_list.md) lists detailed descriptions of known bugs.
- [`issues.json`](issues.json) maps between known bugs and indexes.
- [`bad_tokens_all.csv`](bad_tokens_all.csv) along with [`bad_tokens_all.json`](bad_tokens_all.json) are lists of all buggy Token contracts in CSV and JSON formats.
- [`bad_tokens_top.csv`](bad_tokens_top.csv) along with [`bad_tokens_top.json`](bad_tokens_top.json) are lists of top ranking buggy Token contracts in CSV and JSON formats.
-  [`raw/`](raw), [`csv/`](csv) and [`json/`](json) list all known bugs and addresses of affected contracts in formats of plain text, CSV and JSON.
- [`gen_token_detail_dict.py`](gen_token_detail_dict.py) is a script to update [`TOKEN_DETAIL_DICT.json`](TOKEN_DETAIL_DICT.json)
- [`gen_list_from_raw.py`](gen_list_from_raw.py) is a script to generate ```.csv``` and ```.json``` lists above.

As shown below, lists in CSV and JSON help developers to browse and search for addresses of given contracts with known vulnerabilities.

```csv
addr,category,name,symbol,exchanges,totalSupply,decimals,info
0x014B50466590340D41307Cc54DCee990c8D58aa8,[B6],ICOS,ICOS,@HitBTC@Tidex,560417,6,_
0x093e5C256Ff8B32c7F1377f4C20e331674C77F00,[A2],Dignity,DIG,@Livecoin,3000000000,8,_
```

```json
{
    "0x014B50466590340D41307Cc54DCee990c8D58aa8": {
        "decimals": 6,
        "exchanges": [
            "HitBTC",
            "Tidex"
        ],
        "info": "_",
        "issues": {
            "no-symbol": true
        },
        "name": "ICOS",
        "rank": 316,
        "symbol": "ICOS",
        "totalSupply": 560417
    },
    "0x093e5C256Ff8B32c7F1377f4C20e331674C77F00": {
        "decimals": 8,
        "exchanges": [
            "Livecoin"
        ],
        "info": "_",
        "issues": {
            "totalsupply-overflow": true
        },
        "name": "Dignity",
        "rank": 613,
        "symbol": "DIG",
        "totalSupply": 3000000000
    }
}
```

## How to Contribute

We hope this collection can contribute to the Ethereum ecosystem and definitely welcome contributions to this collection.

For now we only maintain detailed information of token contracts (totalSupply, decimals, exchanges) that have market caps on CoinMarketCap. If you find any other incompatible/buggy/vulnerable ERC20 token contracts, please update [`TOKEN_DICT.json`](TOKEN_DICT.json) and use script [`gen_token_detail_dict.py`](gen_token_detail_dict.py).

If you find other bugs not listed in this collection, please update in the following process.
  - Add the name and description of the bug with reference to [`ERC20_token_issue_list.md`](ERC20_token_issue_list.md)
  - Create a new file with the bug name in [`raw`](raw) directory and fill in the address of affected contracts
  - Add the name and index of the new bug to [`issues.json`](issues.json)
  - Run `python3 gen_list_from_raw.py -i raw/* -o bad_tokens` in the repo root
  - Check the update and send us a pull request

If you have any questions or ideas, please join our discussion on [Gitter](https://gitter.im/sec-bit/Lobby).

## References

- \[1\] [ERC-20 Token Standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md), Nov 19, 2015
- \[2\] [Understanding The DAO Hack for Journalists](https://medium.com/@pullnews/understanding-the-dao-hack-for-journalists-2312dd43e993), Jun 19, 2016
- \[3\] [A disastrous vulnerability found in smart contracts of BeautyChain (BEC)](https://medium.com/secbit-media/a-disastrous-vulnerability-found-in-smart-contracts-of-beautychain-bec-dbf24ddbc30e), Apr 23, 2018
- \[4\] [SmartMesh Announcement on Ethereum Smart Contract Overflow Vulnerability](https://smartmesh.io/2018/04/25/smartmesh-announcement-on-ethereum-smart-contract-overflow-vulnerability/)
- [5] SECBIT: 智能合约红色预警：四个Token惊爆逻辑漏洞，归零风险或源于代码复制, <https://mp.weixin.qq.com/s/lf9vXcUxdB2fGY2YVTauRQ>
- [6] SECBIT: 围观！81个智能合约惊现同一漏洞，是巧合？还是另有玄机？, <https://mp.weixin.qq.com/s/9FMt_TBSb9avL78KEAXHuA>
- [7] Tsinghua-360 Research Center of Enterprise Security: ERC20智能合约整数溢出系列漏洞披露, <https://www.secrss.com/articles/3289>
- [8]【ChainDD】ERC20智能合约又现大量整数溢出漏洞, <http://www.chaindd.com/3083754.html>
- \[9\] [Alert! Another integer overflow vulnerability just found in HXG smart contract](https://medium.com/secbit-media/alert-another-integer-overflow-vulnerability-just-found-in-hxg-smart-contract-ff2f69fdd242), May 19, 2018
- \[10\] [UselessEthereumToken(UET), ERC20 token, allows attackers to steal all victim’s balances (CVE-2018–10468)](https://medium.com/coinmonks/uselessethereumtoken-uet-erc20-token-allows-attackers-to-steal-all-victims-balances-543d42ac808e), May 3, 2018
- \[11\] [Bugged Smart Contract FuturXE: How Could Someone Mess up with Boolean? (CVE-2018–12025)](https://medium.com/secbit-media/bugged-smart-contract-f-e-how-could-someone-mess-up-with-boolean-d2251defd6ff), Jun 6, 2018
- \[12\] [An Incompatibility in Ethereum Smart Contract Threatening dApp Ecosystem](https://medium.com/loopring-protocol/an-incompatibility-in-smart-contract-threatening-dapp-ecosystem-72b8ca5db4da), Jun 8, 2018
- \[13\] [Redundant Check in ERC20 Smart Contracts’ approve()](https://medium.com/secbit-media/redundant-check-in-erc20-smart-contracts-approve-5a675bb88261), Jun 15, 2018
- \[14\] [token-erc20: add event Approval to follow eip20](https://github.com/ethereum/ethereum-org/pull/865)
- \[15\] [DASP - Top 10 of 2018](https://www.dasp.co/)
- \[16\] [PeckShield: Highly-Manipulatable ERC20 Tokens Identified in Multiple Top Exchanges](https://medium.com/@peckshield/highly-manipulatable-erc20-tokens-identified-in-multiple-top-exchanges-including-binance-d158deab4b9a), Jun 9, 2018
- \[17\] [A guide to smart contract security best practices](https://github.com/ConsenSys/smart-contract-best-practices)
- \[18\] [OpenZeppelin, a framework to build secure smart contracts on Ethereum](https://github.com/OpenZeppelin/openzeppelin-solidity)
- \[19\] [360 0KEE Team: 以太坊智能合约Hexagon存在溢出漏洞](https://www.jianshu.com/p/c5363ffad6a7), May 18, 2018
- \[20\] [SlowMist：ATN 披露特殊场景下的以太坊合约重大漏洞](https://mp.weixin.qq.com/s/S5Oq4TxxW5OgEkOmy8ZSzQ), Jun 20, 2018
- \[21\] [BCSEC: 一些智能合约存在笔误，一个字母可造成代币千万市值蒸发！](https://bcsec.org/index/detail?id=157), Jun 22, 2018
- \[22\] [LianAn：小心！智能合约再爆高危漏洞，两大加密货币直接变废纸！](https://mp.weixin.qq.com/s/qDTrZPy5f4_-V2F4DpzoNA), Jun 6, 2018

## License

[![CC0](http://mirrors.creativecommons.org/presskit/buttons/88x31/svg/cc-zero.svg)](https://creativecommons.org/publicdomain/zero/1.0/)
