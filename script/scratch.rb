require 'aws-sdk'
require 'dotenv'

Dotenv.load

client = Aws::DynamoDB::Client.new(region: ENV["AWS_REGION"])
h = {put_request: {item: {"pool_id" => 1, "version" => 1}}}
client.batch_write_item(request_items: {ENV["DYNAMO_DB_POOL_VERSION_TABLE"] => [h]}, return_consumed_capacity: "NONE")