# frozen_string_literal: true

require 'rails_helper'

describe APIv1::Withdraw, type: :request do
  let(:user) { create(:user, :level_3) }
  let(:token) { jwt_for(user) }

  before do
    set_security_configuration(:peatio, actions: peatio_actions)
    set_security_configuration(:barong, actions: barong_actions)
  end
  let(:peatio_actions) do
    { write_withdraws: { required_signatures: %i[applogic] } }
  end
  let(:barong_actions) do
    { otp_sign: { required_signatures: %i[applogic] } }
  end

  describe 'POST /api/v1/withdraws' do
    before do
      stub_request(:post, "#{ENV.fetch('PEATIO_ROOT_URL')}/management_api/v1/withdraws/new")
        .to_return(status: peatio_response.status,
                   body: peatio_response.body.to_json.to_s,
                   headers: {})
      stub_request(:post, "#{ENV.fetch('BARONG_ROOT_URL')}/management_api/v1/otp/sign")
        .to_return(status: barong_response.status,
                   body: barong_response.body.to_json.to_s,
                   headers: {})
    end
    let(:peatio_response) do
      OpenStruct.new(status: 200, body: { 'foo' => 'bar' })
    end
    let(:barong_response) do
      OpenStruct.new(status: 200, body: { 'foo' => 'bar' })
    end

    let(:do_request) do
      api_post '/api/v1/withdraws', token: token, params: params
    end
    let(:params) do
      {
        currency: 'BTC',
        amount: 0.2,
        otp: '1234',
        rid: '123'
      }
    end

    context 'when action doesn\'t require barong totp' do
      before do
        stub_request(:post, "#{ENV.fetch('BARONG_ROOT_URL')}/management_api/v1/otp/sign")
            .to_raise(Faraday::Error)
      end

      it 'doesn\'t send request to barong' do
        expect{ do_request }.to_not raise_error
      end

      it 'sends withdrawal request to peatio' do
        do_request
        expect(response.status).to eq 201
        expect(json_body).to eq peatio_response.body
      end
    end

    context 'when action requires barong totp' do
      let(:peatio_actions) do
        {
          write_withdraws: {
            required_signatures: %i[applogic],
            requires_barong_totp: true
          }
        }
      end

      it 'sends withdrawal request to peatio and barong' do
        do_request
        expect(response.status).to eq 201
        expect(json_body).to eq peatio_response.body
      end

      context 'when barong responds with errors' do
        before do
          stub_request(:post, "#{ENV.fetch('PEATIO_ROOT_URL')}/management_api/v1/withdraws/new")
              .to_raise(Faraday::Error)
        end
        let(:barong_response) do
          OpenStruct.new(status: 422, body: { error: 'OTP code is invalid' })
        end

        it 'doesn\'t send request to peatio' do
          expect{ do_request }.to_not raise_error
        end

        it 'responds with barong error message' do
          do_request
          expect(response.status).to eq 422
          expect(json_body).to eq JSON.parse(barong_response.body.to_json)
        end
      end

      context 'when barong responds with internal server error' do
        before do
          stub_request(:post, "#{ENV.fetch('PEATIO_ROOT_URL')}/management_api/v1/withdraws/new")
              .to_raise(Faraday::Error)
        end
        let(:barong_response) do
          OpenStruct.new(status: 500, body: {})
        end

        it 'doesn\'t send request to peatio' do
          expect{ do_request }.to_not raise_error
        end

        it 'responds with external services error message' do
          do_request
          expect(response.status).to eq 503
          expect(json_body).to eq({'error' => 'External services error'})
        end
      end

      context 'when peatio responds with errors' do
        let(:peatio_response) do
          OpenStruct.new(status: 422, body: { error: 'Cannot unlock funds (amount: 10).' })
        end

        it 'responds with peatio error message' do
          do_request
          expect(response.status).to eq 422
          expect(json_body).to eq JSON.parse(peatio_response.body.to_json)
        end
      end

      context 'when peatio responds with internal server error' do
        let(:barong_response) do
          OpenStruct.new(status: 500, body: {})
        end

        it 'responds with external services error message' do
          do_request
          expect(response.status).to eq 503
          expect(json_body).to eq({'error' => 'External services error'})
        end
      end
    end

    context 'daily withdrawal check' do
      let(:check) do
        check_obj = instance_double(WithdrawLimits::DailyLimitCheck)
        allow(WithdrawLimits::DailyLimitCheck).to receive(:new).and_return(check_obj)
        check_obj
      end

      context 'when fails' do
        before do
          allow(check).to receive(:call).with(user.uid).and_return(false)
        end

        it 'should respond with error' do
          do_request
          expect(response.status).to eq 422
          expect(json_body).to eq('error' => '24 hour withdraw limit exceeded')
        end
      end

      context 'when pass' do
        before do
          allow(check).to receive(:call).with(user.uid).and_return(true)
        end

        it 'should allow api request to run' do
          expect { do_request }.to_not raise_error
          expect(response.status).to eq 201
        end
      end
    end
  end
end
