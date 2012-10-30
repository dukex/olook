# -*- encoding : utf-8 -*-

require 'fileutils'
require 'yaml'

module MarketingReports
  class FileUploader

    TEMP_PATH = "#{Rails.root}/tmp/"

    def initialize(filename = "untitled.txt", file_content)
      @filename = filename
      @file_content = file_content
      @encoding = "ISO-8859-1" #"UTF-8"
    end

    def save_local_file
     File.open(TEMP_PATH+DateTime.now.strftime(@filename), 'w', :encoding => @encoding) do |file|
        file.write(@file_content) #.encode(@encoding).force_encoding(@encoding))
      end
    end

    def self.copy_file(filename)
      report_path = Rails.env.production? ? '/home/allinmail' : Rails.root
      FileUtils.copy(TEMP_PATH+DateTime.now.strftime(filename), "#{report_path}/#{filename}")
    end
  end
end
