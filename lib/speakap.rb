require 'speakap/version'
require 'net/http'
require 'net/https'

module Speakap
  class Api
    def initialize(network_eid, app_eid, secret)
      @network_eid = network_eid
      @app_eid = app_eid
      @app_secret = secret
      @api_version = 'v1.3.8'
    end

    def get_network
      make_call nil, embed: :user_profile
    end

    def create_notification(xid, text, app_data)
      resp = make_call(:alerts, {
        recipients: [
          {
            type: :user,
            XID: xid
          }
        ],
        localizableBody: {
          'nl-NL' => text,
          'nl-US' => text
        },
        appData: app_data
      }, :post)

      return true, resp['EID'] if resp['EID']
      false
    end

    def create_notifications(eids, text, app_data)
      make_call(:alerts, {
        recipients: eids.map { |eid| {
          type: :user,
          EID: eid
        } },
        localizableBody: {
          'nl-NL' => text,
          'nl-US' => text
        },
        appData: app_data
      }, :post)
    end

    def get_user_by_eid(eid)
      make_call "users/#{eid}", embed: 'organizationGroups'
    end

    def get_users(page)
      items_per_page = 100
      response = make_call 'users',
                           'embed' => 'users.organizationGroups',
                           'offset[self]' => (page - 1) * items_per_page,
                           'offset[users.organizationGroups]' => 0,
                           'limit' => items_per_page
      response['_embedded']['users']
    end

    def get_admins
      response = make_call 'users',
                           embed: :users,
                           role: :enterprise_admin,
                           limit: 1000,
                           properties: :EID
      enterprise_admins = response['_embedded']['users']
      
      response = make_call 'users',
                           embed: :users,
                           role: :admin,
                           limit: 1000,
                           properties: :EID
      admins = response['_embedded']['users']

      enterprise_admins + admins
    end

    def get_groups(page)
      items_per_page = 1
      response = make_call 'groups',
                           'embed' => 'groups.members',
                           'type' => 'basic',
                           'properties[groups]' => 'name',
                           'properties[groups.members]' => 'EID',
                           'offset[self]' => (page - 1) * items_per_page,
                           'offset[groups.members]' => 0,
                           'limit[self]' => items_per_page,
                           'limit[groups.members]' => 1000,
                           'include_hidden' => true,
                           'include_secret' => true
      response['_embedded']['groups']
    end

    private

    def get_authorization
      "Bearer #{@app_eid}_#{@app_secret}"
    end

    def make_call(call = nil, data = nil, method = :get)
      url = "https://api.speakap.io/networks/#{@network_eid}/"
      url += "#{call}/" unless call.nil?
      url += "?#{data.to_query}" if !data.nil? && method == :get

      uri = URI.parse(url)

      if method == :post
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        headers = {
          'Accept' => "application/vnd.speakap.api-#{@api_version}+json",
          'Content-Type' => 'application/json',
          'Authorization' => get_authorization
        }

        resp, data = http.post(uri.path, data.to_json, headers)
        if data
          JSON.parse data
        else
          JSON.parse resp.body
        end
      else
        resp = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
          req = Net::HTTP::Get.new(uri.request_uri) if method == :get
          req = Net::HTTP::Delete.new(uri.request_uri) if method == :delete
          req.add_field 'Accept', "application/vnd.speakap.api-#{@api_version}+json"
          req.add_field 'Authorization', get_authorization
          http.request req
        end

        JSON.parse resp.body
      end
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
