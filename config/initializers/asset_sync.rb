AssetSync.configure do |config|
  config.fog_provider = 'AWS'
  config.aws_access_key_id = 'AKIAJ2WH3XLYA24UTAJQ'
  config.aws_secret_access_key = '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'
  if Rails.env.staging?
    bucket = 'cdn-app-staging'
  else
    bucket = 'cdn-app'
  end

  config.fog_directory = bucket 
  
  # Increase upload performance by configuring your region
  config.fog_region = 'us-east-1'
  #
  # Don't delete files from the store
  config.existing_remote_files = "delete"
  #
  # Automatically replace files with their equivalent gzip compressed version
  config.gzip_compression = true
  #
  # Use the Rails generated 'manifest.yml' file to produce the list of files to 
  # upload instead of searching the assets directory.
  #config.manifest = true
  #
  # Fail silently.  Useful for environments such as Heroku
  # config.fail_silently = true
end
