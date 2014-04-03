# -*- encoding : utf-8 -*-
module Seo
  class SeoManager
    DEFAULT_PAGE_TITLE = 'Sapatos Femininos e Roupas Femininas'
    DEFAULT_PAGE_DESCRIPTION = 'test'

    attr_accessor :url, :page_title, :page_description

    def initialize url, options={}
      @url = url
    end

    def select_meta_tag
      choose_meta_tag
    end

    private

      def choose_meta_tag
        title = search_meta_tag[:title] || DEFAULT_PAGE_TITLE
        description = search_meta_tag[:description] || DEFAULT_PAGE_DESCRIPTION
        {title: "#{title} | Olook" , description: description}
      end

      def extract_meta_tag_text
      end

      def category_meta_tag
        subcategory_name = extract_subcategories unless subcategory.blank?
        category_name = category.first unless category.blank?
        return "#{subcategory_name} #{color_formatted}" if !subcategory.blank? && !color.blank?
        return "#{subcategory_name}" unless subcategory.blank?
        if category && category_name
          return "#{CATEGORY_TEXT[category_name.downcase.to_sym]} #{color_formatted}" unless color.blank?
          return "#{CATEGORY_TEXT[category_name.downcase.to_sym]}" 
        end
        ""
      end

      def extract_subcategories
       if subcategory.size > 3
         "#{subcategory.map(&:capitalize).first(3).join(" - ")} e outros"
       else
         subcategory.map(&:capitalize).join(" - ")
       end
      end

      def search_meta_tag
        header = find_parent_meta_tag(url.dup)
        {title: header.try(:page_title), description: header.try(:page_description)}
      end

      def find_parent_meta_tag(_url)
        return nil if _url.blank? || _url[0] != "/"
        header = Header.for_url(_url).first
        return header if header
        find_parent_meta_tag(_url.sub(%r{/[^/]*$}, ''))
      end
  end
end
