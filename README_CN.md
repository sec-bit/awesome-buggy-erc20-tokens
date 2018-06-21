

# Awesome-buggy-erc20-tokens
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Join the chat at https://gitter.im/sec-bit/Lobby](https://badges.gitter.im/sec-bit/Lobby.svg)](https://gitter.im/sec-bit/Lobby)
[![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

以太坊 ERC20 智能合约风险问题及影响 Token 汇总

## 快速提示

- 想快速查询某 Token 合约代码是否存在问题，[点此直达](bad_top_tokens.csv)
- 想了解各类合约漏洞细节讲解以及受影响 Token，[点此直达](bug-list.md)
- 本项目列表正在持续更新，如有遗漏和误报，[欢迎指正](#如何参与贡献)

## 最近更新

- [2018-06-16, ICX, pauseTransfer-anyone](bug-list.md#a11-pausetransfer-anyone)
- [2018-06-12, PKT, excess-mint-token-by-overflow](bug-list.md#a8-excess-mint-token-by-overflow)
- [2018-06-08, ITC, transfer-no-return](bug-list.md#b1-transfer-no-return)

## ERC20 Token 面临的主要问题

以太坊 ERC20 Token 标准自 2015 年 11 月 19 日诞生以来 [[1]](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md)，为智能合约、以太坊生态以及区块链应用的发展产生了巨大的贡献。据 Etherscan 网站[数据显示](https://etherscan.io/tokens)，截止 2018 年 6 月 20 日，以太坊主网上 ERC20 Token 数量已超过 90000。下图是我们统计的 ERC20 每日创建数量趋势图。

![以太坊主网上 ERC20 合约每日创建数量](img/erc20-creation.jpeg)

### 智能合约重大安全事件列表

ERC20 Token 在其发展历程中，经历了逐渐成熟和完善的过程。其中有不少 ERC20 智能合约出现过重大漏洞，对项目方、投资人、交易所甚至整个以太坊社区造成难以估量的经济损失 [2-11]。

2016 年 6 月 18 日，针对 DAO 合约的攻击导致超过 3,600,000 个以太币 (ETH) 的损失，这些以太币以今天的市价计算总值超过 10 亿美元，这次攻击之后的以太坊硬分叉导致了以太坊社区的分裂 [[2]](https://medium.com/@pullnews/understanding-the-dao-hack-for-journalists-2312dd43e993)。

2018 年 4 月 22 日，黑客攻击了美链 (BEC) 的 Token 合约，通过一个整数溢出安全漏洞，将天量的 Token 砸向交易所，导致 BEC 的价格几乎归零 [[3]](https://medium.com/secbit-media/a-disastrous-vulnerability-found-in-smart-contracts-of-beautychain-bec-dbf24ddbc30e)。

2018 年 4 月 25 日，SMT 爆出类似的整数溢出漏洞，黑客通过漏洞制造和抛售了天文数字规模的 Token，导致 SMT 价格崩盘 [[4]](https://smartmesh.io/2018/04/25/smartmesh-announcement-on-ethereum-smart-contract-overflow-vulnerability/)。

2018 年 5 月 20 日，又是整数溢出漏洞导致任何人可以将任何用户的 EDU 账户转出，同时还有其它 3 个 Token 也出现了相同问题 [[5]](https://mp.weixin.qq.com/s/lf9vXcUxdB2fGY2YVTauRQ)。SECBIT 实验室对以太坊上所有的智能合约的进一步深入分析表明，至少有81个合约具有相同的漏洞 (CVE-2018–11397, CVE-2018–11398) [[6]](https://mp.weixin.qq.com/s/9FMt_TBSb9avL78KEAXHuA)。

2018 年 6 月 12 日，清华-360企业安全联合研究中心的张超教授团队又发现了一系列 ERC20 智能合约整数溢出漏洞 (CVE-2018-11687, CVE-2018-11809, CVE-2018-11810, CVE-2018-11811, CVE-2018-11812) [[7]](https://www.secrss.com/articles/3289)。SECBIT 实验室在对以太坊上已部署的 2 万多个合约的分析检测后，发现有 800 多个合约受到这些漏洞影响 [[8]](http://www.chaindd.com/3083754.html)。

### 众多 ERC20 Token 实现不规范

很多 Token 合约未参照 ERC20 标准实现，也给 DApp 开发带来很大的困扰 [12-14]。

数以千计的已部署 Token 合约参考了以太坊官网以及 OpenZeppelin 的错误模版代码，多个函数实现没有遵循 ERC20 规范，导致 Solidity 编译器升级至 0.4.22 后出现严重的兼容性问题，恐无法与去中心化交易所（DEX）和 DApp 完成正常转账 [[12]](https://medium.com/loopring-protocol/an-incompatibility-in-smart-contract-threatening-dapp-ecosystem-72b8ca5db4da)。而大多数的 DApp 开发团队对此了解甚少，也缺乏对该问题的安全警惕意识。

若干 Token 合约自行在标准 approve() 函数中添加了多余的对当前账户余额校验逻辑，要求授权的 _amount 小于或等于当前余额 [[13]](https://medium.com/secbit-media/redundant-check-in-erc20-smart-contracts-approve-5a675bb88261)。这导致采用类似 0x 协议的 DEX 无法正常提前完成 approve()，而需要 Token 项目方先行转账一笔数额巨大的 Token 至交易所中间账户，违背了 ERC20 标准设计的初衷，带来诸多不便。

由于 ERC20 规范中对几个通用查询接口如 name()、symbol()、decimals() 的要求为可选 [[1]](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md)，致使大量 Token 合约未提供这些接口，甚至不少采用 NAME()、SYMBOL()、DECIMALS() 等不一致的写法。这也直接加大了 DEX 和 DApp 的开发难度。

ERC20 标准中还规定了 Transfer 和 Approval 两个事件必须在特定场景下触发 [[1]](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md)。事实上，很多 Token 的实现参考了以太坊官网的不标准代码，漏掉实现 Approval 事件 [[14]](https://github.com/ethereum/ethereum-org/pull/865)。这对 DApp 生态发展也十分不利，开发者面对这些 Token 无法方便的监听相关事件。

### 应对之策之一：收集问题 Token 列表

来自安全组织和专家的统计和汇总同样表明目前智能合约中存在着触目惊心的安全问题，例如以下由 NCC Group 总结的智能合约中出现频率最高的10类安全问题 [[15]](https://www.dasp.co/)：

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

这些也许只是冰山一角，上述的最后一点以及最近的研究都表明，已经部署在以太坊上的智能合约存在的问题可能比大家想象的更加严重。

在此，我们对已知的漏洞和缺陷做了一个汇总，收录的 Token 问题类型主要包括：

1. Token 合约安全漏洞
2. 不符合 ERC20 规范导致的兼容问题
3. Token 合约管理员的权限过高 [[16]](https://medium.com/@peckshield/highly-manipulatable-erc20-tokens-identified-in-multiple-top-exchanges-including-binance-d158deab4b9a)

## 为何要维护一个 token list

在此之前，以太坊社区已有不少有助于智能合约生态发展的项目。如由 ConsenSys 维护的「以太坊智能合约 —— 最佳安全开发指南」[[17]](https://github.com/ConsenSys/smart-contract-best-practices)，以及由 OpenZeppelin 主导开发的 openzeppelin-solidity 安全智能合约代码库[[18]](https://github.com/OpenZeppelin/openzeppelin-solidity)。

而我们发现，实际中很多问题 Token 漏洞来源于不严谨的代码参考、拷贝和修改，以及使用了不正确的模版代码。智能合约初学者和开发者很难迅速判断一份主网合约代码是否存在问题以及具体存在哪些问题。

本项目通过维护一个 token list:

+ 列出常见的智能合约漏洞实例，为合约开发者提供学习细节素材
+ 列出问题 Token 合约，为基于 ERC20 的 DApp 开发者提供参考，提前规避问题 Token 引入的潜在安全风险
+ 便于交易所、项目方及 Token 投资者能够便利地查询到问题 Token，避免在交易中造成损失

## 项目主要包含内容

+ 常见安全漏洞描述
+ 已部署的漏洞合约 Token 列表
+ 不兼容的合约 Token 列表

## 项目各部分说明

```bash
awesome-buggy-erc20-tokens
├── TOKEN_DETAIL_DICT.json
├── bug-list.md
├── issues.json
├── badtop600token.csv
├── badtop600token.json
├── raw
├── csv
├── json
└── gen_list_from_raw.py
```

- [`TOKEN_DETAIL_DICT.json`](TOKEN_DETAIL_DICT.json) 收集了被 [CoinMarketCap](https://coinmarketcap.com/tokens/) 收录的 ERC20 合约主网地址和基本信息
- [`bug-list.md`](bug-list.md) 包含已知漏洞的详细描述
- [`issues.json`](issues.json) 是已知漏洞和代号编码的映射
- [`bad_top_tokens.csv`](bad_top_tokens.csv) 和 [`bad_top_tokens.json`](bad_top_tokens.json) 是问题 Token 的汇总列表，分别以 CSV 和 JSON 形式展示
- [`raw`](raw)、[`csv`](csv) 和 [`json`](json) 文件夹是各已知漏洞和受影响的合约地址，分别以纯文本、CSV、JSON 形式展示
- [`gen_list_from_raw.py`](gen_list_from_raw.py) 是生成各个 CSV 和 JSON 列表的脚本

如下所示，CSV 和 JSON 格式的列表，可以帮助开发者快速浏览和查询某合约地址存在哪些已知问题。

```csv
addr,category,name,symbol,info
0x093e5C256Ff8B32c7F1377f4C20e331674C77F00,[A2],Dignity,DIG,_
0x0aeF06DcCCC531e581f0440059E6FfCC206039EE,[B1],Intelligent Trading Technologies,ITT,_
0x0b76544F6C413a555F309Bf76260d1E02377c02A,[A2][A4][A6][B1],Internet Node Token,INT,_
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

## 如何参与贡献

我们希望通过此项目为以太坊生态做出一点贡献。

我们会长期维护此列表，并对其进行持续地更新。也欢迎大家共同参与进来，共同推进以太坊生态健康发展。

目前我们仅收录在 CoinMarketCap 有过市值显示的 Token 合约。如果你觉得我们有所遗漏，欢迎编辑 [`TOKEN_DETAIL_DICT.json`](TOKEN_DETAIL_DICT.json) 文件添加。

如果你发现了我们未收录的漏洞，欢迎按照以下流程贡献更新：

- 在 [`bug-list.md`](bug-list.md) 文件中添加漏洞名称和描述，附上引用出处地址
- 在 [`raw`](raw) 文件夹中创建以漏洞名称命名的新文件，填入受影响的合约地址
- 在 [`issues.json`](issues.json) 中增加新漏洞的名称和序列号
- 在项目根目录运行 `python3 gen_list_from_raw.py -i raw/* -o bad_top_tokens`
- 检查更改的文件，提交更新

如果你有其他任何问题或者想法，欢迎加入我们的 [Gitter](https://gitter.im/sec-bit/Lobby) 参与讨论。

## Reference

- [1] [ERC-20 Token Standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md), 
Nov 19, 2015
- [2] [Understanding The DAO Hack for Journalists](https://medium.com/@pullnews/understanding-the-dao-hack-for-journalists-2312dd43e993), Jun 19, 2016
- [3] [A disastrous vulnerability found in smart contracts of BeautyChain (BEC)](https://medium.com/secbit-media/a-disastrous-vulnerability-found-in-smart-contracts-of-beautychain-bec-dbf24ddbc30e), Apr 23, 2018
- [4] [SmartMesh Announcement on Ethereum Smart Contract Overflow Vulnerability](https://smartmesh.io/2018/04/25/smartmesh-announcement-on-ethereum-smart-contract-overflow-vulnerability/)
- [5] 智能合约红色预警：四个Token惊爆逻辑漏洞，归零风险或源于代码复制, https://mp.weixin.qq.com/s/lf9vXcUxdB2fGY2YVTauRQ
- [6] 围观！81个智能合约惊现同一漏洞，是巧合？还是另有玄机？, https://mp.weixin.qq.com/s/9FMt_TBSb9avL78KEAXHuA
- [7] ERC20智能合约整数溢出系列漏洞披露, https://www.secrss.com/articles/3289
- [8] 【得得预警】ERC20智能合约又现大量整数溢出漏洞, http://www.chaindd.com/3083754.html
- [9] [Alert! Another integer overflow vulnerability just found in HXG smart contract](https://medium.com/secbit-media/alert-another-integer-overflow-vulnerability-just-found-in-hxg-smart-contract-ff2f69fdd242), May 19, 2018
- [10] [UselessEthereumToken(UET), ERC20 token, allows attackers to steal all victim’s balances (CVE-2018–10468)](https://medium.com/coinmonks/uselessethereumtoken-uet-erc20-token-allows-attackers-to-steal-all-victims-balances-543d42ac808e), May 3, 2018
- [11] [Bugged Smart Contract FuturXE: How Could Someone Mess up with Boolean? (CVE-2018–12025)](https://medium.com/secbit-media/bugged-smart-contract-f-e-how-could-someone-mess-up-with-boolean-d2251defd6ff), Jun 6, 2018
- [12] [An Incompatibility in Ethereum Smart Contract Threatening dApp Ecosystem](https://medium.com/loopring-protocol/an-incompatibility-in-smart-contract-threatening-dapp-ecosystem-72b8ca5db4da), Jun 8, 2018
- [13] [Redundant Check in ERC20 Smart Contracts’ approve()](https://medium.com/secbit-media/redundant-check-in-erc20-smart-contracts-approve-5a675bb88261), Jun 15, 2018
- [14] [token-erc20: add event Approval to follow eip20](https://github.com/ethereum/ethereum-org/pull/865)
- [15] [DASP - Top 10 of 2018](https://www.dasp.co/)
- [16] [Highly-Manipulatable ERC20 Tokens Identified in Multiple Top Exchanges](https://medium.com/@peckshield/highly-manipulatable-erc20-tokens-identified-in-multiple-top-exchanges-including-binance-d158deab4b9a), Jun 9, 2018
- [17] [A guide to smart contract security best practices](https://github.com/ConsenSys/smart-contract-best-practices)
- [18] [OpenZeppelin, a framework to build secure smart contracts on Ethereum](https://github.com/OpenZeppelin/openzeppelin-solidity)

## 版权声明

[GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html)
