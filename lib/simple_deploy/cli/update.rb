require 'trollop'

module SimpleDeploy
  module CLI

    class Update
      include Shared

      def update
        @opts = Trollop::options do
          version SimpleDeploy::VERSION
          banner <<-EOS

Update the attributes for one more stacks.

simple_deploy update -n STACK_NAME1 -n STACK_NAME2 -e ENVIRONMENT -a KEY1=VAL1 -a KEY2=VAL2

EOS
          opt :help, "Display Help"
          opt :attributes, "= seperated attribute and it's value", :type  => :string,
                                                                   :multi => true
          opt :environment, "Set the target environment", :type => :string
          opt :force, "Force an update to proceed"
          opt :log_level, "Log level:  debug, info, warn, error", :type    => :string,
                                                                  :default => 'info'
          opt :name, "Stack name(s) of stack to deploy", :type => :string,
                                                         :multi => true
          opt :read_from_env, "Read credentials and region from environment variables"
          opt :template, "Path to a new template file", :type => :string
        end

        valid_options? :provided => @opts,
                       :required => [:environment, :name, :read_from_env]

        config_arg = @opts[:read_from_env] ? :read_from_env : @opts[:environment]
        SimpleDeploy.create_config config_arg
        SimpleDeploy.logger @opts[:log_level]

        attributes = parse_attributes :attributes => @opts[:attributes]

        @opts[:name].each do |name|
          stack = Stack.new :name        => name,
                            :environment => @opts[:environment]

          if @opts[:template]
            template_body = IO.read @opts[:template]
          end

          rescue_exceptions_and_exit do
            stack.update :force => @opts[:force],
                         :template_body => template_body,
                         :attributes => attributes
          end
        end
      end

      def command_summary
        'Update the attributes for one more stacks'
      end

    end

  end
end
