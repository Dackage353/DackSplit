import csv
import os
from string import Template

output_directory = 'output'

def write_output(file_name, output):
    os.makedirs(output_directory, exist_ok=True)
    file_path = os.path.join(output_directory, file_name)

    with open(file_path, 'w', encoding='utf-8') as output_file:
        output_file.write(output)


if __name__ == '__main__':
    with open('standard.tmpl', encoding='utf-8') as file:
        standard = Template(file.read())

    with open('aglab_igt.tmpl', encoding='utf-8') as file:
        aglab_igt = Template(file.read())

    with open('addresses.csv', newline='', encoding='utf-8') as file:
        for row in csv.DictReader(file):
            file_name = f"AutoSplitter for {row['name']} ({row['version']}).asl"

            if row['type'] == 'standard':
                output = standard.substitute(**row)

            elif row['type'] == 'aglab igt':
                output = aglab_igt.substitute(**row)

            else:
                continue

            write_output(file_name, output)