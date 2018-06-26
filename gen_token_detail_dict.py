"""
Use this script to generate token detail dict as token_detail_dict.json

Workflow:

1. Add token in token_dict.json (token name and coinmarketcap name needed)
2. Run `python3 gen_token_detail_dict.py`
3. Check token_detail_dict.json (token info grabbed from etherscan and coinmarketcap)

This script needs several packages.
`pip3 install web3 lxml scrapy` before use.

Example in token_dict.json:

"0x1A0F2aB46EC630F9FD638029027b552aFA64b94c": {
    "name": "Aston X",
    "cmcName": "aston"
}

- checksum of token address must be correct
- name should be accurate
- cmcName is derived from cmc url (https://coinmarketcap.com/currencies/aston/)
"""
from web3 import Web3
import json
import logging
import requests
from lxml import html
from scrapy.selector import Selector
import copy
import time


def get_token_info(url, addr, cnt):
    try:
        logging.info("DL %s" % url)
        page = requests.get(url)
        tree = html.fromstring(page.text)

        real_addr = tree.xpath('//*[(@id = "ContentPlaceHolder1_trContract")]//a')[0].text.strip()
        total_supply_content = tree.xpath('//*[contains(concat( " ", @class, " " ), concat( " ", "tditem", " " ))]')[0]\
            .text.strip().split(" ")

        symbol = "_"
        total_supply = total_supply_content[0]
        if len(total_supply_content) > 1:
            symbol = total_supply_content[1]

        selector = Selector(text=page.text)
        content = selector.css('#ContentPlaceHolder1_trContract+ tr td+ td').extract()[0].strip()
        decimals = content.replace("<td>", "").replace("</td>", "").replace('\n', "")

        ex_spans = selector.css("#tokenExchange div+ span").extract()
        exs = []
        for ex_span in ex_spans:
            exs.append(ex_span.split('<span style="margin:2px;">')[1].split('</span>')[0])

        if len(exs) > 0:
            exs = sorted(dict.fromkeys(exs).keys())
        else:
            try:
                if TOKEN_DICT[addr]['cmcName'] != "":
                    cmc_addr = f"https://coinmarketcap.com/currencies/{TOKEN_DICT[addr]['cmcName']}/"
                    print("CMC DL %s" % cmc_addr)
                    page = requests.get(cmc_addr)
                    selector = Selector(text=page.text)
                    ex_list = selector.css(".link-secondary").extract()
                    for ex_attr in ex_list:
                        exs.append(ex_attr.split('</a>')[0].split('">')[1])
                    if len(exs) > 0:
                        exs = sorted(dict.fromkeys(exs).keys())
            except KeyError as err:
                print("KeyError: ", err)

        print(f"cnt: {cnt}, real_addr: {real_addr}, total_supply: {total_supply},"
              f" decimals: {decimals}, symbol: {symbol}, exchanges: {exs}")

        total_supply = total_supply.replace(",", "")

        if addr not in TOKEN_DETAIL_DICT_NEW:
            TOKEN_DETAIL_DICT_NEW[addr] = {"name": TOKEN_DICT[addr]['name']}

        try:
            TOKEN_DETAIL_DICT_NEW[addr]['totalSupply'] = int(total_supply)
        except ValueError as err:
            TOKEN_DETAIL_DICT_NEW[addr]['totalSupply'] = int(0)
            print(f"{addr} wrong totalSupply, err: {err}")

        TOKEN_DETAIL_DICT_NEW[addr]['decimals'] = int(decimals)
        TOKEN_DETAIL_DICT_NEW[addr]['exchanges'] = exs

        if symbol != "_":
            TOKEN_DETAIL_DICT_NEW[addr]['symbol'] = symbol
        time.sleep(0.08)

    except Exception as err:
        logging.error('DL %s [FAILED][%s]' % (url, str(err)))


with open('token_dict.json', 'r') as f:
    TOKEN_DICT = json.load(f)
    print("token_dict.json loaded.")

with open('token_detail_dict.json', 'r') as f:
    TOKEN_DETAIL_DICT = json.load(f)
    print("token_detail_dict.json loaded.")


TOKEN_DETAIL_DICT_NEW = copy.deepcopy(TOKEN_DETAIL_DICT)
cnt = 0

TOKEN_DICT_NEW = {}
append_cnt = 0
for addr in TOKEN_DICT:
    addr = Web3.toChecksumAddress(addr)
    if addr not in TOKEN_DETAIL_DICT:
        token_url = "https://etherscan.io/token/" + addr
        get_token_info(token_url, addr, cnt)
        append_cnt += 1
    cnt += 1

with open('token_detail_dict.json', 'w') as outfile:
    json.dump(TOKEN_DETAIL_DICT_NEW, outfile, indent=4)

print(f"Append done! token_detail_dict.json saved. ({append_cnt} new)")
