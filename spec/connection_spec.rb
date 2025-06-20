# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OneRoster::Connection do
  let(:connection) { described_class.new(client) }
  let(:logger) { stub('Logger') }
  let(:app_id) { 'app_id' }
  let(:app_secret) { 'app_secret' }
  let(:api_url) { 'https://bjulez.oneroster.com/' }
  let(:sentry_client) { nil }

  let(:client) do
    OneRoster::Client.configure do |config|
      config.app_id     = app_id
      config.app_secret = app_secret
      config.api_url    = api_url
      config.logger     = logger
      config.sentry_client = sentry_client
    end
  end

  describe '#connection' do
    it 'returns new faraday connection if one does not exist' do
      conn = connection.connection
      expect(conn).to be_a(Faraday::Connection)
      expect(conn.headers).to eq('User-Agent' => "Faraday v#{Faraday::VERSION}")
      expect(conn.builder.handlers).to include(
          Faraday::OAuth::Middleware,
          Faraday::Response::Json,
          Faraday::Response::Logger
      )
    end

    it 'memoizes the connection' do
      conn = connection.connection
      expect(connection.connection).to eq(conn)
    end
  end

  describe '#execute' do
    let(:status) { 200 }
    let(:body) { 'body' }
    let(:env) { stub(url: stub(path: '/enrollments')) }
    let(:mock_response) { stub(status: status, body: body, env: env, headers: {}) }

    context 'successful response' do
      it 'returns a successful response object' do
        connection.expects(:connection).returns(OneRoster::MockFaradayConnection.new(mock_response))
        response = connection.execute('/enrollments', :get, limit: OneRoster::PAGE_LIMIT, offset: 0)
        expect(response).to be_a(OneRoster::Response)
        expect(response.success?).to be(true)
        expect(response.raw_body).to eq(mock_response.body)
      end
    end

    context 'failed response' do
      let(:status) { 401 }
      let(:body) { 'unauthorized' }

      it 'returns a failed response object' do
        connection.stubs(:raw_request).returns(mock_response)
        response = connection.execute('/teachers', :get, limit: OneRoster::PAGE_LIMIT, offset: 0)
        expect(response).to be_a(OneRoster::Response)
        expect(response.success?).to be(false)
        expect(response.raw_body).to eq(mock_response.body)
      end
    end

    context '502 response' do
      let(:status) { 502 }
      let(:body) { 'Bad Gateway' }

      before { connection.stubs(:raw_request).returns(mock_response) }

      it 'does not log to sentry and returns a failed response object' do
        response = connection.execute('/teachers', :get, limit: OneRoster::PAGE_LIMIT)
        expect(response).to be_a(OneRoster::Response)
        expect(response.success?).to be(false)
        expect(response.raw_body).to eq(mock_response.body)
      end

      context 'with a sentry_client configured' do
        let(:sentry_client) { stub(capture_message: stub) }

        it 'logs to sentry and returns a failed response object' do
          sentry_client.expects(:capture_message)

          response = connection.execute('/teachers', :get, limit: OneRoster::PAGE_LIMIT)
          expect(response).to be_a(OneRoster::Response)
          expect(response.success?).to be(false)
          expect(response.raw_body).to eq(mock_response.body)
        end
      end
    end

    context '504 response' do
      subject { connection.execute('/teachers', :get, limit: OneRoster::PAGE_LIMIT) }

      let(:status) { 504 }
      let(:body) { 'Gateway Timeout' }

      before { connection.stubs(:raw_request).returns(mock_response) }

      it 'raises an error' do
        expect { subject }.to raise_error(OneRoster::Connection::GatewayTimeoutError)
      end

      context 'with a sentry_client configured' do
        let(:sentry_client) { stub(capture_message: stub) }

        it 'logs to sentry and raises' do
          sentry_client.expects(:capture_message)

          expect { subject }.to raise_error(OneRoster::Connection::GatewayTimeoutError)
        end
      end
    end
  end

  describe '#log' do
    it 'logs properly' do
      logger.expects(:info)

      connection.log('💩')
    end
  end
end
