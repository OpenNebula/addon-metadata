# addon-metadata - Metadata server for OpenNebula

## DESCRIPTION

This addon is a metadata server, compatible with EC2, 
for the OpenNebula Cloud Toolkit.

## Development

To contribute bug patches or new features, you can use the github Pull Request model. It is assumed that code and documentation are contributed under the Apache License 2.0. 

More info:
* [How to Contribute](http://opennebula.org/software:add-ons#how_to_contribute_to_an_existing_add-on)
* Support: [OpenNebula user mailing list](http://opennebula.org/community:mailinglists)
* Development: [OpenNebula developers mailing list](http://opennebula.org/community:mailinglists)
* Issues Tracking: Github issues (https://github.com/OpenNebula/addon-metadata/issues)

## Authors

* Ricardo Duarte (ricardo.duarte@outlook.com)

## Compatibility

This add-on is compatible with OpenNebula 3.8, 4.0, 4.2, 4.4.
Tested extensively with 4.4 (EC2)

## INSTALLATION

### REQUISITES

OpenNebula Server installation is required.

### INSTALLATION

The installation script assumes OpenNebula is installed system-wide.
To install, run the following script:

    $ ./install.sh

An init script is provided for Debian based distributions.

### REDIRECT TO 169.254.169.254:80

To comply with EC2, the metadata server should be available from 
http://169.254.169.254:80.
To enable this either:

- Setup a redirect rule on the default gateway
- Setup a redirect on each host, using iptables

#### REDIRECT ON DEFAULT GATEWAY

This is out of scope for this document

#### REDIRECT USING IPTABLES

The rp_filter must be disabled for each cloud interface/bridge.
To do so, add a line to /etc/sysctl.conf for each interface:
```
net.ipv4.conf.<interface_name>.rp_filter = 0
```
If using bridges, the following line must also be added/modified:
```
net.bridge.bridge-nf-call-iptables = 1
```
On each host, run the following at startup (ex.: using rc.local):
```
iptables -t nat -A PREROUTING -d 169.254.169.254/32 -p tcp -m tcp --dport 80 -j DNAT --to-destination <metadata_server_ip>:<metadata_server_port>
```

### CONTEXT

The metadata server was thought to work with instances launched by eucatools, hybridfox or econe-* , and assumes that you are using the standard /etc/one/ec2query_templates/*.erb .
If a custom template is to be used, add the folowing context variables:
```
CONTEXT         = [
  (...)
    EC2_USER_DATA = <YOUR USER DATA>
    EC2_PUBLIC_KEY = <YOUR PUBLIC KEY>
    EC2_KEYNAME = <THE NAME OF THE KEY>
  ]
```
If there is the need to use other variables instead, just change them on /usr/lib/one/ruby/cloud/metadata/MetadataServer.rb.
Search and replace with your own data:
```
  TEMPLATE/CONTEXT/EC2_KEYNAME
  TEMPLATE/CONTEXT/EC2_PUBLIC_KEY
  TEMPLATE/CONTEXT/EC2_USER_DATA
```

### TEST

To test the metadata server, download and run the EC2 Instance Metadata Query Tool tool from inside an instance.
The EC2 Instance Metadata Query Tool tool is available 

    http://aws.amazon.com/code/1825

## CONTACT

Ricardo Duarte (ricardo.duarte@outlook.com)

## COPYRIGHT

Copyright 2014, Ricardo Duarte (ricardo.duarte@outlook.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

