require 'json'
require 'time'

class Parser
    def splitwise(body, user_id)
      expenses = JSON.parse(body)['expenses']
      res = {}
      expenses.each do |expense|
        # convert timestamp to local timezone
        timestamp = DateTime.iso8601(expense['date']).to_time.to_datetime
        expense['time'] = timestamp.to_s
        month_identifier = timestamp.strftime('%Y-%^b')

        res[month_identifier]||={'sum' => 0.0, 'expenses' => []}

        expense = clean_splitwise_expense(expense, user_id)
        if expense
          res[month_identifier]['expenses'].push expense
          res[month_identifier]['sum'] = (res[month_identifier]['sum'] + expense['amount']).round(2)
        end
      end
      res
    end

    def remove_null(hash)
      hash.keep_if do |key, value|
        return !value
      end
    end

    def clean_splitwise_expense(expense, user_id)
      users = expense['users']

      user_found = false
      amount = 0
      users.each do |user|
        if user['user_id'] === user_id
          return false if user['owed_share'].to_f == 0.0
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