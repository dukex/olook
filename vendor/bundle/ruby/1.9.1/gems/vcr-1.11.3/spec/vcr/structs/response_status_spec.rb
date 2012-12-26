require 'spec_helper'

describe VCR::ResponseStatus do
  describe '.from_net_http_response' do
    let(:response) { VCR::YAML.load_file("#{VCR::SPEC_ROOT}/fixtures/#{YAML_SERIALIZATION_VERSION}/example_net_http_response.yml") }
    subject { described_class.from_net_http_response(response) }

    it            { should be_instance_of(described_class) }
    its(:code)    { should eq(200) }
    its(:message) { should eq('OK') }
  end

  it_performs 'status message normalization' do
    def instance(message)
      described_class.new(200, message)
    end
  end
end
