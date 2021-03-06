require_relative '../spec_helper'
require "cancan/matchers"
require 'support/abilities_helper'

describe Canard::Abilities, "for guests" do
  include AbilitiesHelper

  subject { Ability.new }

  context 'should be able to' do
    it { can([:create, :activate], any(:user)) }
  end

  context 'should not be able to' do
    it { cant([:accept_invitation, :create_receipts, :update_recipes, :read, :create, :destroy, :update, :manage], any(:user_group)) }
    it { cant([:set_store, :recipes, :checkout, :do_checkout, :email_group, :read, :create, :destroy, :update, :manage], any(:grocery)) }
    it { cant([:auto_complete, :read, :create, :destroy, :update, :manage], any(:item)) }
    it { cant([:default_group, :auto_complete, :read, :destroy, :update, :manage], any(:user)) }
    it { cant([:read, :create, :destroy, :update, :manage], any(:authentication)) }
  end
end
