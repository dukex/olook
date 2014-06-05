# -*- encoding : utf-8 -*-
  require 'builder'

class MktXmlBuilder
  extend XmlHelper
  extend ActionView::Helpers::NumberHelper

  RENDERERS = {
    nextperformance: 'nextperformance_template.xml.erb',
    topster: 'topster_template.xml.erb',
    criteo: 'criteo_template.xml.erb',
    triggit: 'triggit_template.xml.erb',
    sociomantic: 'sociomantic_template.xml.erb',
    parceirosmkt: 'ilove_ecommerce_template.xml.erb',
    ilove_ecommerce: 'ilove_ecommerce_template.xml.erb',
    nano: 'nano_template.xml.erb',
    nano_interactive: 'nano_interactive_template.xml.erb',
    zanox: 'zanox_template.xml.erb',
    afilio: 'afilio_template.xml.erb',
    mt_performance: 'mt_performance_template.xml.erb',
    netaffiliation: 'netaffiliation_template.xml.erb',
    google_shopping: 'google_shopping_template.xml.erb',
    muccashop: 'muccashop_template.xml.erb',
    shopear: 'shopear_template.xml.erb',
    melt: 'melt_template.xml.erb',
    paraiso_feminino: 'paraiso_feminino_template.xml.erb',
    stylight: 'stylight_template.xml.erb',
    all_in: 'all_in.xml.erb',
    zoom: 'zoom_template.xml.erb',
    buscape: 'buscape_template.xml.erb',
    rise: 'rise_template.xml.erb',
    myestilo: 'myestilo_template.xml.erb',
    ingriffe: 'ingriffe_template.xml.erb'
  }

  def self.create_xmls
    create_xml(RENDERERS.keys)
  end

  def self.create_xml(templates)
    xmls = {}
    @products = load_products
    ids = Setting.mercadolivre_product_ids.split(',')
    @products_for_mercadolivre = Product.where({id: ids})

    templates.each do |template_name|
      xmls[template_name] = generate_for(template_name)
    end

    xmls
  end

  def self.upload(xmls)
    xmls.each {|template_name, xml| send_to_amazon(xml, "#{template_name}_data.xml") }
  end

  private

    def self.send_to_amazon (xml, file_name)
      bucket = ENV["RAILS_ENV"] == 'production' ? 'cdn-app' : 'cdn-app-staging'
      connection = Fog::Storage.new({
        :provider   => 'AWS'
      })
      directory = connection.directories.get(bucket)
      directory.files.create(
        :key    => "xml/#{file_name}",
        :body   => xml,
        "Content-Type" => "application/xml",
        :public => true)
    end


    def self.generate_for(template_name)
      begin
        renderer = get_renderer(template_name)
        renderer.result(binding)
      rescue => e
        puts "[XML] Erro ao processar template #{template_name}: #{e.backtrace.join('\n')}"
      end
    end

    def self.get_renderer(template_name)
      begin
        template_file_path = "app/views/xml/" + RENDERERS.fetch(template_name)
        ERB.new(File.read(template_file_path))
      rescue KeyError
        OpenStruct.new({result: ""})
      end
    end

    def self.load_products
      Product.includes(:pictures,:details).valid_for_xml(Product.xml_blacklist("products_blacklist").join(','))
    end
end
