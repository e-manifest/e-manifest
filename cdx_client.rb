require 'json'
require 'forwardable'

require 'savon-multipart'
require_relative 'secret'

module CDX
  class Client
    attr_reader :savon

    def initialize(opts={})
      @savon = Savon.client(default_opts.merge(opts))
    end

    def default_opts
      {
        :wsdl => "https://devngn.epacdxnode.net/cdx-register/services/RegisterAuthService?wsdl",
        :pretty_print_xml => true,
        :log => true,
        :soap_version => 2,
        :convert_request_keys_to => :none,
      }
    end

    def self.signing
      new({
        :multipart => true,
        :filters => [:password, :credential, :answer]
      })
    end

    def self.auth
      new({
        :filters => [:password]
      })
    end

    extend Forwardable

    def_delegators :savon, :call

    Signing = signing
    Auth = auth
  end

  class User
    attr_reader :output_stream, :opts

    def initialize(opts, output_stream=$stdout)
      @opts = opts
      @output_stream = output_stream
    end

    def authenticate
      puts opts
      puts authentication_response.hash
      repackage_response
    end

    private

    def puts(message)
      output_stream.puts(message)
    end

    def user_id
      opts['userId']
    end

    def password
      opts['password']
    end

    def user_data
      authentication_response.hash[:envelope][:body][:authenticate_response][:user]
    end

    def authentication_response
      @authentication_response ||= CDX::Client::Auth.call(:authenticate, {
        :message => {
          :userId => user_id, :password => password
        }
      })
    end

    def repackage_response
      {
        :UserId => user_data[:user_id],
        :FirstName => user_data[:first_name],
        :LastName => user_data[:last_name],
        :MiddleInitial => user_data[:middle_initial]
      }
    end
  end
end

def authenticate(args)
  signature_user = authenticate_user(args)
  token = authenticate_system
  activity_id = create_activity({:token => token, :signature_user => signature_user,
                                 :dataflow_name => "eManifest", :activity_description => "development test",
                                 :role_name => "TSDF", :role_code => 112090})
  question = get_question({:token => token, :activity_id => activity_id, :user => signature_user})

  authenticate_response = {
    :token => token,
    :activityId => activity_id,
    :question => question,
    :userId => signature_user[:UserId]
  }
rescue Savon::SOAPFault => error
  puts error.to_hash
  fault_detail = error.to_hash[:fault][:detail]
  if (fault_detail.key?(:register_auth_fault))
    description = fault_detail[:register_auth_fault][:description]
  else
    description = fault_detail[:register_fault][:description]
  end
  puts description
  error_description = {:description => description}
end

def authenticate_user(args, output_stream=$stdout)
  CDX::User.new(args, output_stream).authenticate
end

def authenticate_system
  puts CDX::Client::Signin.operations
  response = CDX::Client::Signin.call(:authenticate,
                                                message: {
                                                  :userId => $cdx_username, :credential => $cdx_password,
                                                  :domain => "default", :authenticationMethod => "password"
                                                })
  puts "---"
  puts response.body
  puts "---"
  token = response.body[:authenticate_response][:security_token]
rescue Savon::SOAPFault => error
  raise error
end

def create_activity(args)
  properties = [{:Property => {:Key => "activityDescription", :Value => args[:activity_description]}},
                {:Property => {:Key => "roleCode", :Value => args[:role_code]}}]
  response = CDX::Client::Signin.call(:create_activity_with_properties,
                                                message: {
                                                  :securityToken => args[:token],
                                                  :signatureUser => args[:signature_user],
                                                  :dataflowName => args[:dataflow_name],
                                                  :properties => properties
                                                })
  puts "---"
  puts response.body
  puts "---"
  activity_id = response.body[:create_activity_with_properties_response][:activity_id]
rescue Savon::SOAPFault => error
  raise error
end

def get_question(args)
  response = CDX::Client::Signin.call(:get_question,
                                                message: {
                                                  :securityToken => args[:token],
                                                  :activityId => args[:activity_id],
                                                  :userId => args[:user][:UserId]
                                                })
  puts "---"
  puts response.body
  puts "---"
  question = response.body[:get_question_response][:question]
  question_id = question[:question_id]
  question_text = question[:text]
  question_response = {:questionId => question_id, :questionText => question_text}
rescue Savon::SOAPFault => error
  raise error
end

def sign_manifest(args)
  is_valid_answer = validate_answer(args)
  document_id = sign(args)
  sign_response = { :documentId => document_id }
rescue Savon::SOAPFault => error
  puts error.to_hash
  description = error.to_hash[:fault][:detail][:register_fault][:description] 
  puts description
  return {:description => description}
end

def validate_answer(args)
  response =
    CDX::Client::Signin.call(:validate_answer,
                                       message: {
                                         :securityToken => args["token"],
                                         :activityId => args["activityId"],
                                         :userId => args["userId"],
                                         :questionId => args["questionId"],
                                         :answer => args["answer"]
                                       })
  puts "---"
  puts response.body
  puts "---"
  is_valid_answer = response.body[:validate_answer_response][:valid_answer]
rescue Savon::SOAPFault => error
  # throws on invalid answer
  raise error
end

def sign(args)
  manifest_id = args["id"]
  name = "e-manifest " + manifest_id
  
  signature_document = {
    :Name => name,
    :Format => "BIN",
    :Content => args[:manifest_content]
  }
  
  response =
    CDX::Client::Signin.call(:sign,
                                       message: {
                                         :securityToken => args["token"],
                                         :activityId => args["activityId"],
                                         :signatureDocument => signature_document
                                       })
  puts "---"
  puts response.body
  puts "---"
  document_id = response.body[:sign_response][:document_id]
rescue Savon::SOAPFault => error
  # throws on invalid answer
  raise error
end

