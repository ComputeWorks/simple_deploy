require 'spec_helper'

describe SimpleDeploy::Stack::SSH do
  include_context 'stubbed config'
  include_context 'double stubbed logger'
  include_context 'double stubbed stack', :name        => 'my_stack',
                                          :environment => 'my_env'

  before do
    @task_mock = mock 'task'
    @config_mock.should_receive(:region).and_return 'test-us-west-1'

    @stack_stub.stub(:attributes).and_return({ :ssh_gateway => false })
    @options = { :instances   => ['1.2.3.4', '4.3.2.1'],
                 :environment => 'test-env',
                 :ssh_user    => 'user',
                 :ssh_key     => 'key',
                 :stack       => @stack_stub,
                 :pty         => true,
                 :name        => 'test-stack' }
    @task_logger_mock = mock 'task_logger'
    @ssh_options = Hash.new
    @task_mock.stub :logger    => @task_logger_mock,
                    :variables => @ssh_options
  end

  after do
    SimpleDeploy.release_config
  end

  context "when unsuccessful" do
    it "should return false when no running instances running" do
      @ssh = SimpleDeploy::Stack::SSH.new @options.merge({ :instances   => [] })

      @ssh.execute(:sudo    => true, :command => 'uname').should be_false
    end

    context "with capistrano configured" do
      before do
        Capistrano::Configuration.should_receive(:new).
            with(:output => @logger_stub).
            and_return @task_mock

        @task_logger_mock.should_receive(:level=).with(3)
        @task_mock.should_receive(:set).with :user, 'user'
        @task_mock.should_receive(:server).with('1.2.3.4', :instances)
        @task_mock.should_receive(:server).with('4.3.2.1', :instances)
      end

      it "should return false when Capistrano command error" do
        @ssh = SimpleDeploy::Stack::SSH.new @options

        @task_mock.should_receive(:load).with({ :string=>"task :execute do\n          sudo 'a_bad_command'\n          end" })
        @task_mock.should_receive(:execute).and_raise Capistrano::CommandError.new 'command error'

        @ssh.execute(:sudo => true, :command => 'a_bad_command').should be_false
      end

      it "should return false when Capistrano connection error" do
        @ssh = SimpleDeploy::Stack::SSH.new @options

        @task_mock.stub :logger    => @task_logger_mock,
                        :variables => @ssh_options
        @task_mock.should_receive(:load).with({ :string=>"task :execute do\n          sudo 'uname'\n          end" })
        @task_mock.should_receive(:execute).and_raise Capistrano::ConnectionError.new 'connection error'

        @ssh.execute(:sudo => true, :command => 'uname').should be_false
      end

      it "should return false when Capistrano generic error" do
        @ssh = SimpleDeploy::Stack::SSH.new @options

        @task_mock.should_receive(:load).with({ :string=>"task :execute do\n          sudo 'uname'\n          end" })
        @task_mock.should_receive(:execute).and_raise Capistrano::Error.new 'generic error'

        @ssh.execute(:sudo => true, :command => 'uname').should be_false
      end
    end
  end

  context "when successful" do
    before do
      @ssh = SimpleDeploy::Stack::SSH.new @options
    end

    describe "when execute called" do
      before do
        Capistrano::Configuration.should_receive(:new).
            with(:output => @logger_stub).
            and_return @task_mock

        @task_logger_mock.should_receive(:level=).with(3)
        @task_mock.should_receive(:set).with :user, 'user'
        @task_mock.should_receive(:server).with('1.2.3.4', :instances)
        @task_mock.should_receive(:server).with('4.3.2.1', :instances)
      end

      describe "when successful" do
        it "should execute a task with sudo" do
          @task_mock.should_receive(:load).with({ :string=>"task :execute do\n          sudo 'uname'\n          end" })
          @task_mock.should_receive(:execute).and_return true

          @ssh.execute(:pty     => false,
                       :sudo    => true,
                       :command => 'uname').should be_true
        end

        it "should execute a task as the calling user " do
          @task_mock.should_receive(:load).with({ :string=>"task :execute do\n          run 'uname'\n          end" })
          @task_mock.should_receive(:execute).and_return true

          @ssh.execute(:pty     => false,
                       :sudo    => false,
                       :command => 'uname').should be_true
        end

        it "should set the task variables" do
          @task_mock.should_receive(:load).with({ :string=>"task :execute do\n          run 'uname'\n          end" })
          @task_mock.should_receive(:execute).and_return true

          @ssh.execute(:pty     => false,
                       :sudo    => false,
                       :command => 'uname')
          expect(@task_mock.variables).to eq ({ :ssh_options => { :keys => "key", :paranoid => false } })
        end

        it "should set the pty to true" do
          @task_mock.should_receive(:load).with({ :string=>"task :execute do\n          sudo 'uname'\n          end" })
          @task_mock.should_receive(:execute).and_return true

          @ssh.execute(:pty     => true,
                       :sudo    => true,
                       :command => 'uname')
          expect(@task_mock.variables[:default_run_options]).to eq ({ :pty => true })
        end

        it "sets the ssh options" do
          @task_mock.stub(:load)
          @task_mock.stub(:execute).and_return(true)
          @ssh.execute :sudo => false, :command => 'uname'

          @ssh_options.should == { :ssh_options => { :keys     => 'key',
                                                     :paranoid => false } }
        end
      end
    end
  end
end
