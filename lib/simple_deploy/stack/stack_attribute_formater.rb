module SimpleDeploy
  class StackUpdateFormater

    def initialize(args)
      @attributes = args[:attributes]
      @config = args[:config]
      @environment = args[:environment]
      @region = @config.region @environment
    end

    def updated_attributes
      updates = []
      @attributes.each do |attribute|
        key = attribute.keys.first
        if artifact_names.include? key
          updates << cloud_formation_url(attribute)
        end
      end
      @attributes + updates
    end

    def artifact_names
      @config.artifacts.map {|i| i['name']}
    end
    
    def cloud_formation_url attribute
      name = attribute.keys.first
      id = attribute[name]
      a = @config.artifacts.select { |a| a['name'] == name }.first

      endpoint = a['endpoint'] ||= 's3'
      variable = a['variable']
      bucket_prefix = a['bucket_prefix']
      cloud_formation_url = a['cloud_formation_url']

      artifact = Artifact.new :name          => name,
                              :id            => id,
                              :region        => @region,
                              :config        => @config,
                              :bucket_prefix => bucket_prefix

      { cloud_formation_url => artifact.endpoints[endpoint] }
    end

  end
end
