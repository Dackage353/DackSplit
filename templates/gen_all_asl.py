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

    with open('standard_debug.tmpl', encoding='utf-8') as file:
        standard_debug = Template(file.read())

    with open('aglab_igt.tmpl', encoding='utf-8') as file:
        aglab_igt = Template(file.read())

    with open('aglab_igt_debug.tmpl', encoding='utf-8') as file:
        aglab_igt_debug = Template(file.read())

    with open('addresses.csv', newline='', encoding='utf-8') as file:
        for row in csv.DictReader(file):
            main_file_name = f"AutoSplitter for {row['name']} ({row['version']}).asl"
            reader_file_name = f"Debug for {row['name']} ({row['version']}).asl"

            if row['type'] == 'standard':
                write_output(main_file_name, standard.substitute(**row))
                write_output(reader_file_name, standard_debug.substitute(**row))

            elif row['type'] == 'aglab igt':
                write_output(main_file_name, aglab_igt.substitute(**row))
                write_output(reader_file_name, aglab_igt_debug.substitute(**row))