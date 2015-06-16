# -------------------------------------------------------------------------- #
# Copyright 2002-2012, OpenNebula Project Leads (OpenNebula.org)             #
# Copyright 2012, Ricardo Duarte                                             #
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

require 'rubygems'
require 'erb'
require 'CloudServer'
require 'base64'


###############################################################################
# The Metadata Server implements a EC2 compatible metadata service based on the
# OpenNebula Engine
###############################################################################
class MetadataServer < CloudServer

    ###########################################################################

    def initialize(oneadmin_client, config, logger)
        super(config, logger)

        @oneadmin_client = oneadmin_client

    end

    ###########################################################################
    # Metadata Interface
    ###########################################################################

    def version(params)
        response = ERB.new(File.read(@config[:views]+"/version.erb"))
        return response.result(binding), 200
    end

    def root(params)
        response = ERB.new(File.read(@config[:views]+"/root.erb"))
        return response.result(binding), 200
    end

    def get_value(ip, command, params = nil)
        @value = nil
        flags = OpenNebula::Pool::INFO_ALL || OpenNebula::VirtualMachinePool::INFO_NOT_DONE
        vmpool = VirtualMachinePool.new(@oneadmin_client, flags)
        vmpool.info
     
        vmpool.each do |vm|
          if vm["TEMPLATE/NIC/IP"] == ip 
            case command
              when 'top-level'
		@capabilities = ['instance-id', 'local-ipv4', 'local-hostname', 'hostname', 'public-hostname', 'public-ipv4']
		@capabilities << 'user-data' if vm["TEMPLATE/CONTEXT/EC2_USER_DATA"]
		@capabilities << 'public-keys/' if vm["TEMPLATE/CONTEXT/EC2_PUBLIC_KEY"]
		@capabilities << ['ami-id', 'ami-launch-index', 'ami-manifest-path', 'instance-type', 'reservation-id' ] if vm['TEMPLATE/IMAGE_ID']
		@capabilities.flatten!
                @value = ERB.new(File.read(@config[:views]+"/top_level.erb"), nil, '%<>-').result(binding)
              when 'ami-id'
                @value = "#{vm['TEMPLATE/IMAGE_ID']}" if vm['TEMPLATE/IMAGE_ID']
              when 'instance-id'
                @value = "i-#{vm.id}"
              when 'ami-launch-index'
                @value = "#{vm.id}"
              when 'ami-manifest-path'
                @value = "none"
              when 'local-ipv4'
                @value = "#{ip}"
              when 'public-keys'
                if params[:splat].last.split('/').last == 'openssh-key'
                  @value = vm["TEMPLATE/CONTEXT/EC2_PUBLIC_KEY"] if vm["TEMPLATE/CONTEXT/EC2_PUBLIC_KEY"]
                elsif params[:splat].last.split('/').first == '0'
                  @value = 'openssh-key'
                else
                  @value = "0="+vm["TEMPLATE/CONTEXT/EC2_KEYNAME"] if vm["TEMPLATE/CONTEXT/EC2_KEYNAME"]
                end
              when 'reservation-id'
                @value = "r-#{vm.id}"
              when 'security-groups'
              #  @value = ""
              when 'local-hostname'  # 2007-01-19
                @value = "i-#{vm.id}#{params[:cloud_domain]}"
              when 'public-hostname'
                @value = "i-#{vm.id}#{params[:cloud_domain]}"
              when 'hostname'
                @value = "i-#{vm.id}#{params[:cloud_domain]}"
              when 'public-ipv4'
                @value = "#{ip}"
              when 'instance-type'  # 2007-08-29
                @value = vm["TEMPLATE/INSTANCE_TYPE"]
              when 'user-data'
                @value = Base64.decode64(vm["TEMPLATE/CONTEXT/EC2_USER_DATA"]) if vm["TEMPLATE/CONTEXT/EC2_USER_DATA"]

              end
            break
          end
        end

        if(@value.nil?)
          return OpenNebula::Error.new('Unsupported'),404
        else 
          return @value, 200
        end
    end


    ###########################################################################
    # Unsupported
    ###########################################################################

    def unsupported
	    return OpenNebula::Error.new('Unsupported'),404
    end

    ###########################################################################
    # Helper functions
    ###########################################################################
    private


end

