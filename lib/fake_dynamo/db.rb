module FakeDynamo
  class DB

    include Validation

    attr_reader :tables

    class << self
      def instance
        @db ||= DB.new
      end
    end

    def initialize
      @tables = {}
    end

    def process(operation, data)
      validate_payload(operation, data)
      operation = operation.underscore
      self.send operation, data
    end

    def create_table(data)
      table_name = data['TableName']
      raise ResourceInUseException, "Duplicate table name: #{table_name}" if tables[table_name]

      table = Table.new(data)
      tables[table_name] = table
      response = table.description
      table.activate
      response
    end

    def describe_table(data)
      table = find_table(data['TableName'])
      table.describe_table
    end

    def delete_table(data)
      table_name = data['TableName']
      table = find_table(table_name)
      tables.delete(table_name)
      table.delete
    end

    def list_tables(data)
      start_table = data['ExclusiveStartTableName']
      limit = data['Limit']

      all_tables = tables.keys
      start = 0

      if start_table
        if i = all_tables.index(start_table)
          start = i + 1
        end
      end

      limit ||= all_tables.size
      result_tables = all_tables[start, limit]
      response = { 'TableNames' => result_tables }

      if (start + limit ) < all_tables.size
        last_table = all_tables[start + limit -1]
        response.merge!({ 'LastEvaluatedTableName' => last_table })
      end
      response
    end

    def update_table(data)
      table = find_table(data['TableName'])
      table.update(data['ProvisionedThroughput']['ReadCapacityUnits'], data['ProvisionedThroughput']['WriteCapacityUnits'])
    end

    def self.delegate_to_table(*methods)
      methods.each do |method|
        define_method(method) do |data|
          find_table(data['TableName']).send(method, data)
        end
      end
    end

    delegate_to_table :put_item, :get_item, :delete_item, :update_item

    private
    def find_table(table_name)
      tables[table_name] or raise ResourceNotFoundException, "Table : #{table_name} not found"
    end

  end
end
