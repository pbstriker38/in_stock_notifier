# frozen_string_literal: true

require 'sidekiq'
require 'webpush'

class Notify
  include Sidekiq::Worker

  def perform
    redis = Redis.new(url: ENV['REDIS_URL'])
    subscriptions = redis.hgetall('subscriptions')

    subscriptions.each_value do |subscription_json|
      subscription = JSON.parse(subscription_json)
      puts "Notifying #{subscription}"

      Webpush.payload_send(
        message: JSON.generate({ title: 'Hello', body: 'everyone!'}),
        endpoint: subscription['endpoint'],
        p256dh: subscription['p256dh'],
        auth: subscription['auth'],
        vapid: {
          subject: "mailto:#{ENV.fetch('VAPID_CLAIM_EMAIL')}",
          public_key: ENV.fetch('VAPID_PUBLIC_KEY'),
          private_key: ENV.fetch('VAPID_PRIVATE_KEY')
        },
        ssl_timeout: 5,
        open_timeout: 5,
        read_timeout: 5
      )
    end
  end
end
