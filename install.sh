# -------------------------------------------------------------------------- #
# Copyright 2012, Ricardo Duarte (ricardo.duarte@outlook.com)                #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

if [ ! -d "/usr/lib/one/ruby/cloud/" ]; then
  echo "OpenNebula is not installed"
  exit
fi


echo "Installing OpenNebula Metadata Server..."

mkdir -p /usr/lib/one/ruby/cloud/metadata
mkdir -p /etc/one
cp etc/metadata.conf /etc/one/metadata.conf
cp -rfp lib/metadata/* /usr/lib/one/ruby/cloud/metadata
cp -rfp bin/metadata-server /usr/bin
if [ -e /etc/debian_version ]; then
  cp extra/initscripts/opennebula-metadata.debian /etc/init.d/opennebula-metadata
  chmod +x /etc/init.d/opennebula-metadata
fi

echo "Done"
