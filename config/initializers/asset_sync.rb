# -*- encoding : utf-8 -*-
AssetSync.configure do |config|
  config.aws_access_key = 'AKIAJ2WH3XLYA24UTAJQ'
  config.aws_access_secret = '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'
  config.aws_bucket = Rails.env.production? ? 'cdn-app.olook.com.br' : 'cdn-app-staging.olook.com.br'
  # config.aws_region = "eu-west-1"
  config.existing_remote_files = "delete"
end
