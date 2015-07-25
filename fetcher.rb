require './parser'
require 'patron'

class Fetcher
    def initialize(config)
      cookie = config['paytm']['credentials']

      @paytm_session = Patron::Session.new
      @paytm_session.headers = {
        #'User-Agent' => 'Gringotts (https://github.com/captn3m0/gringotts)',
        'Cookie'     => "connect.sid=#{cookie};"
      }
      @paytm_session.base_url = 'https://paytm.com'
      @paytm_session.enable_debug "/tmp/patron.debug"
      @config = config
    end
    def splitwise(mock = false)
        config = @config['splitwise']
        body = ""
        if mock
          body = File.read('raw_data/splitwise.json')
        else
          consumer = OAuth::Consumer.new(config["key"], config["secret"], {
            :site => config["base_url"],
            :scheme => :header,
            :http_method => :post,
            :authorize_path => config["authorize_path"],
            :request_token_path => config["request_path"],
            :access_token_path => config["access_token_path"]
          })

          access_token = OAuth::AccessToken.new(consumer, config["credentials"]["token"], config["credentials"]["secret"])

          response = access_token.get('https://secure.splitwise.com/api/v3.0/get_expenses?limit=0')
          body = response.body
        end
        expenses = Parser.new.splitwise(body, config['credentials']['user_id'])
        write('splitwise', expenses)
    end

    def paytm(mock = false)
      body = ''
      if mock
        # For now, we just parse the json file
        body = File.read('raw_data/paytm.json')
      else
        response = @paytm_session.get('/shop/orderhistory?pagesize=300')
        body = response.body
      end
      orders = Parser.new.paytm(body)
      write('paytm', orders)
    end

    def uber(mock = false)
      body = ''
      if mock
        # For now, we just parse the json file
        body = File.read('raw_data/paytm_txn.json')
      else
        response = @paytm_session.get('/shop/wallet/txnhistory?page_size=199&page_number=0')
        body = response.body
      end
      # Now we parse the transactions
      rides = Parser.new.uber(body)
      write('uber', rides)
    end

    def write(method, data)
      data.each do |month, e|
        content = e.to_yaml
        File.write("reports/#{method}/#{month}.yml", content)
      end
    end
end