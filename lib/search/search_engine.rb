require 'active_support/inflector'
class SearchEngine
  include Search::Paginable
  SEARCH_CONFIG = YAML.load_file("#{Rails.root}/config/cloud_search.yml")[Rails.env]
  BASE_URL = SEARCH_CONFIG["search_domain"] + "/2011-02-01/search"

  MULTISELECTION_SEPARATOR = '-'
  RANGED_FIELDS = HashWithIndifferentAccess.new({'price' => '', 'heel' => '', 'inventory' => ''})
  IGNORE_ON_URL = Set.new(['inventory', :inventory, 'is_visible', :is_visible, 'in_promotion', :in_promotion])
  PERMANENT_FIELDS_ON_URL = Set.new([:is_visible, :inventory])

  RETURN_FIELDS = [:subcategory,:name,:brand,:image,:retail_price,:price,:backside_image,:category,:text_relevance,:inventory]

  SEARCHABLE_FIELDS = [ :care, :sort, :term, :excluded_brand]
  SEARCHABLE_FIELDS.each do |attr|
    define_method "#{attr}=" do |v|
      @expressions[attr] = v.to_s.split(MULTISELECTION_SEPARATOR)
    end
  end

  [:product_id, :brand, :subcategory, :visibility,
  :color, :size].each do |attr|
    define_method "#{attr}=" do |v|
      @structured.or do |s|
        v.to_s.split(MULTISELECTION_SEPARATOR).each do |_v|
          s.field attr, _v
        end
      end
    end
  end

  NESTED_FILTERS = {
    category: [ :subcategory ]
  }

  DEFAULT_SORT = "age,-inventory,-text_relevance"

  attr_accessor :skip_beachwear_on_clothes
  attr_accessor :df

  attr_reader :current_page, :result
  attr_reader :structured, :sort_field

  def initialize attributes = {}, is_smart = false
    @structured = SearchedProduct.structured(:and)
    @expressions = HashWithIndifferentAccess.new
    @structured.and do |s|
      s.field 'is_visible', 1
      s.field 'inventory', [1, nil]
      s.field 'in_promotion', 0
      s.or do |_s|
        _s.field 'visibility', Product::PRODUCT_VISIBILITY[:site]
        _s.field 'visibility', Product::PRODUCT_VISIBILITY[:all]
      end
    end
    @facets = []
    @is_smart = is_smart
    default_facets

    Rails.logger.debug("SearchEngine received these params: #{attributes.inspect}")
    @current_page = 1

    attributes.each do |k, v|
      next if k.blank?
      begin
        self.send("#{k}=", v)
      rescue NoMethodError
      end
    end
    validate_sort_field
    Rails.logger.debug("SearchEngine processed these params: #{expressions.inspect}")

    @redis = Redis.connect(url: ENV['REDIS_CACHE_STORE'])
  end

  def term= term
    @query = URI.encode(term) if term
  end

  def term
    @query
  end

  # TODO: Mudar a forma que o recebe o collection_theme pois
  # o ideal é modificar o MULTISELECTION_SEPARATOR para ','
  # e passar a usar parameterize na indexação e mudar as urls.
  # Depende de fazer um tradutor dos links antigos para os novos.
  def collection_theme=(val)
    @structured.and 'collection_theme', val.to_s unless val.blank?
  end

  def heel= heel
    if heel =~ /^(-?\d+-\d+)+$/
      hvals = heel.split('-')
      while hvals.present?
        val = hvals.shift(2)
        @structured.or "heeluint", val
      end
    end
    self
  end

  def price= price
    if price.to_s =~ /^(-?\d+-\d+)+$/
      pvals = price.split('-')
      while pvals.present?
        val_arr = pvals.shift(2)
        @structured.or "retail_price", val_arr
      end
    end
    self
  end

  def sort= sort_field
    @sortables ||= Set.new(['retail_price', '-retail_price', 'desconto', '-desconto','age'])
    if sort_field.present? && @sortables.include?(sort_field)
      @is_smart = false
      @sort_field = "#{ sort_field }"
    end
    self
  end

  def page=(val)
    for_page(val)
  end

  def limit=(val)
    with_limit(val)
  end

  def admin=(val)
    for_admin if val
  end

  def category= _category
    if _category == "roupa" && !@skip_beachwear_on_clothes
      @structured.or do |s|
        s.field "category", "roupa"
        s.field "category", "moda praia"
        s.field "category", "lingerie"
      end
    elsif _category.is_a?(Array) 
      @structured.or do |s|
        _category.each do |c|
          s.field "category", c
        end
      end
    elsif _category == 'plus-size'
      @structured.and("category", _category)
    else
      @structured.or do |s|
        _category.to_s.split(MULTISELECTION_SEPARATOR).each do |c|
          s.field "category", c
        end
      end
    end
  end

  def expressions
    HashWithIndifferentAccess.new(@structured.nodes_by_field)
  end

  def total_results
    @result.hits["found"] || 0
  end

  def cache_key
    key = build_url_for(limit: @limit, start: self.start_item)
    Digest::SHA1.hexdigest(df.to_s + "/" + key.to_s)
  end

  def filters_applied(filter_key, filter_value)
    filter_value = ActiveSupport::Inflector.transliterate(filter_value).downcase
    filter_params = append_or_remove_filter(filter_key, filter_value, formatted_filters)
    filter_params
  end

  def remove_filter filter
    parameters = formatted_filters
    parameters.delete_if {|k| IGNORE_ON_URL.include? k }
    parameters[filter.to_sym] = []
    if NESTED_FILTERS[filter.to_sym]
      NESTED_FILTERS[filter.to_sym].each do |key|
        parameters[key.to_sym] = []
      end
    end
    parameters
  end

  def replace_filter(filter, filter_value)
    parameters = formatted_filters
    parameters.delete_if {|k| IGNORE_ON_URL.include? k }
    parameters[filter.to_sym] = [filter_value]
    if NESTED_FILTERS[filter.to_sym]
      NESTED_FILTERS[filter.to_sym].each do |key|
        parameters[key.to_sym] = []
      end
    end
    parameters
  end

  def current_filters
    parameters = formatted_filters
    parameters.delete_if {|k| IGNORE_ON_URL.include? k }
    parameters
  end

  def filters(options={})
    @filters_result ||= {}
    url = build_filters_url(options)
    @filters_result[url] ||= -> {
      f = fetch_result(url, parse_facets: true, parser: SearchedProduct)
      f.set_groups('subcategory', subcategory_without_care_products(f))
      f
    }.call
  end

  def products(pagination = true)
    url = build_url_for(pagination ? {limit: @limit, start: self.start_item} : {})
    @result ||= fetch_result(url, parse_products: true, parser: SearchedProduct)
    @result.products
  end

  def range_values_for(filter)
    if /(?<min>\d+)\.\.(?<max>\d+)/ =~ expressions[filter].to_s
      { min: (min.to_d/100.0).round.to_s, max: (max.to_d/100.0).round.to_s }
    end
  end

  def filter_value(filter)
    expressions[filter]
  end

  def filter_selected?(filter_key, filter_value)
    if filter_key == :price
      arr = filter_value.split("-")
      filter_value = format_price_range(arr[0], arr[1])
    end

    if values = expressions[filter_key]
      if RANGED_FIELDS[filter_key]
        values.any? do |v|
          /#{filter_value.gsub('-', '..')}/ =~ v
        end
      else
        values.map{|_v| ActiveSupport::Inflector.transliterate(_v).downcase.titleize}.include?(ActiveSupport::Inflector.transliterate(filter_value).downcase.titleize)
      end
    else
      false
    end
  end

  def selected_filters_for category
    if category == "price"
      return price_selected_filters expressions
    else
      return expressions[category.to_sym] || []
    end
  end

  def has_any_filter_selected?
    _filters = expressions.clone
    _filters.delete(:category)
    _filters.delete(:price)
    _filters.delete_if{|k,v| IGNORE_ON_URL.include?( k )}
    _filters.delete_if{|k,v| v.empty?}
    _filters.values.flatten.any?
  end

  def build_filters_url(options={})
    bq = build_boolean_expression(options)
    bq += "facet=#{@facets.join(',')}&facet-brand_facet-top-n=100" if @facets.any?
    q = @query ? "q=#{@query}&" : ""
    "http://#{BASE_URL}?#{q}#{bq}"
  end


  def for_admin
    @structured.and do |s|
      s.or do |_s|
        _s.field 'is_visible', 0
        _s.field 'is_visible', 1
      end
      s.or do |_s|
       _s.field 'in_promotion', 0
       _s.field 'in_promotion', 1
      end
      s.field 'inventory', [0, nil]
    end
    self
  end

  def default_facets
    @facets << "brand_facet"
    @facets << "subcategory"
    @facets << "color"
    @facets << "heel"
    @facets << "care"
    @facets << "size"
    @facets << "category"
    @facets << 'collection_theme'
    self
  end

  def build_url_for(options={})
    options[:start] ||= 0
    options[:limit] ||= 50
    bq = build_boolean_expression
    bq += "facet=#{@facets.join(',')}&" if @facets.any?
    q = @query ? "?q=#{@query}&" : "?"
    if @is_smart
      "http://#{BASE_URL}#{q}#{bq}return-fields=#{RETURN_FIELDS.join(',')}&start=#{ options[:start] }&#{ ranking }&rank=#{smart_ranking_params}&size=#{ options[:limit] }"
    else
      "http://#{BASE_URL}#{q}#{bq}return-fields=#{RETURN_FIELDS.join(',')}&start=#{ options[:start] }&rank=#{ @sort_field }&size=#{ options[:limit] }"
    end
  end

  def ranking
    "rank-exp=r_inventory%2Br_brand_regulator%2Br_age"
  end


  def build_boolean_expression(options={})
    bq = []
    _expressions = @expressions.clone
    cares = _expressions.delete('care')
    if cares.present?
      subcategories = _expressions.delete('subcategory')
      vals = cares.map { |v| "(field care '#{v}')" }
      vals.concat(subcategories.map { |v| "(field subcategory '#{v}')" }) if subcategories.present?
      bq << ( vals.size > 1 ? "(or #{vals.join(' ')})" : vals.first )
    end

    remove_excluded_brands(bq, _expressions)
    _expressions.each do |field, values|
      next if options[:use_fields] && !options[:use_fields].include?(field.to_sym) && PERMANENT_FIELDS_ON_URL.exclude?(field.to_sym)
      next if values.empty?
      if RANGED_FIELDS[field]
        bq << "(or #{values.join(' ')})"
      elsif values.is_a?(Array) && values.any?
        vals = values.map { |v| "(field #{field} '#{v}')" } unless values.empty?
        bq << ( vals.size > 1 ? "(or #{vals.join(' ')})" : vals.first )
      end
    end

    if bq.size == 1
      "bq=#{ERB::Util.url_encode "(and #{@structured.to_url} #{bq.first})"}&"
    elsif bq.size > 1
      "bq=#{ERB::Util.url_encode "(and #{@structured.to_url} #{bq.join(' ')})"}&"
    else
      "bq=#{ERB::Util.url_encode @structured.to_url}&"
    end
  end

  def subcategory_without_care_products(filters)
    _filters = filters.grouped_products('subcategory')
    _filters.delete_if{|c| Product::CARE_PRODUCTS.map(&:parameterize).include?(c.parameterize) } if _filters
    _filters
  end

  def key_for field
    chosen_filter_values = expressions[field.to_sym] || []
    # Use Digest::SHA1.hexdigest ??
    key = expressions[:category].to_a.join("-") + "/" + field.to_s + "/" + chosen_filter_values.join("-")
    Rails.logger.info "[cloudsearch] #{field}_key=#{key}"
    key
  end

  private

  def fetch_result(url, options={})
    Search::Retriever.new(redis: @redis, logger: Rails.logger).fetch_result(url, options)
  end

  def append_or_remove_filter(filter_key, filter_value, filter_params)
    filter_params[filter_key] ||= [filter_value.downcase]
    if filter_selected?(filter_key, filter_value)
      filter_params[filter_key] -= [ filter_value.downcase ]
    else
      filter_params[filter_key] << filter_value.downcase
    end
    filter_params[filter_key].uniq!
    filter_params
  end

  def formatted_filters
    filter_params = HashWithIndifferentAccess.new
    expressions.clone.each do |k, v|
      next if IGNORE_ON_URL.include?(k)
      next if k == 'visibility'
      filter_params[k] ||= []
      if RANGED_FIELDS[k]
        v.each do |_v|
          /(?<min>\d+)\.\.(?<max>\d+)/ =~ _v.to_s
          if k.to_s == 'price'
            min = (min.to_d / 100.0).round
            max = (max.to_d / 100.0).round
          end
          filter_params[k] << "#{min}-#{max}"
        end
      else
        filter_params[k].concat v.map { |_v| _v.downcase }
      end
    end
    filter_params[:sort] = ( @sort_field == DEFAULT_SORT ? nil : @sort_field )

    filter_params
  end

  def remove_excluded_brands(bq, _expressions)
    return unless _expressions["excluded_brand"].present?
    excluded_brands = _expressions["excluded_brand"]
    _expressions.delete("excluded_brand")
    vals = excluded_brands.map { |v| "(field brand '#{v}')" } unless excluded_brands.empty?
    bq << ( "(not (or #{vals.join(' ')}))" )
  end

  def validate_sort_field
    if @sort_field.nil? || @sort_field == "" || @sort_field == 0 || @sort_field == "0"
      @sort_field = DEFAULT_SORT
    end
  end

  def format_price_range(min,max)
    "#{min.to_i*100}..#{[max.to_i*100-1, 0].max}"
  end

  def price_selected_filters _expressions
    return [] unless _expressions[:price]
    price_filters = _expressions[:price].map do |e| 
      a = e.gsub("retail_price:","").split("..")
      a[0] = (a[0].to_i/100).to_s
      a[1] = ((a[1].to_i+1)/100).to_s
      a.join("-")
    end
    price_filters || []
  end

  def smart_ranking_params
    "-exp,#{ @sort_field }".split(",").reject{|v| v.blank?}.join(",")
  end
end
