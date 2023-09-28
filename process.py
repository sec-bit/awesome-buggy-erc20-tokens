import os
import csv


# Read all csv files in ./csv folder and save them in a list
csv_files = []
for file in os.listdir('./csv'):
    if file.endswith('.csv'):
        csv_files.append(file)

# Save list of files to a list variable
contracts_list = os.listdir('./contracts')

# For each csv file, create a folder with the same name under ./result
for file in csv_files:
    file_name = file.split('.')[0]
    folder_name = './result/' + file_name
    if not os.path.exists(folder_name):
        os.makedirs(folder_name)

    # Read the first column and save into a list variable
    csv_file = open('./csv/' + file, 'r')
    reader = csv.reader(csv_file)
    first_column = []
    for row in reader:
        first_column.append(row[0])
    csv_file.close()

    # For each item in the first column, copy the corresponding file from ./contracts to the folder
    for item in first_column:
        item_name = item.split('/')[-1]

        # copy the file starting with item_name from ./contracts to the folder. Ignore case.
        for contract_file in contracts_list:
            if contract_file.lower().startswith(item_name.lower()):
                os.system('cp ./contracts/' + contract_file + ' ' + folder_name)
                break

        else:
            print('Error: ' + item_name + ' not found in ./contracts')