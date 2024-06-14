# DnsSimpleBench

DnsSimpleBench is a shell script that performs a **basic** DNS benchmark. 
It is not intended to compete with existing sophisticated tools. It is 
intended to provide a quick check. If you wish to perform extensive DNS 
performance checks look at the more sophisticated tools.

The script assumes that you run the script in the directory that holds
the script and the configuration files.

You may have to increase the width of your terminal to ensure that 
the output is displayed clearly.

Here is an example run (**NOTE** - the output presented below is wide).

```
$ ./DnsCheck.sh 
-----------------+-----------------+-----------------+-----------------+-----------------+
Domain           |LOCAL            |CloudFlare       |Google           |Quad 9           |
-----------------+-----------------+-----------------+-----------------+-----------------+
google.com       |0 msec           |16 msec          |16 msec          |16 msec          |
amazon.com       |0 msec           |12 msec          |20 msec          |16 msec          |
nominet.uk       |0 msec           |16 msec          |36 msec          |12 msec          |
reddit.com       |0 msec           |12 msec          |20 msec          |16 msec          |
www.welt.de      |0 msec           |20 msec          |20 msec          |16 msec          |
bbc.co.uk        |24 msec          |72 msec          |20 msec          |12 msec          |
qors49ci.j       |36 msec          |16 msec          |16 msec          |12 msec          |
-----------------+-----------------+-----------------+-----------------+-----------------+
$ 
```

## Install

Clone this repository into a directory on your system.

## Execution

Change to the directory that holds your repo clone. Ensure that the shell
script is executable. Run the shell script.

## Elements

There are three components of the tool:

* the Bash shell script `DnsSimpleBench.sh`
* the JSON configuration file `dns_servers.json` defines the DNS servers that are to be tested
* the plain text configuration file `domains.txt` defines the DNS domains that are to be
queried.

The shell script reads the 2 configuration files, it iterates over the test 
domains, querying the domain, extracting the time required to perform the query
using `dig` against each of the DNS defined in the JSON configuration file.

The script creates an additional domain name from random characters. This is used
 to test performance of domains are not in the DNS server's cache.

### Shell script

The script does not require elevated privileges. 

The requires that the tools`dig` and `jq` are installed.

The script uses a Bash associative array as well as a standard array. The 
script therefore requires Bash version 4.4 or higher.

This script has been tested on Ubuntu 22.04 and Alma 9.1 with the required 
tools installed. This script has only been tested with the Bash shell.

The user can change both the DNS servers and test domains. If you have a large
 number of DNS servers you should ensure that your terminal window is wide 
 enough to display the output clearly.

The testing of this script has been limited to 6 domains and DNS. It should be
possible to use greater numbers of both, but 
_**when Bash limits are encountered the script will fail ungracefully**_.

The script was only tested with DNS servers with IPv4 addresses. The ISP I use
does not support IPv6.

This script has only been tested with DNS services with "ASCII" names.

If you run this script more than once, all the target domains will have been
loaded into the DNS servers' cache.

This script has been "linted" with  ShellCheck v0.8.0. No errors or warnings
were reported.

### DNS server configuration file

The file `dns_servers.json`` is set of key-value pairs in JSON format with
the name of the DNS service as the key and primary IPv4 address of the service
as the value.

```
# Example:
{
    "Google": "8.8.8.8",
    "CloudFlare": "1.1.1.1"
}
```

If the output has a single column for the local DNS, it is likely there is a
syntax error in this file.

An example of a larger DNS server configuration file is also provided
in the repository `LARGE_dns_servers.json`.

### Test domains configuration file

The file `domains.txt` is plain text file that defines the set of existing
domains that the script will use. This file contains a list of domains,
one per line:

```
google.com
amazon.com
reddit.com
www.welt.de
```

