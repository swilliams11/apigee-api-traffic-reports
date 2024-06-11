import fileinput
import sys


def find_and_replace(filename, *values):
    """
    Searches the file for the list of strings that need to be replaced.
    Strings that need to be replace should have double underscore as the prefix and suffix.
    i.e. __PROJECT__ __REGION__
    """
    find_replace_list = []
    for item in values:
        old_new_values = item.split(":")
        old_value = old_new_values[0]
        new_value = old_new_values[1]
        find_replace_list.append({ "find_string": old_value, "replacement_string": new_value})
    print(find_replace_list)
    
    # search every line in the file
    with fileinput.FileInput(filename, inplace=True) as file:
        for line in file:
            # check for the original string to be replaced
            if find_replace_list[0]["find_string"] in line or find_replace_list[1]["find_string"] in line:
                new_line = replace_all_items_in_line(line, find_replace_list)
                print(new_line, end='')    
            else:
                print(line, end='')


def replace_all_items_in_line(line:str, find_replace_list:list):
    new_line = line
    for item in find_replace_list:
        new_line = new_line.replace(item["find_string"], item["replacement_string"])
    return new_line

# TODO - update this to pass all arguments
if __name__ == '__main__':
    if len(sys.argv) < 4:
        print("Usage: python find_replace.py <filename> <old_value>:<new_value> <old_value>:<new_value> ...")
    else:
        find_and_replace(sys.argv[1], sys.argv[2], sys.argv[3])