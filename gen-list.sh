curl -s 'https://publicsuffix.org/list/public_suffix_list.dat' > list.list
crystal generate.cr -- list.list > ./src/public_suffix/generated_list.cr
