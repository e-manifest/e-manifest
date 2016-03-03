require 'rails_helper'

describe 'CDX::UserRoles' do
  it '#perform' do
    VCR.use_cassette('user_roles_perform') do
      opts = { user_id: 'e-manifest-dev', dataflow: 'eManifest' }
      orgs = CDX::UserOrganizations.new(opts, stream_logger).perform
      orgs.each do |org|
        roles = CDX::UserRoles.new(opts.merge(organization: org), stream_logger).perform
        expect(roles[0][:type][:description]).to eq('TSDF Certifier')
      end
    end
  end
end
      
