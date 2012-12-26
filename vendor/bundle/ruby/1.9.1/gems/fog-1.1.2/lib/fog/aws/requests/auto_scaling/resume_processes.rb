module Fog
  module AWS
    class AutoScaling

      class Real

        require 'fog/aws/parsers/auto_scaling/basic'

        # Resumes Auto Scaling processes for an Auto Scaling group.
        #
        # ==== Parameters
        # * auto_scaling_group_name'<~String> - The name or Amazon Resource
        #   Name (ARN) of the Auto Scaling group.
        # * options<~Hash>:
        #   * 'ScalingProcesses'<~Array> - The processes that you want to
        #     resume. To resume all process types, omit this parameter.
        #
        # ==== Returns
        # * response<~Excon::Response>:
        #   * body<~Hash>:
        #     * 'ResponseMetadata'<~Hash>:
        #       * 'RequestId'<~String> - Id of request
        #
        # ==== See Also
        # http://docs.amazonwebservices.com/AutoScaling/latest/APIReference/API_ResumeProcesses.html
        #
        def resume_processes(auto_scaling_group_name, options = {})
          if scaling_processes = options.delete('ScalingProcesses')
            options.merge!(AWS.indexed_param('ScalingProcesses.member.%d', [*scaling_processes]))
          end
          request({
            'Action'               => 'ResumeProcesses',
            'AutoScalingGroupName' => auto_scaling_group_name,
            :parser                => Fog::Parsers::AWS::AutoScaling::Basic.new
          }.merge!(options))
        end

      end

      class Mock

        def resume_processes(auto_scaling_group_name, options = {})
          Fog::Mock.not_implemented
        end

      end

    end
  end
end
