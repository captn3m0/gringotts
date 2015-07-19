require 'json'
require 'time'
require 'pp'

class Parser
    def splitwise(body, user_id)
      @splitwise_user_id = user_id
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
      # You put the output of https://paytm.com/shop/orderhistory?pagesize=300 in the json file
      data = JSON.parse(body)
      if data.is_a? Hash and data.has_key? 'orders'
        data = data.orders
      end
      summarize data.map! {|e| clean_paytm_expense(e)}
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