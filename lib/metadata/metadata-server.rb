# -------------------------------------------------------------------------- #
# Copyright 2002-2012, OpenNebula Project Leads (OpenNebula.org)             #
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

##############################################################################
# Environment Configuration for the Cloud Server
##############################################################################
ONE_LOCATION=ENV["ONE_LOCATION"]

if !ONE_LOCATION
    LOG_LOCATION = "/var/log/one"
    VAR_LOCATION = "/var/lib/one"
    ETC_LOCATION = "/etc/one"
    RUBY_LIB_LOCATION = "/usr/lib/one/ruby"
else
    VAR_LOCATION = ONE_LOCATION + "/var"
    LOG_LOCATION = ONE_LOCATION + "/var"
    ETC_LOCATION = ONE_LOCATION + "/etc"
    RUBY_LIB_LOCATION = ONE_LOCATION+"/lib/ruby"
end

METADATA_AUTH           = VAR_LOCATION + "/.one/ec2_auth"
METADATA_LOG            = LOG_LOCATION + "/metadata-server.log"
CONFIGURATION_FILE = ETC_LOCATION + "/metadata.conf"

TEMPLATE_LOCATION  = ETC_LOCATION + "/ec2query_templates"
VIEWS_LOCATION     = RUBY_LIB_LOCATION + "/cloud/metadata/views"

$: << RUBY_LIB_LOCATION
$: << RUBY_LIB_LOCATION+"/cloud"
$: << RUBY_LIB_LOCATION+"/cloud/metadata"

###############################################################################
# Libraries
###############################################################################
require 'rubygems'
require 'sinatra'
require 'yaml'
require 'uri'

require 'MetadataServer'
require 'CloudAuth'

include OpenNebula

##############################################################################
# Parse Configuration file
##############################################################################
begin
    conf = YAML.load_file(CONFIGURATION_FILE)
rescue Exception => e
    STDERR.puts "Error parsing config file #{CONFIGURATION_FILE}: #{e.message}"
    exit 1
end

conf[:template_location] = TEMPLATE_LOCATION
conf[:views] = VIEWS_LOCATION
conf[:debug_level] ||= 3
conf[:cloud_domain] ||= nil

##############################################################################
# Sinatra Configuration
##############################################################################

include CloudLogger
logger = enable_logging METADATA_LOG, conf[:debug_level].to_i

if conf[:server]
    conf[:host] ||= conf[:server]
    warning = "Warning: :server: configuration parameter has been deprecated."
    warning << " Use :host: instead."
    logger.warn warning
end

if CloudServer.is_port_open?(conf[:host],
                             conf[:port])
    logger.error {
        "Port #{conf[:port]} busy, please shutdown " <<
        "the service or move occi server port."
    }
    exit -1
end

set :bind, conf[:host]
set :port, conf[:port]

begin
    ENV["ONE_CIPHER_AUTH"] = METADATA_AUTH
    cloud_auth = CloudAuth.new(conf, logger)
rescue => e
    logger.error {"Error initializing authentication system"}
    logger.error {e.message}
    exit -1
end

set :cloud_auth, cloud_auth

if conf[:ssl_server]
    uri = URI.parse(conf[:ssl_server])
    metadata_host = uri.host
    metadata_port = uri.port
    metadata_path = uri.path
else
    metadata_host = conf[:host]
    metadata_port = conf[:port]
    metadata_path = '/'
end

unless conf[:cloud_domain].nil? or conf[:cloud_domain].start_with?('.')
    conf[:cloud_domain].insert(0,'.')
end

set :metadata_host, metadata_host
set :metadata_port, metadata_port
set :metadata_path, metadata_path

set :config, conf

CloudServer.print_configuration(conf)
##############################################################################
# Actions
##############################################################################

before do
    begin
        params['metadata_host'] = settings.metadata_host
        params['metadata_port'] = settings.metadata_port
        params['metadata_path'] = settings.metadata_path
        params['cloud_domain'] = conf[:cloud_domain]
        oneadmin_client = settings.cloud_auth.client
        @metadata_server = MetadataServer.new(oneadmin_client, settings.config, settings.logger)
    end
end

helpers do
    def error_xml(code,id)
        message = ''

        case code
        when 'AuthFailure'
            message = 'User not authorized'
        when 'InvalidAMIID.NotFound'
            message = 'Specified AMI ID does not exist'
        when 'Unsupported'
            message = 'The instance type or feature is not supported in your requested Availability Zone.'
        else
            message = code
        end

        xml = "<Response><Errors><Error><Code>"+
                    code +
                    "</Code><Message>" +
                    message +
                    "</Message></Error></Errors><RequestID>" +
                    id.to_s +
                    "</RequestID></Response>"

        return xml
    end
end

get '/' do
    do_version_request(params)
end

get '/*/meta-data/?' do
    do_metadata_request(request.ip, 'top-level', params)
end

get '/*/meta-data/:value/?*?' do
    do_metadata_request(request.ip, params['value'].downcase, params)
end

get '/*/user-data/?' do
    do_metadata_request(request.ip, 'user-data')
end

get '/*' do
    do_root_request(params)
end

not_found do
    halt 404
end

def do_version_request(params)

    result,rc = @metadata_server.version(params)

    if rc != 200
      halt 404
    end

    result
end

def do_root_request(params)

    result,rc = @metadata_server.root(params)

    if rc != 200
      halt 404
    end

    result
end

def do_metadata_request(ip, value, params = nil)

    result,rc = @metadata_server.get_value(ip, value, params)

    if rc != 200
      halt 404
    end

    result

end

