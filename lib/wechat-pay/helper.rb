# frozen_string_literal: true

require 'active_support/concern'

module WechatPayHelper # :nodoc:
  GATEWAY_URL = 'https://api.mch.weixin.qq.com'

  extend ActiveSupport::Concern

  class_methods do
    def build_query(params)
      params.sort.map { |key, value| "#{key}=#{value}" }.join('&')
    end

    def make_request(method:, path:, for_sign: '', payload: {}, extra_headers: {})
      gateway_url = if path.include?('/v3/global/transactions')
                      'https://apihk.mch.weixin.qq.com'
                    else
                      GATEWAY_URL
                    end
      authorization = WechatPay::Sign.build_authorization_header(method, path, for_sign)
      headers = {
        'Authorization' => authorization,
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'Accept-Encoding' => '*'
      }.merge(extra_headers)

      rs = RestClient::Request.execute(
        url: "#{gateway_url}#{path}",
        method: method.downcase,
        payload: payload,
        log: Logger.new(STDERR),
        raw_response: true,
        headers: headers.compact # Remove empty items
      )
      Rails.logger.info "[WechatPayHelper#make_request] url: #{gateway_url}#{path}, duration: #{sprintf('%.2f', duration)}s
      rs
    rescue ::RestClient::ExceptionWithResponse => e
      e.response
    end
  end
end
