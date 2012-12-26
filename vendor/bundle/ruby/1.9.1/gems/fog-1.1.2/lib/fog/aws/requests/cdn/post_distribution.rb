module Fog
  module CDN
    class AWS
      class Real

        require 'fog/aws/parsers/cdn/distribution'

        # create a new distribution in CloudFront
        #
        # ==== Parameters
        # * options<~Hash> - config for distribution.  Defaults to {}.
        #   REQUIRED:
        #   * 'S3Origin'<~Hash>:
        #     * 'DNSName'<~String> - origin to associate with distribution, ie 'mybucket.s3.amazonaws.com'
        #     * 'OriginAccessIdentity'<~String> - Optional: Used when serving private content
        #   or
        #   * 'CustomOrigin'<~Hash>:
        #     * 'DNSName'<~String> - origin to associate with distribution, ie 'www.example.com'
        #     * 'HTTPPort'<~Integer> - Optional HTTP port of origin, in [80, 443] or (1024...65535), defaults to 80
        #     * 'HTTPSPort'<~Integer> - Optional HTTPS port of origin, in [80, 443] or (1024...65535), defaults to 443
        #     * 'OriginProtocolPolicy'<~String> - Policy on using http vs https, in ['http-only', 'match-viewer']
        #   OPTIONAL:
        #   * 'CallerReference'<~String> - Used to prevent replay, defaults to Time.now.to_i.to_s
        #   * 'Comment'<~String> - Optional comment about distribution
        #   * 'CNAME'<~Array> - Optional array of strings to set as CNAMEs
        #   * 'DefaultRootObject'<~String> - Optional default object to return for '/'
        #   * 'Enabled'<~Boolean> - Whether or not distribution should accept requests, defaults to true
        #   * 'Logging'<~Hash>: Optional logging config
        #     * 'Bucket'<~String> - Bucket to store logs in, ie 'mylogs.s3.amazonaws.com'
        #     * 'Prefix'<~String> - Optional prefix for log filenames, ie 'myprefix/'
        #   * 'OriginAccessIdentity'<~String> - Used for serving private content, in format 'origin-access-identity/cloudfront/ID'
        #   * 'RequiredProtocols'<~String> - Optional, set to 'https' to force https connections
        #   * 'TrustedSigners'<~Array> - Optional grant of rights to up to 5 aws accounts to generate signed URLs for private content, elements are either 'Self' for your own account or an AWS Account Number
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'DomainName'<~String>: Domain name of distribution
        #     * 'Id'<~String> - Id of distribution
        #     * 'LastModifiedTime'<~String> - Timestamp of last modification of distribution
        #     * 'Status'<~String> - Status of distribution
        #     * 'DistributionConfig'<~Array>:
        #       * 'CallerReference'<~String> - Used to prevent replay, defaults to Time.now.to_i.to_s
        #       * 'CNAME'<~Array> - array of associated cnames
        #       * 'Comment'<~String> - comment associated with distribution
        #       * 'Enabled'<~Boolean> - whether or not distribution is enabled
        #       * 'Logging'<~Hash>:
        #         * 'Bucket'<~String> - bucket logs are stored in
        #         * 'Prefix'<~String> - prefix logs are stored with
        #       * 'Origin'<~String> - s3 origin bucket
        #       * 'TrustedSigners'<~Array> - trusted signers
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AmazonCloudFront/latest/APIReference/CreateDistribution.html

        def post_distribution(options = {})
          options['CallerReference'] = Time.now.to_i.to_s
          data = '<?xml version="1.0" encoding="UTF-8"?>'
          data << "<DistributionConfig xmlns=\"http://cloudfront.amazonaws.com/doc/#{@version}/\">"
          for key, value in options
            case value
            when Array
              for item in value
                data << "<#{key}>#{item}</#{key}>"
              end
            when Hash
              data << "<#{key}>"
              for inner_key, inner_value in value
                data << "<#{inner_key}>#{inner_value}</#{inner_key}>"
              end
              data << "</#{key}>"
            else
              data << "<#{key}>#{value}</#{key}>"
            end
          end
          data << "</DistributionConfig>"
          request({
            :body       => data,
            :expects    => 201,
            :headers    => { 'Content-Type' => 'text/xml' },
            :idempotent => true,
            :method     => 'POST',
            :parser     => Fog::Parsers::CDN::AWS::Distribution.new,
            :path       => "/distribution"
          })
        end

      end
    end
  end
end