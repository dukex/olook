module Fog
  module AWS
    class AutoScaling

      class Real

        require 'fog/aws/parsers/auto_scaling/basic'

        # Deletes the specified launch configuration.
        #
        # The specified launch configuration must not be attached to an Auto
        # Scaling group. Once this call completes, the launch configuration is
        # no longer available for use.
        #
        # ==== Parameters
        # * launch_configuration_name<~String> - The name of the launch
        #   configuration.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_DeleteLaunchConfiguration.html
        #
        def delete_launch_configuration(launch_configuration_name)
          request({
            'Action'                  => 'DeleteLaunchConfiguration',
            'LaunchConfigurationName' => launch_configuration_name,
            :parser                   => Fog::Parsers::AWS::AutoScaling::Basic.new
          })
        end

      end

      class Mock

        def delete_launch_configuration(launch_configuration_name)
          Fog::Mock.not_implemented
        end

      end

    end
  end
end
