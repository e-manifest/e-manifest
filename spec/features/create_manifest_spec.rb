require 'rails_helper'

feature 'Create manifest' do
  scenario 'create manifest requires authentication' do
    visit new_manifest_path

    expect(page).to have_content('You must be logged in to access this page.')
  end

  scenario 'fills in tracking number' do
    mock_authenticated_session
    manifest_tracking_number = '987654321abc'
    visit new_manifest_path

    fill_in 'Manifest Tracking Number (4)', with: manifest_tracking_number
    click_on 'Continue'

    expect(page).to have_content("Manifest #{manifest_tracking_number} submitted successfully.")
  end

  scenario 'does not fill in tracking number' do
    mock_authenticated_session
    visit new_manifest_path

    click_on 'Continue'

    expect(page).to have_content("Tracking number must be present")
  end

  scenario 'fills in tracking number that does not match validation regex' do
    mock_authenticated_session
    manifest_tracking_number = "invalid"
    visit new_manifest_path

    fill_in 'Manifest Tracking Number (4)', with: manifest_tracking_number
    click_on 'Continue'

    expect(page).to have_content(
      "Tracking number must be 12 characters, starting with 9 numbers and ending with 3 letters"
    )
  end

  scenario 'fills in all fields', :js do
    mock_authenticated_session
    manifest_tracking_number = '987654321abc'
    visit new_manifest_path

    # Generator
    fill_in 'U.S. EPA ID Number (1)', with: 'abc987654321'
    fill_in 'Emergency Response Phone (3)', with: '555-555-5555'
    fill_in 'Manifest Tracking Number (4)', with: manifest_tracking_number
    fill_in 'Name of generator/offeror signatory (15)', with: 'Jane Doe'
    fill_in 'manifest[generator][signatory][date]', with: '2016/11/23'

    # Mailing address
    fill_in 'Name (5)', with: 'Mailing name'
    within('.mailing-address') do
      fill_in_address_fields
    end

    fill_in 'Phone number (5)', with: '555-555-5555'
    find('#manifest_generator_site_address_same_as_mailing_false').trigger('click')

    within('.site-address') do
      fill_in_address_fields
    end

    # Transporters
    within('.transporter') do
      fill_in 'manifest[transporters][][name]', with: 'Transporter company 1 name'
      fill_in 'manifest[transporters][][us_epa_id_number]', with: 'def987654321'
      fill_in 'manifest[transporters][][signatory][name]', with: 'TransporterSigner Smith'
      fill_in 'manifest[transporters][][signatory][date]', with: '2016/11/23'
    end

    # Designated facility
    fill_in 'Name (8)', with: 'Designated facility name'
    fill_in 'Address 1 (8)', with: '123 Designated Facility St.'
    fill_in 'City (8)', with: 'Waterville'
    select 'Maine', from: 'State (8)'
    fill_in 'ZIP code (8)', with: '12345'
    fill_in 'Phone number (8)', with: '555-555-5555'
    fill_in 'U.S. EPA ID Number (8)', with: 'jkl987654321'

    # Manifest items
    within('.manifest-items div.manifest-item:nth-child(1)') do
      select 'True', from: 'This shipment contains hazardous material (9a)'
      fill_in 'Comma separated hazard classes (9b)', with: 'class 1, class 2'
      fill_in 'Proper shipping name (9b)', with: 'Proper shipping name'
      fill_in 'ID number (9b)', with: '12345'
      select 'I', from: 'Packing group (9b)'
      fill_in 'Number of containers (10)', with: 2
      select 'BA (Burlap, cloth, paper or plastic bags)', from: 'Container type (10)'
      select 'Gallons', from: 'Unit Wt./Vol. (12)'
      fill_in 'Total quantity for the listed unit of measure (11)', with: 1
      fill_in 'Comma separated list of federal waste codes (13)', with: 'D004,D003'
      fill_in 'Comma separated list of state and other waste codes (13)', with: 'D004,D003'
    end

    click_on '+ Add an additional manifest item'

    within('.manifest-items div.manifest-item:nth-child(2)') do
      select 'True', from: 'This shipment contains hazardous material (9a)'
      fill_in 'Comma separated hazard classes (9b)', with: 'class 1, class 2'
      fill_in 'Proper shipping name (9b)', with: 'Proper shipping name'
      fill_in 'ID number (9b)', with: '12345'
      select 'I', from: 'Packing group (9b)'
      fill_in 'Number of containers (10)', with: 2
      select 'BA (Burlap, cloth, paper or plastic bags)', from: 'Container type (10)'
      select 'Gallons', from: 'Unit Wt./Vol. (12)'
      fill_in 'Total quantity for the listed unit of measure (11)', with: 1
      fill_in 'Comma separated list of federal waste codes (13)', with: 'D004,D003'
      fill_in 'Comma separated list of state and other waste codes (13)', with: 'D004,D003'
    end


    # Other
    fill_in 'Special handling instructions and additional information (14)', with: 'be careful'
    fill_in 'PCB description (14)', with: 'description'

    # International
    find('#manifest_international_true').trigger('click')
    select 'Export from U.S.', from: 'Import/Export (16)'
    fill_in 'City of Entry/Exit (16)', with: 'Anytown'
    select 'Maine', from: 'State of Entry/Exit (16)'
    fill_in 'manifest[international_shipment][date_leaving_us]', with: '2016/11/23'

    click_on 'Continue'

    expect(page).to have_content("Manifest #{manifest_tracking_number} submitted successfully.")
  end

  private

  def fill_in_address_fields
    fill_in 'Address 1 (5)', with: '123 Main Street'
    fill_in 'City (5)', with: 'Anytown'
    select 'California', from: 'State (5)'
    fill_in 'ZIP code (5)', with: '12345'
  end
end
