require './parser'
class Fetcher
    def splitwise(config, mock = false)
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

    def paytm(config)
      # For now, we just parse the json file
      body = File.read('raw_data/paytm.json')
      orders = Parser.new.paytm(body)
      write('paytm', orders)
    end

    def uber(config)
      # Now we parse the transactions
      body = File.read('raw_data/paytm_txn.json')
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