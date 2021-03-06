module AbilitiesHelper
  def any(*args)
    create(*args)
  end

  def can(abilities, object)
    abilities.each { |ability| expect(subject).to be_able_to(ability, object) }
  end
  def cant(abilities, object)
    abilities.each { |ability| expect(subject).to_not be_able_to(ability, object) }
  end

  shared_context 'own objects' do
    let(:own_user_group) { create(:user_group, users: [user, related_user]) }
    let(:own_owned_user_group) { create(:user_group, users: [user, related_user], owner: user) }
    let(:own_grocery) { create(:grocery, user_group: own_user_group) }
    let(:own_item) { create(:item) }
    let(:related_user) { create(:user) }
    let(:own_authentication) { create(:authentication, user_id: user.id) }

    before :each do
      own_item.groceries << own_grocery
    end
  end
end
