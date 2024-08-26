# frozen_string_literal: true

require 'active_support/concern'

module WechatPayHelper # :nodoc:
  GATEWAY_URL = 'https://api.mch.weixin.qq.com'
  HK_GATEWAY_URL = 'https://apihk.mch.weixin.qq.com'

  extend ActiveSupport::Concern

  class_methods do
    def build_query(params)
      params.sort.map { |key, value| "#{key}=#{value}" }.join('&')
    end

    def make_request(method:, path:, for_sign: '', payload: {}, extra_headers: {})
      gateway_url = HK_GATEWAY_URL
      authorization = WechatPay::Sign.build_authorization_header(method, path, for_sign)
      headers = {
        'Authorization' => authorization,
        'Content-Type' => 'application/json',
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
      Rails.logger.info "[WechatPayHelper#make_request] url: #{gateway_url}#{path}, duration: #{format('%.2f', rs.duration)}s, resp: #{rs.inspect}"
      rs
    rescue ::RestClient::ExceptionWithResponse => e
      e.response
    end

    # 证书获取
    #
    # Document: https://pay.weixin.qq.com/wiki/doc/api_external/ch/apis/chapter3_4_8.shtml
    #
    # Example:
    #
    # ``` ruby
    # WechatPay::Direct.certificates
    # ```
    #
    def certificates
      url = '/v3/global/certificates'
      method = 'GET'

      make_request(
        method: method,
        path: url,
        extra_headers: {
          'Content-Type' => 'application/x-www-form-urlencoded'
        }
      )
    end
  end
end
