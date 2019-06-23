# frozen_string_literal: true

require 'roda'
require_relative './app'

module CoEditPDF
  # Web controller for CoEditPDF API
  class Api < Roda
    route('accounts') do |routing| # rubocop:disable Metrics/BlockLength
      @account_route = "#{@api_root}/accounts"
      routing.on String do |account_name|
        routing.halt(403, UNAUTH_MSG) unless @auth_account

        # GET api/v1/accounts/[account_name]
        routing.get do
          auth = AuthorizeAccount.call(
            auth: @auth, name: account_name,
            auth_scope: AuthScope.new(AuthScope::READ_ONLY)
          )
          { data: auth }.to_json
        rescue AuthorizeAccount::ForbiddenError => e
          routing.halt 404, { message: e.message }.to_json
        rescue StandardError => e
          puts "GET ACCOUNT ERROR: #{e.inspect}"
          routing.halt 500, { message: 'API Server Error' }.to_json
        end
      end

      # POST api/v1/accounts
      routing.post do
        account_data = SignedRequest.new(Api.config).parse(request.body.read)
        new_account = Account.create(account_data)

        response.status = 201
        response['Location'] = "#{@account_route}/#{new_account.name}"
        { message: 'Account saved', data: new_account }.to_json
      rescue Sequel::MassAssignmentRestriction
        routing.halt 400, { message: 'Illegal Attributes' }.to_json
      rescue SignedRequest::VerificationError
        routing.halt 403, { message: 'Must sign request' }.to_json
      rescue StandardError => e
        puts "ERROR CREATING ACCOUNT: #{e.inspect}"
        routing.halt 500, { message: 'Error creating account' }.to_json
      end
    end
  end
end
