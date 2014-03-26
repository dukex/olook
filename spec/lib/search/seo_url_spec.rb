# encoding: utf-8
require 'spec_helper'

describe SeoUrl do
  before do
    described_class.stub(:all_categories).and_return({ "Sapato" => [], "Roupa" => [], "Acessório" => [], "Bolsa" => [] })
    described_class.stub(:db_subcategories).and_return(["Amaciante","Bota", "Camiseta"])
    described_class.stub(:db_brands).and_return(["Colcci","Olook"])
  end

  describe "#parse_params" do
    context "Main keys" do
      context "that include collection themes" do
        subject { described_class.new(path: '/colecoes/p&b', path_positions: '/colecoes/:collection_theme:') }
        it { expect(subject.parse_params).to have_key(:collection_theme)  }
        it { expect(subject.parse_params[:collection_theme]).to match(/p&b/i) }
      end
      context "that includes brands" do
        subject { described_class.new(path: '/marcas/olook', path_positions: '/marcas/:brand:') }
        it { expect(subject.parse_params).to have_key(:brand)  }
        it { expect(subject.parse_params[:brand]).to match(/Olook/i) }
      end
      context "that includes category" do
        subject { described_class.new(path: '/sapato', path_positions: '/:category:/_:brand::subcategory:-/_:color::size::heel:-') }
        it { expect(subject.parse_params).to have_key(:category)  }
        it { expect(subject.parse_params[:category]).to match(/Sapato/i) }
      end
    end
    context "Main keys and filters" do
      context "that includes brands as main category as filter" do
        subject { described_class.new(path: '/sapato/olook', path_positions: '/:category:/-:brand::subcategory:-/_:color::size::heel:-') }
        it { expect(subject.parse_params[:brand]).to match(/Olook/i) }
        it { expect(subject.parse_params[:category]).to match(/Sapato/i) }
      end
      context "that includes category as main" do
        context "brands as filter" do
          context "one brand" do
            subject { described_class.new(path: '/sapato/olook', path_positions: '/:category:/-:brand::subcategory:-/_:color::size::heel:-') }
            it { expect(subject.parse_params[:category]).to match(/Sapato/i) }
            it { expect(subject.parse_params[:brand]).to match(/Olook/i) }
          end
          context "multiple brands" do
            subject { described_class.new(path: '/sapato/olook-colcci', path_positions: '/:category:/-:brand::subcategory:-/_:color::size::heel:-') }
            it { expect(subject.parse_params[:category]).to match(/Sapato/i) }
            it { expect(subject.parse_params[:brand]).to match(/Olook/i) }
            it { expect(subject.parse_params[:brand]).to match(/Colcci/i) }
          end
        end
        context "and filtering by care products" do
          subject { described_class.new(path: '/sapato/conforto-amaciante-palmilha', path_positions: '/:category:/-:brand::subcategory:-/_:care::color::size::heel:-') }
          it { expect(subject.parse_params[:category]).to match(/Sapato/i) }
          it { expect(subject.parse_params[:care]).to match(/amaciante-palmilha/i) }
        end
      end
      context "filtering by subcategory" do
        context "one subcategory" do
          subject { described_class.new(path: '/sapato/bota', path_positions:  '/:category:/-:brand::subcategory:-/_:care::color::size::heel:-') }
          it { expect(subject.parse_params[:subcategory]).to match(/bota/i) }
        end
        context "multiple subcategories" do
          subject { described_class.new(path: '/sapato/bota-scarpin', path_positions: '/:category:/-:brand::subcategory:-/_:care::color::size::heel:-') }
          it { expect(subject.parse_params[:category]).to match(/sapato/i) }
          it { expect(subject.parse_params[:subcategory]).to match(/bota/i) }
          it { expect(subject.parse_params[:subcategory]).to match(/scarpin/i) }
        end
      end
      context "filtering by colors and size" do
        context "one color" do
          subject { described_class.new(path: '/sapato/bota/cor-azul', path_positions: '/:category:/-:brand::subcategory:-/_:care::color::size::heel:-') }
          it { expect(subject.parse_params[:subcategory]).to match(/bota/i) }
          it { expect(subject.parse_params[:color]).to match(/azul/i) }
        end
        context "one size" do
          subject { described_class.new(path: '/sapato/bota/tamanho-37', path_positions: '/:category:/-:brand::subcategory:-/_:care::color::size::heel:-') }
          it { expect(subject.parse_params[:subcategory]).to match(/bota/i) }
          it { expect(subject.parse_params[:size]).to match(/37/i) }
        end
        context "multiple colors" do
          subject { described_class.new(path: '/sapato/bota/cor-azul-amarelo', path_positions: '/:category:/-:brand::subcategory:-/_:care::color::size::heel:-') }
          it { expect(subject.parse_params[:subcategory]).to match(/bota/i) }
          it { expect(subject.parse_params[:color]).to match(/azul-amarelo/i) }
        end
        context "multiple sizes" do
          subject { described_class.new(path: '/sapato/bota/tamanho-37-40', path_positions: '/:category:/-:brand::subcategory:-/_:care::color::size::heel:-') }
          it { expect(subject.parse_params[:subcategory]).to match(/bota/i) }
          it { expect(subject.parse_params[:size]).to match(/37-40/i) }
        end
        context "colors and sizes" do
          subject { described_class.new(path: '/sapato/bota/cor-azul_tamanho-37', path_positions: '/:category:/-:brand::subcategory:-/_:care::color::size::heel:-') }
          it { expect(subject.parse_params[:subcategory]).to match(/bota/i) }
          it { expect(subject.parse_params[:color]).to match(/azul/i) }
          it { expect(subject.parse_params[:size]).to match(/37/i) }
        end
      end
    end

    context "filtering by ordenation" do
      context "lower price" do
        subject { described_class.new(path: '/sapato?por=menor-preco') }
        it { expect(subject.parse_params[:sort]).to match(/retail_price/i) }
      end

      context "greater price" do
        subject { described_class.new(path: '/sapato?por=maior-preco') }
        it { expect(subject.parse_params[:sort]).to match(/-retail_price/i) }
      end

      context "lower discount" do
        subject { described_class.new(path: '/sapato?por=maior-desconto') }
        it { expect(subject.parse_params[:sort]).to match(/-desconto/i) }
      end
    end

    context "ordering by price range" do
      subject { described_class.new(path: '/sapato?preco=100-300') }
      it { expect(subject.parse_params[:price]).to match(/100-300/i) }
    end

    context "with custom path_positions" do
      subject { described_class.new(path: '/marcas/olook/sapato', path_positions: '/marcas/:brand:/-:category::subcategory-/_:color::size::heel:-') }
      it { expect(subject.parse_params[:brand]).to match(/Olook/i) }
    end
  end

  describe "#build_link_for" do
    context 'without sections' do
      subject { described_class.new(path_positions: '') }
      it { expect(subject.build_link_for(category: [ 'sapato' ])).to eq('/?categoria=sapato') }
      it { expect(subject.build_link_for(subcategory: [ 'bota' ])).to eq('/?modelo=bota') }
    end

    context 'with one section' do
      subject { described_class.new(path_positions: '/:category:/') }
      it { expect(subject.build_link_for(category: [ 'sapato' ])).to eq('/sapato') }
      it { expect(subject.build_link_for(subcategory: [ 'bota' ])).to eq('/?modelo=bota') }
      it { expect(subject.build_link_for(category: [ 'sapato' ], subcategory: [ 'bota' ])).to eq('/sapato?modelo=bota') }
    end

    context "with fake section" do
      subject { described_class.new(path_positions: '/marcas/-:brand:-/-:category::subcategory:-/-:care::color::size::heel:_')}
      it { expect(subject.build_link_for).to eq('/marcas') }
      it { expect(subject.build_link_for(brand: ['olook'])).to eq('/marcas/olook') }
      it { expect(subject.build_link_for(brand: ['olook'], category: ['roupa'])).to eq('/marcas/olook/roupa') }
      it { expect(subject.build_link_for(brand: ['olook'], category: ['roupa'], size: ['P'])).to eq('/marcas/olook/roupa/tamanho-P') }
      it { expect(subject.build_link_for(brand: ['olook'], category: ['roupa'], size: ['P'], color: ['azul'])).to eq('/marcas/olook/roupa/cor-azul_tamanho-P') }
    end
  end
end

