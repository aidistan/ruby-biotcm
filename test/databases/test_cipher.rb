require_relative '../test-helper'

describe BioTCM::Databases::Cipher do
  before do
    @cipher = BioTCM::Databases::Cipher.new(['137280', '100050'])
  end

  it "must return omim ids" do
    assert_equal(['137280', '100050'], @cipher.omim_ids)
  end

  it "must build gene tables" do
    assert_instance_of(Table, @cipher.table('137280'))
  end
end
