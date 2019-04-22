# frozen_string_literal: true

require_relative './spec_helper'

describe 'Test User Handling' do
  include Rack::Test::Methods

  before do
    wipe_database
  end

  it 'HAPPY: should be able to get list of all users' do
    CoEditPDF::User.create(DATA[:users][0])
    CoEditPDF::User.create(DATA[:users][1])

    get 'api/v1/users'
    _(last_response.status).must_equal 200

    result = JSON.parse last_response.body
    _(result['data'].count).must_equal 2
  end

  it 'HAPPY: should be able to get details of a single user' do
    existing_user = DATA[:users][1]
    CoEditPDF::User.create(existing_user)
    id = CoEditPDF::User.first.id

    get "/api/v1/users/#{id}"
    _(last_response.status).must_equal 200

    result = JSON.parse last_response.body
    _(result['data']['attributes']['id']).must_equal id
    _(result['data']['attributes']['name']).must_equal existing_user['name']
    _(result['data']['attributes']['email']).must_equal existing_user['email']
  end

  it 'SAD: should return error if unknown user requested' do
    get '/api/v1/users/foobar'

    _(last_response.status).must_equal 404
  end

  it 'HAPPY: should be able to create new users' do
    existing_user = DATA[:users][1]

    req_header = { 'CONTENT_TYPE' => 'application/json' }
    post 'api/v1/users', existing_user.to_json, req_header
    _(last_response.status).must_equal 201
    _(last_response.header['Location'].size).must_be :>, 0

    created = JSON.parse(last_response.body)['data']['data']['attributes']
    user = CoEditPDF::User.first

    _(created['id']).must_equal user.id
    _(created['name']).must_equal existing_user['name']
    _(created['email']).must_equal existing_user['email']
  end
end