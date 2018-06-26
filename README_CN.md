# Awesome Buggy ERC20 Tokens
[![Join the chat at https://gitter.im/sec-bit/Lobby](https://badges.gitter.im/sec-bit/Lobby.svg)](https://gitter.im/sec-bit/Lobby)
[![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

以太坊 ERC20 智能合约风险问题及影响 Token 汇总

## 声明

- 本项目旨在通过收录已披露的智能合约漏洞，提升社区安全开发意识
- 本项目全部信息来源于公开资料，部分分析结果由程序自动生成，辅以人工校对
- 本项目收集的部分信息可能不准确，如有问题，请直接提交更改请求或联系我们更正
- 本项目不包含未公开漏洞
- 本项目中列出的 Token 名字或缩写可能会与知名项目重复，请勿过分解读
- 本项目中列出的部分 Token 仅存在不规范问题，并无致命漏洞
- 本项目中列出的部分问题 Token 项目方已采取措施妥善处理

## 快速提示

- 所有问题 Token 合约总表，请访问[`bad_tokens.all.csv`](bad_tokens.all.csv)
- 排名靠前的问题 Token 合约总表，请访问[`bad_tokens.top.csv`](bad_tokens.top.csv)
- 想了解各类合约漏洞细节讲解以及受影响 Token，请访问[`ERC20_token_issue_list_CN.md`](ERC20_token_issue_list_CN.md)
- 本项目列表正在持续更新，如有遗漏和误报，[欢迎指正](#如何参与贡献)

## 最近更新

- [2018-06-25, TFD, a16-custom-call-abuse](ERC20_token_issue_list_CN.md#a16-custom-call-abuse)
- 各 Token 列表中加入 totalSupply、decimals、已上交易所等信息
- [2018-06-23, ATN, a15-custom-fallback-bypass-ds-auth](ERC20_token_issue_list_CN.md#a15-custom-fallback-bypass-ds-auth)
- [2018-06-22, MORPH, a14-constructor-case-insentive](ERC20_token_issue_list_CN.md#a14-constructor-case-insentive)
- [2018-06-16, ICX, a11-pausetransfer-anyone](ERC20_token_issue_list_CN.md#a11-pausetransfer-anyone)
- [2018-06-12, PKT, a8-excess-mint-token-by-overflow](ERC20_token_issue_list_CN.md#a8-excess-mint-token-by-overflow)
- [2018-06-08, ITC, b1-transfer-no-return](ERC20_token_issue_list_CN.md#b1-transfer-no-return)

## ERC20 Token 面临的主要问题

以太坊 ERC20 Token 标准自 2015 年 11 月 19 日诞生以来 [[1]](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md)，为智能合约、以太坊生态以及区块链应用的发展产生了巨大的贡献。据 Etherscan 网站[数据显示](https://etherscan.io/tokens)，截止 2018 年 6 月 26 日，以太坊主网上 ERC20 Token 数量已超过 95000。下图是我们统计的 ERC20 每日创建数量趋势图。

![以太坊主网上 ERC20 合约每日创建数量](img/erc20-creation.jpeg)

### 智能合约重大安全事件列表

ERC20 Token 在其发展历程中，经历了逐渐成熟和完善的过程。其中有不少 ERC20 智能合约出现过重大漏洞，对项目方、投资人、交易所甚至整个以太坊社区造成难以估量的经济损失 [2-11]。

2016 年 6 月 18 日，针对 DAO 合约的攻击导致超过 3,600,000 个以太币 (ETH) 的损失，这些以太币以今天的市价计算总值超过 10 亿美元，这次攻击之后的以太坊硬分叉导致了以太坊社区的分裂 [[2]](https://medium.com/@pullnews/understanding-the-dao-hack-for-journalists-2312dd43e993)。

2018 年 4 月 22 日，黑客攻击了美链 (BEC) 的 Token 合约，通过一个整数溢出安全漏洞，将天量的 Token 砸向交易所，导致 BEC 的价格几乎归零 [[3]](https://medium.com/secbit-media/a-disastrous-vulnerability-found-in-smart-contracts-of-beautychain-bec-dbf24ddbc30e)。至少还有 10 份合约存在同样问题。

2018 年 4 月 25 日，SMT 爆出类似的整数溢出漏洞，黑客通过漏洞制造和抛售了天文数字规模的 Token，导致 SMT 价格崩盘 [[4]](https://smartmesh.io/2018/04/25/smartmesh-announcement-on-ethereum-smart-contract-overflow-vulnerability/)。至少还有 1 份合约存在同样问题。

2018 年 5 月 20 日，又是整数溢出漏洞导致任何人可以将任何用户的 EDU 账户转出，同时还有其它 3 个 Token 也出现了相同问题 [[5]](https://mp.weixin.qq.com/s/lf9vXcUxdB2fGY2YVTauRQ)。我们对以太坊上所有的智能合约的进一步深入分析表明，至少有81个合约具有相同的漏洞 (CVE-2018–11397, CVE-2018–11398) [[6]](https://mp.weixin.qq.com/s/9FMt_TBSb9avL78KEAXHuA)。

2018 年 6 月 12 日，一系列 ERC20 智能合约整数溢出漏洞 (CVE-2018-11687, CVE-2018-11809, CVE-2018-11810, CVE-2018-11811, CVE-2018-11812) 又被爆出 [[7]](https://www.secrss.com/articles/3289)。我们对以太坊上已部署的 2 万多个合约的分析检测后，发现有 800 多个合约受到这些漏洞影响 [[8]](http://www.chaindd.com/3083754.html)。

### 众多 ERC20 Token 实现不规范

很多 Token 合约未参照 ERC20 标准实现，也给 DApp 开发带来很大的困扰 [12-14]。

数以千计的已部署 Token 合约参考了以太坊官网以及 OpenZeppelin 的错误模版代码，多个函数实现没有遵循 ERC20 规范，导致 Solidity 编译器升级至 0.4.22 后出现严重的兼容性问题，恐无法与去中心化交易所（DEX）和 DApp 完成正常转账 [[12]](https://medium.com/loopring-protocol/an-incompatibility-in-smart-contract-threatening-dapp-ecosystem-72b8ca5db4da)。而大多数的 DApp 开发团队对此了解甚少，也缺乏对该问题的安全警惕意识。

若干 Token 合约自行在标准 `approve()` 函数中添加了多余的对当前账户余额校验逻辑，要求授权的 _amount 小于或等于当前余额 [[13]](https://medium.com/secbit-media/redundant-check-in-erc20-smart-contracts-approve-5a675bb88261)。这导致采用类似 0x 协议的 DEX 无法正常提前完成 `approve()`，而需要 Token 项目方先行转账一笔数额巨大的 Token 至交易所中间账户，违背了 ERC20 标准设计的初衷，带来诸多不便。

由于 ERC20 规范中对几个通用查询接口如 `name()`、`symbol()`、`decimals()` 的要求为可选 [[1]](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md)，致使大量 Token 合约未提供这些接口，甚至不少采用 `NAME()`、`SYMBOL()`、`DECIMALS()` 等不一致的写法。这也直接加大了 DEX 和 DApp 的开发难度。

ERC20 标准中还规定了 `Transfer` 和 `Approval` 两个事件必须在特定场景下触发 [[1]](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md)。事实上，很多 Token 的实现参考了以太坊官网的不标准代码，漏掉实现 `Approval` 事件 [[14]](https://github.com/ethereum/ethereum-org/pull/865)。这对 DApp 生态发展也十分不利，开发者面对这些 Token 无法方便的监听相关事件。

### 应对之策之一：收集问题 Token 列表

来自安全组织和专家的统计和汇总同样表明目前智能合约中存在着触目惊心的安全问题，例如以下由 NCC Group 总结的智能合约中出现频率最高的 10 类安全问题 [[15]](https://www.dasp.co/)：

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

1. Token 代码实现漏洞
2. 不符合 ERC20 规范导致的兼容问题
3. Token 合约权限管理问题 [[16]](https://medium.com/@peckshield/highly-manipulatable-erc20-tokens-identified-in-multiple-top-exchanges-including-binance-d158deab4b9a)

## 为何要维护一个 token list

在此之前，以太坊社区已有不少有助于智能合约生态发展的项目。如由 ConsenSys 维护的「以太坊智能合约 —— 最佳安全开发指南」[[17]](https://github.com/ConsenSys/smart-contract-best-practices)，以及由 OpenZeppelin 主导开发的 openzeppelin-solidity 安全智能合约代码库 [[18]](https://github.com/OpenZeppelin/openzeppelin-solidity)。

而我们发现，实际中很多问题 Token 漏洞来源于不严谨的代码参考、拷贝和修改，以及使用了不正确的模版代码。智能合约初学者和开发者很难迅速判断一份主网合约代码是否存在问题以及具体存在哪些问题。

本项目通过维护一个 token list:

+ 列出常见的智能合约漏洞实例，为合约开发者提供学习细节素材
+ 列出问题 Token 合约，为基于 ERC20 的 DApp 开发者提供参考，提前规避问题 Token 引入的潜在安全风险
+ 便于交易所、项目方及 Token 投资者能够便利地查询到问题 Token，避免在交易中造成损失

## 项目主要包含内容

+ 常见安全漏洞描述
+ 已部署的漏洞合约 Token 列表
+ 不规范的合约 Token 列表

## 项目各部分说明

```bash
awesome-buggy-erc20-tokens
├── token_dict.json
├── token_detail_dict.json
├── ERC20_token_issue_list_CN.md
├── issues.json
├── bad_tokens.all.csv
├── bad_tokens.all.json
├── bad_tokens.top.csv
├── bad_tokens.top.json
├── raw/
├── csv/
├── json/
├── gen_token_detail_dict.py
└── gen_list_from_raw.py
```

- [`token_dict.json`](token_dict.json) 收集了被 [CoinMarketCap](https://coinmarketcap.com/tokens/) 收录的 ERC20 合约主网地址和基本信息
- [`token_detail_dict.json`](token_detail_dict.json) 收集了被 [CoinMarketCap](https://coinmarketcap.com/tokens/) 收录的 ERC20 合约主网地址和详细信息
- [`ERC20_token_issue_list_CN.md`](ERC20_token_issue_list_CN.md) 包含已知漏洞的详细描述
- [`issues.json`](issues.json) 是已知漏洞和代号编码的映射
- [`bad_tokens.all.csv`](bad_tokens.all.csv) 和 [`bad_tokens.all.json`](bad_tokens.all.json) 是**所有**问题 Token 的汇总列表，分别以 CSV 和 JSON 形式展示
- [`bad_tokens.top.csv`](bad_tokens.top.csv) 和 [`bad_tokens.top.json`](bad_tokens.top.json) 是**市值排名靠前**的问题 Token 的汇总列表，分别以 CSV 和 JSON 形式展示
- [`raw/`](raw)、[`csv/`](csv) 和 [`json/`](json) 文件夹是各已知漏洞和受影响的合约地址，分别以纯文本、CSV、JSON 形式展示
- [`gen_token_detail_dict.py`](gen_token_detail_dict.py) 是生成 Token 详细信息列表的脚本
- [`gen_list_from_raw.py`](gen_list_from_raw.py) 是生成各个 CSV 和 JSON 列表的脚本

如下所示，CSV 和 JSON 格式的列表，可以帮助开发者快速浏览和查询某合约地址存在哪些已知问题。

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

## 如何参与贡献

我们会长期维护此列表，并对其进行持续地更新。也欢迎大家共同参与进来，共同推进以太坊生态健康发展。

目前我们仅维护被 CoinMarketCap 所收录 Token 合约的详细信息（totalSupply、decimals、exchanges）。如果你觉得我们有所遗漏，欢迎编辑 [`token_dict.json`](token_dict.json) 文件添加，并使用 [`gen_token_detail_dict.py`](gen_token_detail_dict.py) 脚本更新。

如果你发现了我们未收录的漏洞，欢迎按照以下流程贡献更新：

- 在 [`ERC20_token_issue_list_CN.md`](ERC20_token_issue_list_CN.md) 文件中添加漏洞名称和描述，附上引用出处地址
- 在 [`raw`](raw) 文件夹中创建以漏洞名称命名的新文件，填入受影响的合约地址
- 在 [`issues.json`](issues.json) 中增加新漏洞的名称和序列号
- 在项目根目录运行 `python3 gen_list_from_raw.py -i raw/* -o bad_tokens`
- 检查更改的文件，提交更新

如果你有其他任何问题或者想法，欢迎加入我们的 [Gitter](https://gitter.im/sec-bit/Lobby) 参与讨论。

## 技术合作

- Loopring https://loopring.io/
- Dex.top https://dex.top/

## Reference

- [1] [ERC-20 Token Standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md), Nov 19, 2015
- [2] [Understanding The DAO Hack for Journalists](https://medium.com/@pullnews/understanding-the-dao-hack-for-journalists-2312dd43e993), Jun 19, 2016
- [3] [A disastrous vulnerability found in smart contracts of BeautyChain (BEC)](https://medium.com/secbit-media/a-disastrous-vulnerability-found-in-smart-contracts-of-beautychain-bec-dbf24ddbc30e), Apr 23, 2018
- [4] [SmartMesh Announcement on Ethereum Smart Contract Overflow Vulnerability](https://smartmesh.io/2018/04/25/smartmesh-announcement-on-ethereum-smart-contract-overflow-vulnerability/)
- [5] [SECBIT: 智能合约红色预警--四个Token惊爆逻辑漏洞，归零风险或源于代码复制](https://mp.weixin.qq.com/s/lf9vXcUxdB2fGY2YVTauRQ), May 24, 2018
- [6] [SECBIT: 围观！81个智能合约惊现同一漏洞，是巧合？还是另有玄机？](https://mp.weixin.qq.com/s/9FMt_TBSb9avL78KEAXHuA), Jun 3, 2018
- [7] [清华-360企业安全联合研究中心：ERC20智能合约整数溢出系列漏洞披露](https://www.secrss.com/articles/3289), Jun 12, 2018
- [8] [【得得预警】ERC20智能合约又现大量整数溢出漏洞](http://www.chaindd.com/3083754.html), Jun 12, 2018
- [9] [Alert! Another integer overflow vulnerability just found in HXG smart contract](https://medium.com/secbit-media/alert-another-integer-overflow-vulnerability-just-found-in-hxg-smart-contract-ff2f69fdd242), May 19, 2018
- [10] [UselessEthereumToken(UET), ERC20 token, allows attackers to steal all victim’s balances (CVE-2018–10468)](https://medium.com/coinmonks/uselessethereumtoken-uet-erc20-token-allows-attackers-to-steal-all-victims-balances-543d42ac808e), May 3, 2018
- [11] [Bugged Smart Contract FuturXE: How Could Someone Mess up with Boolean? (CVE-2018–12025)](https://medium.com/secbit-media/bugged-smart-contract-f-e-how-could-someone-mess-up-with-boolean-d2251defd6ff), Jun 6, 2018
- [12] [An Incompatibility in Ethereum Smart Contract Threatening dApp Ecosystem](https://medium.com/loopring-protocol/an-incompatibility-in-smart-contract-threatening-dapp-ecosystem-72b8ca5db4da), Jun 8, 2018
- [13] [Redundant Check in ERC20 Smart Contracts’ approve()](https://medium.com/secbit-media/redundant-check-in-erc20-smart-contracts-approve-5a675bb88261), Jun 15, 2018
- [14] [token-erc20: add event Approval to follow eip20](https://github.com/ethereum/ethereum-org/pull/865)
- [15] [DASP - Top 10 of 2018](https://www.dasp.co/)
- [16] [PeckShield: Highly-Manipulatable ERC20 Tokens Identified in Multiple Top Exchanges](https://medium.com/@peckshield/highly-manipulatable-erc20-tokens-identified-in-multiple-top-exchanges-including-binance-d158deab4b9a), Jun 9, 2018
- [17] [A guide to smart contract security best practices](https://github.com/ConsenSys/smart-contract-best-practices)
- [18] [OpenZeppelin, a framework to build secure smart contracts on Ethereum](https://github.com/OpenZeppelin/openzeppelin-solidity)
- [19] [360 0KEE Team: 以太坊智能合约Hexagon存在溢出漏洞](https://www.jianshu.com/p/c5363ffad6a7), May 18, 2018
- [20] [慢雾科技：ATN 披露特殊场景下的以太坊合约重大漏洞](https://mp.weixin.qq.com/s/S5Oq4TxxW5OgEkOmy8ZSzQ), Jun 20, 2018
- [21] [BCSEC: 一些智能合约存在笔误，一个字母可造成代币千万市值蒸发！](https://bcsec.org/index/detail?id=157), Jun 22, 2018
- [22] [链安科技：小心！智能合约再爆高危漏洞，两大加密货币直接变废纸！](https://mp.weixin.qq.com/s/qDTrZPy5f4_-V2F4DpzoNA), Jun 6, 2018
- [23] [PeckShield: New allowAnyone Bug Identified in Multiple ERC20 Smart Contracts](https://medium.com/@peckshield/new-allowanyone-bug-identified-in-multiple-erc20-smart-contracts-20d935b5e7ff), May 23, 2018

## 版权声明

[![CC0](http://mirrors.creativecommons.org/presskit/buttons/88x31/svg/cc-zero.svg)](https://creativecommons.org/publicdomain/zero/1.0/)
