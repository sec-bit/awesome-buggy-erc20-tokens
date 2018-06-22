

# Awesome-buggy-erc20-tokens
[![CC0](http://mirrors.creativecommons.org/presskit/buttons/88x31/svg/cc-zero.svg)](https://creativecommons.org/publicdomain/zero/1.0/)
[![Join the chat at https://gitter.im/sec-bit/Lobby](https://badges.gitter.im/sec-bit/Lobby.svg)](https://gitter.im/sec-bit/Lobby)
[![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

A Collection of Vulnerabilities in ERC20 Smart Contracts With Tokens Affected

Read the docs in Chinese: https://github.com/sec-bit/awesome-buggy-erc20-tokens/blob/master/README_CN.md

## Problems in ERC20 Token Contracts

[ERC20 standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md) is one of the most popular Ethereum token standards[1]. As of June 20th, 2018, more than 90,000 ERC20 token smart contracts have been deployed according to [statistics from Etherscan](https://etherscan.io/tokens). Here is a daily trend chart of ERC20 contracts created according to our statistics:

![ERC20 Contracts Created on main Ethereum network every day](img/erc20-creation.jpeg)

Though a huge amount of assets are managed by those ERC20 token contracts, the contracts by themselves are not always secure as supposed. Lots of critical security issues have been revealed,  some of which have led to severe financial losses [2-6]. Another type of problems is the incompatibility. Some ERC20 token contracts do not follow the ERC20 standard strictly, which is troublesome to developers of DApps on ERC20 tokens [7, 8]. Other types of problems do exist in ERC20 token contracts as well.

We made a collection of past bugs and vulnerabilities, including:

1. vulnerabilities in Token contracts
2. incompatibilities due to inconsistency with ERC20
3. excessive authorities of Token administrators[9]

## Why This Repo?

There are many projects in Ethereum community contributing to the ecosystem of smart contracts, such as 'A guide to smart contract security best practices'[10] maintained by Consensys and 'OpenZeppelin, a framework to build secure smart contracts on Ethereum'[11] developer by OpenZeppelin.

However, we found the fact that a majority of issues in buggy Token contracts come from refering, copying and modifying code without caution. Also, using incorrect example code is a cause. It is difficult for beginners and developers of smart contracts to determine whether a contract snippet from main net contains bugs and identify these issues in seconds.

In the belief that human-beings are good at learning from mistakes, we created this repo and would keep collecting known bugs and vulnerabilities in ERC20 token contracts, along with those got affected.

We created and would maintain this collection with good intentions, including but not limited to:

- providing a reference and learning materials of common bugs in ERC20 token contracts
- helping ERC20 token contract developers to develop correct and secure contracts
- noticing DApp developers of incompatible/buggy/vulnerable ERC20 token contracts
- warning exchanges and investors of potential risks in incompatible/buggy/insecure ERC20 tokens
- ...

## What We Collect?

+ Descriptions of common vulnerabilities
+ List of deployed buggy token contracts
+ List of incompatible token contracts

## Repo Structure

```bash
awesome-buggy-erc20-tokens
├── TOKEN_DETAIL_DICT.json
├── bug-list.md
├── issues.json
├── badtop600token.csv
├── badtop600token.json
├── raw/
├── csv/
├── json/
└── gen_list_from_raw.py
```

- [`TOKEN_DETAIL_DICT.json`](TOKEN_DETAIL_DICT.json) lists addresses and basic information of ERC20 contracts collected by [CoinMarketCap](https://coinmarketcap.com/tokens/)
- [`bug-list.md`](bug-list.md) lists detailed descriptions of known bugs.
- [`issues.json`](issues.json) maps between known bugs and indexes.
- [`bad_top_tokens.csv`](bad_top_tokens.csv) along with [`bad_top_tokens.json`](bad_top_tokens.json) are lists of buggy Token contracts in CSV and JSON formats.
-  [`raw/`](raw), [`csv/`](csv) and [`json/`](json) list all known bugs and addresses of affected contracts in formats of plain text, CSV and JSON.
- [`gen_list_from_raw.py`](gen_list_from_raw.py) is a script to generate ```.csv``` and ```.json``` lists above.

As shown below, lists in CSV and JSON help developers to browse and search for addresses of given contracts with known vulnerabilities.

```csv
addr,category,name,symbol,info
0x093e5C256Ff8B32c7F1377f4C20e331674C77F00,[7],Dignity,DIG,_
0x0aeF06DcCCC531e581f0440059E6FfCC206039EE,[1],Intelligent Trading Technologies,ITT,_
0x0b76544F6C413a555F309Bf76260d1E02377c02A,[1][12][14][7],Internet Node Token,INT,_
```

```json
{
    "0x093e5C256Ff8B32c7F1377f4C20e331674C77F00": {
        "info": "_",
        "issues": {
            "totalsupply-overflow": true
        },
        "name": "Dignity",
        "rank": 613,
        "symbol": "DIG"
    },
    "0x0aeF06DcCCC531e581f0440059E6FfCC206039EE": {
        "info": "_",
        "issues": {
            "transfer-no-return": true
        },
        "name": "Intelligent Trading Technologies",
        "rank": 551,
        "symbol": "ITT"
    },
    "0x0b76544F6C413a555F309Bf76260d1E02377c02A": {
        "info": "_",
        "issues": {
            "owner-control-sell-price-for-overflow": true,
            "owner-decrease-balance-by-mint-by-overflow": true,
            "totalsupply-overflow": true,
            "transfer-no-return": true
        },
        "name": "Internet Node Token",
        "rank": 168,
        "symbol": "INT"
    }
}
```

## How to Contribute

We hope this collection can contribute to the Ethereum ecosystem and definitely welcome contributions to this collection.

- This collection only contains token contracts that have market caps on [CoinMarketCap](https://coinmarketcap.com/) for now. If you find any other incompatible/buggy/vulnerable ERC20 token contracts, please update [`TOKEN_DETAIL_DICT.json`](TOKEN_DETAIL_DICT.json) and send us a pull request.
- If you find other bugs not listed in this collection, please update in the following process.
  1. Add the name and description of the bug with reference to [`bug-list.md`](bug-list.md)
  2. Create a new file with the bug name in [`raw`](raw) directory and fill in the address of affected contracts
  3. Add the name and index of the new bug to [`issues.json`](issues.json)
  4. Run `python3 gen_list_from_raw.py -i raw/* -o bad_top_tokens` in the repo root
  5. Check the update and send us a pull request

If you have any questions or ideas, please join our discussion on [Gitter](https://gitter.im/sec-bit/Lobby).

## References

1. [ERC20 Token Standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md), Nov 19, 2015
2. [Understanding The DAO Hack for Journalists](https://medium.com/@pullnews/understanding-the-dao-hack-for-journalists-2312dd43e993), Jun 19, 2016
3. [A disastrous vulnerability found in smart contracts of BeautyChain (BEC)](https://medium.com/secbit-media/a-disastrous-vulnerability-found-in-smart-contracts-of-beautychain-bec-dbf24ddbc30e), Apr 23, 2018
4. [Alert! Another integer overflow vulnerability just found in HXG smart contract](https://medium.com/secbit-media/alert-another-integer-overflow-vulnerability-just-found-in-hxg-smart-contract-ff2f69fdd242), May 19, 2018
5. [UselessEthereumToken(UET), ERC20 token, allows attackers to steal all victim’s balances (CVE-2018–10468)](https://medium.com/coinmonks/uselessethereumtoken-uet-erc20-token-allows-attackers-to-steal-all-victims-balances-543d42ac808e), May 3, 2018
6. [Bugged Smart Contract FuturXE: How Could Someone Mess up with Boolean? (CVE-2018–12025)](https://medium.com/secbit-media/bugged-smart-contract-f-e-how-could-someone-mess-up-with-boolean-d2251defd6ff), Jun 6, 2018
7. [An Incompatibility in Ethereum Smart Contract Threatening dApp Ecosystem](https://medium.com/loopring-protocol/an-incompatibility-in-smart-contract-threatening-dapp-ecosystem-72b8ca5db4da), Jun 8, 2018
8. [Redundant Check in ERC20 Smart Contracts’ approve()](https://medium.com/secbit-media/redundant-check-in-erc20-smart-contracts-approve-5a675bb88261), Jun 15, 2018
9. [Highly-Manipulatable ERC20 Tokens Identified in Multiple Top Exchanges](https://medium.com/@peckshield/highly-manipulatable-erc20-tokens-identified-in-multiple-top-exchanges-including-binance-d158deab4b9a), Jun 9, 2018
10. [A guide to smart contract security best practices](https://github.com/ConsenSys/smart-contract-best-practices)
11. [OpenZeppelin, a framework to build secure smart contracts on Ethereum](https://github.com/OpenZeppelin/openzeppelin-solidity)

## License

[![CC0](http://mirrors.creativecommons.org/presskit/buttons/88x31/svg/cc-zero.svg)](https://creativecommons.org/publicdomain/zero/1.0/)
