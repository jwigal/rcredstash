class CredStash::Repository
  class Item
    attr_reader :key, :contents, :name, :version, :hmac

    def initialize(key: nil, contents: nil, name: nil, version: nil, hmac: nil)
      @key = key
      @contents = contents
      @name = name
      @version = version
      @hmac = hmac
    end
  end

  class DynamoDB
    def initialize(client: nil)
      @client = client || Aws::DynamoDB::Client.new
    end

    def get(name)
      select(name, limit: 1).first.tap do |item|
        unless item
          raise CredStash::ItemNotFound, "#{name} is not found"
        end
      end
    end

    def select(name, limit: nil)
      params = {
        table_name:  'credential-store',
        consistent_read: true,
        key_condition_expression: "#name = :name",
        expression_attribute_names: { "#name" => "name"},
        expression_attribute_values: { ":name" => name }
      }

      if limit
        params[:limit] = limit
        params[:scan_index_forward] = false
      end

      @client.query(params).items.map do |item|
        Item.new(
          key: item["key"],
          contents: item["contents"],
          name: item["name"],
          version: item["version"]
        )
      end
    end

    def put(item)
      @client.put_item(
        table_name:  'credential-store',
        item: {
          name: item.name,
          version: item.version,
          key: item.key,
          contents: item.contents,
          hmac: item.hmac
        },
        condition_expression: "attribute_not_exists(#name)",
        expression_attribute_names: { "#name" => "name" },
      )
    end

    def list
      @client.scan(
        table_name:  'credential-store',
        projection_expression: '#name, version',
        expression_attribute_names: { "#name" => "name" },
      ).items.map do |item|
        Item.new(name: item['name'], version: item['version'])
      end
    end
  end

  def self.default_storage
    DynamoDB.new
  end

  def initialize(storage: Repository.default_storage)
    @storage = storage
  end

  def get(name)
    @storage.get(name)
  end

  def put(item)
    @storage.put(item)
  end
end