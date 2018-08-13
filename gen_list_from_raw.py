# -*- coding: utf-8 -*-
""" 
Use this script to generate token list in csv/json folder

Workflow:

1. Edit data in raw folder
2. Run `python3 gen_list_from_raw.py -i raw/* -o bad_tokens`
3. Check output files: *.json *.csv

This script needs web3 package.
`pip3 install web3` before use.
"""
from web3 import Web3
import json
import argparse
import copy

ap = argparse.ArgumentParser()
ap.add_argument("-i", "--input", nargs='+', required=True, help="input file")
ap.add_argument("-o", "--output", required=True, help="final output file")

args = vars(ap.parse_args())


input_files = args["input"]
final_output = args["output"]

with open('token_detail_dict.json', 'r') as f:
    TOKEN_DETAIL_DICT = json.load(f)
    print("token_detail_dict.json loaded.")

with open('issues.json', 'r') as f:
    issue_dict = json.load(f)
    print("issues.json loaded.")

csv_header = "addr,category,name,symbol,exchanges,totalSupply,decimals,info\n"

write_csv = True


def export_data(output_file, data_dict):
    csv_saved = output_file + ".o.csv"
    csv = open("./csv/" + csv_saved, 'w', encoding = 'utf-8')
    csv.write(csv_header)
    for addr in data_dict:
        detail = data_dict[addr]
        name, symbol, exchanges, totalSupply, decimals = "", "", "", "", ""
        if 'name' in detail:
            name = detail['name']
        if 'symbol' in detail:
            symbol = detail['symbol']
        if 'exchanges' in detail:
            exs = detail['exchanges']
        if 'totalSupply' in detail:
            totalSupply = detail['totalSupply']
        if 'decimals' in detail:
            decimals = detail['decimals']
        if 'exchanges' in detail:
            exs = detail['exchanges']
            for ex in exs:
                exchanges += f"@{ex}"
        result = f"{addr},{issue_type},{name},{symbol},{exchanges},{totalSupply},{decimals},_\n"
        csv.write(result)
    csv.close()
    print("---\nsave to %s\n---" % csv_saved)

    json_saved = output_file + ".o.json"
    with open("./json/" + json_saved, 'w') as outfile:
        json.dump(data_dict, outfile, sort_keys=True, indent=4)
    print("---\nsave to %s\n---" % json_saved)


def export_data_summary(output_file, data_dict):
    csv_saved = output_file + ".csv"
    csv = open("./" + csv_saved, 'w', encoding = 'utf-8')
    csv.write(csv_header)
    for addr in data_dict:
        detail = data_dict[addr]
        name, symbol, exchanges, totalSupply, decimals = "", "", "", "", ""
        if 'name' in detail:
            name = detail['name']
        if 'symbol' in detail:
            symbol = detail['symbol']
        issues = []
        if 'issues' in detail:
            issues = detail['issues']
        if 'totalSupply' in detail:
            totalSupply = detail['totalSupply']
        if 'decimals' in detail:
            decimals = detail['decimals']
        if 'exchanges' in detail:
            exs = detail['exchanges']
            for ex in exs:
                exchanges += f"@{ex}"
        issue_list = []
        for issue in issues:
            issue_list.append(issue_dict[issue])
        issue_list.sort()
        category = ""
        for issue in issue_list:
            category += f"[{issue}]"
        result = f"{addr},{category},{name},{symbol},{exchanges},{totalSupply},{decimals},_\n"
        csv.write(result)
    csv.close()
    print("---\nsummary save to %s\n---" % csv_saved)

    json_saved = output_file + ".json"
    with open("./" + json_saved, 'w') as outfile:
        json.dump(data_dict, outfile, sort_keys=True, indent=4)
    print("---\nsummary save to %s\n---" % json_saved)


cnt = 0
TOP_ONLY_ALL_IN_ONE_DICT = {}
ALL_IN_ONE_DICT = {}

for input_file in input_files:
    FINAL_DICT = {}
    TOP_ONLY_FINAL_DICT = {}
    issue_type = input_file.split('.')[0].replace("raw/", "")
    print("issue_type:", issue_type)
    with open(input_file) as f:
        for line in f:
            addr = line.split('_')[0].strip('\n')
            if addr == "":
                continue
            try:
                addr = Web3.toChecksumAddress(addr)
            except Exception as err:
                print(f"Web3.toChecksumAddress failed, check raw input in {input_file}, err = {err}, addr = {addr}")
                exit()

            if addr in TOKEN_DETAIL_DICT:
                token_detail = copy.deepcopy(TOKEN_DETAIL_DICT[addr])
                # print("addr in top token:", addr, "detail:", token_detail)
                
                TOP_ONLY_FINAL_DICT[addr] = token_detail
                name = token_detail['name']
                symbol = token_detail['symbol']
                token_detail['info'] = "_"
                token_detail['issues'] = {issue_type: True}
                cnt += 1
                # print(f"{cnt}: {addr},{issue_type},{name},{symbol},_")

                FINAL_DICT[addr] = TOP_ONLY_FINAL_DICT[addr]

                try:
                    old_issues = TOP_ONLY_ALL_IN_ONE_DICT[addr]['issues']
                    TOP_ONLY_ALL_IN_ONE_DICT[addr]['issues'] = {**old_issues, **token_detail['issues']}
                except KeyError:
                    TOP_ONLY_ALL_IN_ONE_DICT[addr] = token_detail

                try:
                    old_issues = ALL_IN_ONE_DICT[addr]['issues']
                    ALL_IN_ONE_DICT[addr]['issues'] = {**old_issues, **token_detail['issues']}
                except KeyError:
                    ALL_IN_ONE_DICT[addr] = token_detail

            else:
                FINAL_DICT[addr] = {'issues': {issue_type: True}}

                try:
                    old_issues = ALL_IN_ONE_DICT[addr]['issues']
                    ALL_IN_ONE_DICT[addr]['issues'] = {**old_issues, **FINAL_DICT[addr]['issues']}
                except KeyError:
                    ALL_IN_ONE_DICT[addr] = {'issues': {issue_type: True}}

    FINAL_DICT_SORTED = dict(sorted(FINAL_DICT.items(), key=lambda x: x[0]))
    export_data(issue_type, FINAL_DICT_SORTED)

TOP_ONLY_ALL_IN_ONE_DICT_SORTED = dict(sorted(TOP_ONLY_ALL_IN_ONE_DICT.items(), key=lambda x: x[0]))
export_data_summary(final_output + ".top", TOP_ONLY_ALL_IN_ONE_DICT_SORTED)

ALL_IN_ONE_DICT_SORTED = dict(sorted(ALL_IN_ONE_DICT.items(), key=lambda x: x[0]))
export_data_summary(final_output + ".all", ALL_IN_ONE_DICT_SORTED)