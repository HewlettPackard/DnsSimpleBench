#!/usr/bin/env bash

################################################################################
# Copyright 2023-2024 Hewlett Packard Enterprise Development LP
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy 
# of  this software and associated documentation files (the “Software”), to 
# deal in the Software without restriction, including without limitation the 
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies  of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in 
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
# OTHER DEALINGS IN THE SOFTWARE.
################################################################################
 
 
 
###############################################################################
# Bash script to do a basic benchmark multiple DNS against specified domains 
# and a randomly generated probably non-existent domain.
#
# The target DNS and domains are defined in configuration files.
#
# See the README.md file for more information
###############################################################################


# Find the location of the jq tool. Terminate if it is not found.
JQ=$(which jq)
if [ -z "${JQ}" ]
then
    echo "Cannot find the tool jq. Terminating"
    exit 2
fi

# Find the location of the tool dig. Terminate if it is not found.
DIG=$(which dig)
if [ -z "${DIG}" ]
then
    echo "Cannot find the tool dig. Terminating"
    exit 3
fi


# Create a an associative array to hold the key-value defined in the JSON public 
# DNS configuration. The key is the DNS name and value is the IP address.
declare -A publicDnsServers



# Add a placeholder value for the locally defined DNS with the key "LOCAL".
# Add the placeholder DNS name as the first value in the list of DNS names.
# Using a list of DNS names permits the script to have the local DNS as the
# column in the output.
publicDnsServers["LOCAL"]+="PLACEHOLDER"
dnsServersList=("LOCAL")

# Read the key-value pairs from the configuration file. The key and value
# are written to the associative array. The key is appended to the list
# of DNS server names.
while IFS="=" read -r key value
do
    publicDnsServers[$key]="$value"
    dnsServersList+=("$key")
done < <(${JQ} -r "to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]" ./dns_servers.json)


# Load the list of test domains from the plain text file ./domains.txt.
mapfile -t domains < ./domains.txt


# Create a random domain name and add it to array of test domains.
# This random TLD (NEDOMIAN) is unlikely to exist and therefore will
# not be present in the cache of the target DNS servers.
#
# Ensure that the random hostname is at least 6 lower-case ASCII characters
# and the random TLD is at least 3 lower-case ASCII characters.
#
# The prefix NE indicates non-existant.

NE_HOST=""
while [[ ${#NE_HOST} -lt 6 ]]
do
    NE_HOST="$(dd if=/dev/urandom bs=32 count=1 2> /dev/null  | tr -dc '[:lower:]')"
done

NE_TLDR=""
while [[ ${#NE_TLDR} -ne 3 ]]
do
    NE_TLDR=$(dd if=/dev/urandom bs=8 count=1 2> /dev/null  | tr -dc '[:lower:]')
done
NEDOMAIN="${NE_HOST}.${NE_TLDR}"
domains[${#domains[@]}]="$NEDOMAIN"

# Create a column divider and header to match the number of public DNSs plus
# the local DNS.

# These string constants are used to format the results into a table.
SPACES="                 "
DASHES="-----------------+"
DOM_SPACES="                 "

#  Populate the first column
div="${DASHES}"
LABEL="Domain"
header=$(printf "%s%s" "${LABEL}" "${DOM_SPACES:${#LABEL}}|")

# Populate the rest of the header line and the divider.
# This is done dynamically based on the number of DNS
# server targets defined in the DNS JSON config file.
for item in "${dnsServersList[@]}"
do
    entry=$(printf "%s%s" "${item}" "${SPACES:${#item}}")
    header="${header}${entry}|"
    div="${div}${DASHES}"
done


# Print the column header including the name of each DNS.
echo "${div}"
echo "${header}"
echo "${div}"

# Iterate over the target domains defined in the environment variable "domains".
#
# Print the name of the target domain, followed by "|" used as a column divider.
# The use of DOM_SPACES ensures a consistent left padded column width.
#
# Within each loop iterate over the list of target DNS servers, "dnsServersList".
#
# For each combination of target domain and DNS server run the dig command and
# extract how long the command took to complete.
#
# Print the time that the dig query took. The use of the SPACES ensures a consistent
# left padded column width. This is followed by "|" used as column divider
# 
# The result is a formatted table of the test results with the results of the queries
# against a single target DNS servers in a single column and results against each test 
# domain in a row.
for domain in "${domains[@]}"
do
    # Print the name of the target domain followed by "|" as column divider.
    entry=$(printf "%s%s" "${domain}" "${DOM_SPACES:${#domain}}")
    echo -ne "${entry}|"

    for dnsServerName in "${dnsServersList[@]}"
    do
        # Initially an empty string was used as the value for
        # LOCAL entry, problems were encountered on Alma 9.1.
        #
        # The output of the $DIG command is munged to extract the time required
        # to complete the DNS in the form of the number of units and time unit.
        querytime=""
        if [ "${dnsServerName}" = "LOCAL" ]
        then
            querytime=$(${DIG} +noall +stats +time=9 "${domain}" 2>&1| grep "Query time" | tail -1 | cut -d\  -f4,5)
        else
            service="@${publicDnsServers[$dnsServerName]}"
            querytime=$(${DIG} +noall +stats +time=9 "${service}" "${domain}" 2>&1| grep "Query time" | tail -1 | cut -d\  -f4,5)
        fi

        # Format the time required to complete the query into a consistent
        # left padded length and print the result followed by the column delimiter.
        entry=$(printf "%s%s" "${querytime}" "${SPACES:${#querytime}}")
        echo -ne "${entry}|"
    done
    echo ""
done

echo "${div}"