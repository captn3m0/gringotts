require 'json'
require 'time'
require 'pp'
require 'money'
require 'monetize'

class Parser
    def initialize(config)
      @config = config
      @splitwise_user_id = @config['splitwise']['credentials']['user_id']
      setup_currency
    end
    def splitwise(body)
      expenses = JSON.parse(body)['expenses']
      summarize expenses.map! {|e| clean_splitwise_expense(e)}
    end

    def summarize(expenses)
      expenses.reject! {|e| e==false}
      res = {}
      expenses.each do |expense|
        #pp expense
        month_identifier = expense['time'].strftime('%Y-%^b')
        res[month_identifier]||={'sum' => 0.0, 'expenses' => []}
        res[month_identifier]['expenses'].push expense
        res[month_identifier]['sum'] = (res[month_identifier]['sum'] + expense['amount']).round(2)
      end
      res
    end

    def paytm(body)
      data = JSON.parse(body)
      if data.is_a? Hash and data.has_key? 'orders'
        data = data['orders']
      end
      summarize data.map! {|e| clean_paytm_expense(e)}
    end

    def uber(body)
      # We only return the uber orders for this now
      data = JSON.parse(body)['response'].select {|order| order['txnTo'] == 'UBER'}
      summarize data.map! {|e| clean_uber_expense(e)}
    end

    def amazon_com(csv)
      orders = []
      csv.each do |row|
        orders.push clean_amazon_com_order(row)
      end
      summarize orders
    end

    def clean_amazon_com_order(row)
      amount = parse_money(row['Subtotal']) + parse_money(row['Shipping Charge'])
      return {
        'id'            => row['Order ID'],
        'time'          => Date.strptime(row['Order Date'], '%m/%d/%y').to_time,
        'description'   => 'Order at amazon.com',
        # Using SubTotal + Shipping Charge instead of Total Chared
        # which is very high and incorrect because of customs
        'amount'        =>  amount.to_f
      }
    end

    def setup_currency
      Monetize.assume_from_symbol = true
      Money.default_currency = Money::Currency.new(@config['base_currency'])
      @config['exchange_rate'].each do |currency_code, rate|
        Money.add_rate currency_code, Money.default_currency, rate
      end
    end

    def parse_money(money)
      Monetize.parse(money).exchange_to(Money.default_currency)
    end

    def clean_uber_expense(order)
      return {
        'id'                => order['txnDescription1'],
        'description'       => order['txnDesc1'],
        'amount'            => order['txnamount'].to_f,
        'time'              => DateTime.parse(order['txndate']).to_time,
        # We keep the category to be the same as that used in Splitwise
        'category'          => 'Taxi'
      }
    end

    def clean_paytm_expense(expense)
      # We do not count wallet or failed expenses
      return false if expense['status'].downcase === 'failed'
      return false if expense['items'][0]['product']['vertical_label'].downcase === 'wallet'
      return {
        'id'                => expense['order_id'],
        'description'       => expense['order_name'],
        'amount'            => expense['amount'],
        'category'          => expense['items'][0]['product']['vertical_label'],
        'time'              => DateTime.parse(expense['dateString']).to_time
      }
    end

    def clean_splitwise_expense(expense)
      users = expense['users']
      amount = 0
      users.each do |user|
        if user['user_id'] === @splitwise_user_id
          return false if user['net_balance'].to_f.floor.zero?
          return {
            "id"             => expense['id'],
            "description"    => expense['description'],
            # net_balance is -ve if you owe it
            # or +ve if you paid
            # Since we are tracking expenses, we use the reverse
            "amount"         => -user['net_balance'].to_f,
            "time"           => DateTime.iso8601(expense['date']).to_time.to_datetime.to_time,
            "category"       => expense['category']['name']
          }
        end
      end
      return false
    end
end