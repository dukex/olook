require 'database_cleaner/data_mapper/base'

module DatabaseCleaner::DataMapper
  class Transaction
    include ::DatabaseCleaner::DataMapper::Base

    def start(repository = self.db)
      ::DataMapper.repository(repository) do |r|
        transaction = DataMapper::Transaction.new(r)
        transaction.begin
        r.adapter.push_transaction(transaction)
      end
    end

    def clean(repository = self.db)
      ::DataMapper.repository(repository) do |r|
        adapter = r.adapter
        while adapter.current_transaction
          adapter.current_transaction.rollback
          adapter.pop_transaction
        end
      end
    end

  end
end
