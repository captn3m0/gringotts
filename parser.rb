require 'json'
require 'time'
require 'pp'

class Parser
    def splitwise(body, user_id)
      expenses = JSON.parse(body)['expenses']
      expenses.map! do |expense|
        # convert timestamp to local timezone
        expense['time'] = DateTime.iso8601(expense['date']).to_time.to_datetime.to_time
        clean_splitwise_expense(expense, user_id)
      end
      summarize expenses.reject {|e| e==false}
    end

    def summarize(expenses)
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
      #data.eac
    end

    def clean_splitwise_expense(expense, user_id)
      users = expense['users']
      amount = 0
      users.each do |user|
        if user['user_id'] === user_id
          return false if user['owed_share'].to_f.floor.zero?
          return {
            "id"             => expense['id'],
            "description"    => expense['description'],
            "amount"         => user['owed_share'].to_f,
            "time"           => expense['time'],
            "category"       => expense['category']['name']
          }
        end
      end
      return false
    end
end