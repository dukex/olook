# encoding: utf-8
require 'spec_helper'

describe SeoUrl do
  before do
    described_class.stub(:all_subcategories).and_return(["Amaciante","Bota"])
    described_class.stub(:all_brands).and_return(["Colcci","Olook"])
  end
  describe ".parse" do
    context "when given parameters has subcategory and filters" do
      subject { SeoUrl.parse("sapatos/amaciante/tamanho-36-p_cor-azul-vermelho") }

      it { expect(subject).to be_a(Hash)  }
      it { expect(subject.keys).to include('size')  }
      it { expect(subject[:size]).to eq '36-p' }

      it { expect(subject.keys).to include('color')  }
      it { expect(subject[:color]).to eq 'azul-vermelho' }

      it { expect(subject.keys).to include('subcategory')  }
      it { expect(subject[:subcategory]).to eq 'amaciante' }

      context "should have access with string key" do
        it { expect(subject['subcategory']).to eq 'amaciante' }
        it { expect(subject['color']).to eq 'azul-vermelho' }
        it { expect(subject['size']).to eq '36-p' }

      end
    end


    context "when given parameters has no subcategory" do
      subject { SeoUrl.parse("sapatos/tamanho-36-p_cor-azul-vermelho") }
      it { expect(subject.keys).to_not include('subcategory')  }
      it { expect(subject[:subcategory]).to be_nil }

      it { expect(subject.keys).to include('size')  }
      it { expect(subject[:size]).to eq '36-p' }

      it { expect(subject.keys).to include('color')  }
      it { expect(subject[:color]).to eq 'azul-vermelho' }
    end

    context "when given parameters has subcategory, but not other filters" do
      subject { SeoUrl.parse("sapatos/amaciante-bota") }
      it { expect(subject.keys).to include('subcategory')  }
      it { expect(subject[:subcategory]).to eq 'amaciante-bota' }

      it { expect(subject.keys).to_not include('color')  }
      it { expect(subject[:color]).to be_nil }

      it { expect(subject.keys).to_not include('size')  }
      it { expect(subject[:size]).to be_nil }
    end

    context "when given parameters has brand and subcategory together" do
      subject { SeoUrl.parse("sapatos/amaciante-bota-colcci-olook") }
      it { expect(subject.keys).to include('subcategory')  }
      it { expect(subject[:subcategory]).to eq 'amaciante-bota' }

      it { expect(subject.keys).to include('brand')  }
      it { expect(subject[:brand]).to eq 'colcci-olook' }
    end

    context "when there's no parameters and subcategories" do
      subject { SeoUrl.parse("sapatos") }

      it { expect(subject.keys).to include('category')  }
      it { expect(subject[:category]).to eq 'sapatos' }
      it { expect(subject[:subcategory]).to be_nil }
      it { expect(subject[:brand]).to be_nil }
      it { expect(subject[:size]).to be_nil }
      it { expect(subject[:color]).to be_nil }
    end

    context "when there's no subcategories but has filters" do
      subject { SeoUrl.parse("sapato/tamanho-36_cor-azul-preto") }

      it { expect(subject[:category]).to eq 'sapato' }
      it { expect(subject[:subcategory]).to be_nil }
      it { expect(subject[:size]).to eq '36' }
      it { expect(subject[:color]).to eq 'azul-preto' }
    end
  end

  describe '.build' do
    context "when given parameters has subcategory and filters" do
      subject { SeoUrl.build(category: ['sapatos'], subcategory: ['amaciante'], size: ['36', 'p'], color: ['azul', 'vermelho']) }
      it { expect(subject).to eq({ parameters: "sapatos/amaciante/tamanho-36-p_cor-azul-vermelho" }) }
    end

    context "when given parameters has no subcategory" do
      subject { SeoUrl.build(category: ["sapatos"], size: ['36', 'p'], color: ['azul','vermelho']) }
      it { expect(subject).to eq({ parameters: "sapatos/tamanho-36-p_cor-azul-vermelho" }) }
    end

    context "when given parameters has subcategory, but not other filters" do
      subject { SeoUrl.build(category: ['sapatos'], subcategory: ['amaciante', 'bota']) }
      it { expect(subject).to eq({ parameters: "sapatos/amaciante-bota" }) }
    end

    context "when given parameters has brand and subcategory together" do
      subject { SeoUrl.build(category: [ 'sapatos' ], subcategory: ['amaciante', 'bota'], brand: ['colcci', 'olook']) }
      it { expect(subject).to eq({ parameters: "sapatos/amaciante-bota-colcci-olook" }) }
    end

    context "when there's no parameters and subcategories" do
      subject { SeoUrl.build(category: ["sapatos"]) }
      it { expect(subject).to eq({ parameters: "sapatos" }) }
    end

    context "when there's no subcategories but has filters" do
      subject { SeoUrl.build(category: ['sapato'], size: ['36'], color: ['azul', 'preto']) }
      it { expect(subject).to eq({ parameters: "sapato/tamanho-36_cor-azul-preto" }) }
    end

    context "when has accents" do
      it { expect(SeoUrl.build(category: ['sapato'], subcategory: ['Sandália'], size: ['36', 'p'], color: ['azul', 'vermelho'])).
           to eq({ parameters: "sapato/sandalia/tamanho-36-p_cor-azul-vermelho" }) }
      it { expect(SeoUrl.build(category: ['sapato'], subcategory: ['rasteira'], size: ['36', 'p'], color: ['azul', 'Onça'])).
           to eq({ parameters: "sapato/rasteira/tamanho-36-p_cor-azul-onca" }) }
      it { expect(SeoUrl.build(category: ['Acessório'], subcategory: ['rasteira'], size: ['36', 'p'], color: ['azul', 'Onça'])).
           to eq({ parameters: "acessorio/rasteira/tamanho-36-p_cor-azul-onca" }) }
    end
  end
end
