# frozen_string_literal: true

require 'sinatra'
require 'webpush'
require 'json'
require 'openssl'
require './workers/notify'

class App < Sinatra::Base
  # subscriptions = {}
  redis = Redis.new(url: ENV['REDIS_URL'])

  get '/' do
    erb :index
  end

  post '/subscribe' do
    params = JSON.parse(request.body.read)
    p params
    subscription = {
      auth: params['auth'],
      endpoint: params['endpoint'],
      p256dh: params['p256dh']
  }.to_json

    key = OpenSSL::Digest::SHA256.hexdigest(subscription)
    redis.hset('subscriptions', key, subscription)

    puts redis.hgetall('subscriptions')

    status 201
    body ''
  end

  get '/notify_all' do
    Notify.perform_async()
  #   subscriptions.each_value do |subscription|
  #     Webpush.payload_send(
  #       message: JSON.generate({ title: 'Hello', body: 'everyone!'}),
  #       endpoint: subscription[:endpoint],
  #       p256dh: subscription[:p256dh],
  #       auth: subscription[:auth],
  #       vapid: {
  #         subject: "mailto:#{ENV.fetch('VAPID_CLAIM_EMAIL')}",
  #         public_key: public_key,
  #         private_key: ENV.fetch('VAPID_PRIVATE_KEY')
  #       },
  #       ssl_timeout: 5,
  #       open_timeout: 5,
  #       read_timeout: 5
  #     )
      status 200
      body ''
  #   end
  end

  post '/push' do
    params = JSON.parse(request.body.read)

    Webpush.payload_send(
      message: JSON.generate(params['message']),
      endpoint: params['endpoint'],
      p256dh: params['p256dh'],
      auth: params['auth'],
      vapid: {
        subject: "mailto:#{ENV.fetch('VAPID_CLAIM_EMAIL')}",
        public_key: public_key,
        private_key: ENV.fetch('VAPID_PRIVATE_KEY')
      },
      ssl_timeout: 5,
      open_timeout: 5,
      read_timeout: 5
    )
    status 200
    body ''
  end

  private

  helpers do
    def public_key
      @public_key ||= ENV.fetch('VAPID_PUBLIC_KEY')
    end
  end
end
