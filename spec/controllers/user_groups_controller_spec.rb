require 'rails_helper'
require 'support/basic_user'
require 'support/routes'

describe UserGroupsController, type: :controller do
  include_context 'basic user'

  let(:id) { user_group }
  it_should_behave_like 'routes', {
    show: { id: true },
    payments: { id: true },
    index: {},
    new: {}
  }

  describe 'POST create' do
    let(:user_group_params) { attributes_for(:user_group) }
    let(:group_members) { create_list(:user, 3) }
    let(:new_group) { UserGroup.last }
    let(:subject) do
      post :create, params: {
        user_group: user_group_params.merge!(
          user_ids: group_members.map(&:id).join(',')
        )
      }
    end

    context 'with valid params' do
      it 'creates the new group' do
        expect { subject }.to change(UserGroup, :count).by(1)
      end

      it 'assigns the creator as the owner' do
        subject
        expect(new_group.reload.owner).to eq controller.current_user
      end

      it 'adds specified and current user to group' do
        subject
        expect(new_group.users).to match_array(group_members + [controller.current_user])
      end

      context 'without a default group' do
        it 'sets the default group' do
          controller.current_user.update_attribute(:default_group, nil)
          subject
          expect(controller.current_user.default_group).to eq new_group
        end
      end

      context 'with a default group' do
        it 'does not change the default' do
          default_group = create(:user_group)
          controller.current_user.update_attribute(:default_group, default_group)
          subject
          expect(controller.current_user.default_group).to eq default_group
        end
      end

      it 'accepts the current user and invites all others' do
        subject
        current_group_user = new_group.user_groups_users.find_by_user_id(controller.current_user.id)
        remaining_user_group_users = new_group.user_groups_users - [current_group_user]
        expect(current_group_user.state).to eq(UserGroupsUsers::ACCEPTED)

        remaining_user_group_users.each do |user_group_user|
          expect(user_group_user.state).to eq(UserGroupsUsers::INVITED)
        end
      end
    end
  end

  describe 'PATCH update' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:group) { create(:user_group, owner: controller.current_user, users: [user1, user2, controller.current_user]) }
    let(:default_group) { false }
    let(:integration_params) {
      {
        slack: {
          api_token: 'this is an api token',
          message_types: {
            send_checkout_message: {
              enabled: true,
              format: 'Alfred, for {title} {recipients} were gifted.'
            }
          }
        }
      }
    }
    let(:user_group_params) {
      {
        name: 'Test Name',
        description: 'Test description',
        user_ids: "#{controller.current_user.id},#{user2.id}",
        owner_id: user2.id,
      }
    }
    let(:subject) {
      patch :update, params: {
        id: group,
        user_group: user_group_params,
        default_group: default_group,
        integrations: integration_params.to_json.to_s
      }
    }

    context 'current default group' do
      before :each do
        controller.current_user.update_attribute(:default_group, group)
      end

      context 'setting not default group' do
        it 'should set the default group to nil' do
          expect(controller.current_user.default_group).to eq group
          subject
          expect(controller.current_user.default_group).to eq nil
        end
      end

      context 'setting default group' do
        let(:default_group) { true }
        it 'should keep the default group the same' do
          expect(controller.current_user.default_group).to eq group
          subject
          expect(controller.current_user.default_group).to eq group
        end
      end
    end

    context 'currently not default group' do
      before :each do
        @other_group = create(:user_group)
        controller.current_user.update_attribute(:default_group, @other_group)
      end

      context 'setting not default group' do
        it 'should not change the default group' do
          expect(controller.current_user.default_group).to eq @other_group
          subject
          expect(controller.current_user.default_group).to eq @other_group
        end
      end

      context 'setting default group' do
        let(:default_group) { true }
        it 'should update the default group to the current group' do
          expect(controller.current_user.default_group).to eq @other_group
          subject
          expect(controller.current_user.default_group).to eq group
        end
      end
    end

    context 'with existing slackbot' do
      before :each do
        @slackbot = create(:slack_bot, user_group: group)
      end

      context 'updating with an api token' do
        it 'should update the bot to use the new api token' do
          subject
          expect(@slackbot.reload.api_token).to eq 'this is an api token'
        end

        context 'with existing messages' do
          before :each do
            @slackbot.slack_messages << create(:slack_message)
          end

          it 'should update the slackbot messages' do
            subject
            message = @slackbot.reload.slack_messages.first
            expect(message.format).to eq 'Alfred, for {title} {recipients} were gifted.'
            expect(message.enabled).to eq true
          end
        end
      end

      context 'updating without an api token' do
        it 'should remove the bot and all slack messages' do
          integration_params[:slack][:api_token] = ''
          subject
          expect(group.reload.slack_bot).to eq nil
          expect(group.slack_messages).to be_empty
        end
      end
    end

    context 'without existing slackbot' do
      context 'updating with an api token' do
        it 'should create a new slack bot with that token' do
          subject
          expect(group.reload.slack_bot.api_token).to eq 'this is an api token'
        end

        it 'should create slack messages' do
          subject
          message = group.reload.slack_messages.first
          expect(message.format).to eq 'Alfred, for {title} {recipients} were gifted.'
          expect(message.enabled).to eq true
        end
      end

      context 'without an api token' do
        it 'should not create a slackbot' do
          integration_params[:slack][:api_token] = nil
          subject
          expect(group.reload.slack_bot).to eq nil
        end
      end
    end

    context 'when leaving kit' do
      it 'should redirect to the kits index' do
        user_group_params[:user_ids] = user2.id.to_s
        subject
        expect(JSON.parse(response.body)['redirect_url']).to eq user_groups_path
      end
    end

    context 'when not leaving kit' do
      it 'should redirect to the kits show' do
        user_group_params[:user_ids] = controller.current_user.id.to_s
        subject
        expect(JSON.parse(response.body)['redirect_url']).to eq user_group_path(group)
      end
    end

    it 'should update the user group fields' do
      subject
      group.reload
      expect(group.name).to eq 'Test Name'
      expect(group.description).to eq 'Test description'
    end

    it 'should update the owner of the group' do
      expect(group.owner).to eq controller.current_user
      subject
      expect(group.reload.owner).to eq user2
    end

    it 'should replace users with new ones' do
      subject
      expect(group.reload.users).to contain_exactly(controller.current_user, user2)
    end

    it 'should make removed users with that group as a default have no default' do
      user1.update_attribute(:default_group, group)
      expect(user1.default_group).to eq group
      subject
      expect(user1.reload.default_group).to eq nil
    end

    it 'should keep remaining users with that group as a default have that default' do
      user2.update_attribute(:default_group, group)
      expect(user2.default_group).to eq group
      subject
      expect(user2.reload.default_group).to eq group
    end
  end

  describe 'PATCH accept_invitation' do
    it 'should accept the invitation and change UserGroupUser state' do
      user = create(:user)
      user2 = controller.current_user
      user_group = create(:user_group)

      user_group.users << [user, user2]
      user_group.user_groups_users.find_by_user_id(user.id).update_attribute(:state, UserGroupsUsers::ACCEPTED)
      user_group_user = user_group.user_groups_users.find_by_user_id(user2.id)

      expect(user_group_user.state).to eq(UserGroupsUsers::INVITED)
      patch :accept_invitation, params: { id: user_group.id }
      expect(user_group_user.reload.state).to eq(UserGroupsUsers::ACCEPTED)
    end
  end

  describe 'PATCH do_payment' do
    let(:payee) { create(:user) }
    let(:group) { create(:user_group, users: [payee, controller.current_user]) }
    let(:subject) { patch :do_payment, params: { id: group.id, user_group: payment_params } }
    let(:payment_params) {
      {
        reason: 'This is a reason',
        price: 4,
        payee_id: payee.id
      }
    }

    it 'should create the payment with the correct values and users' do
      expect { subject }.to change(UserPayment, :count).by 1
      payment = UserPayment.last
      expect(payment.payer).to eq controller.current_user
      expect(payment.payee).to eq payee
      expect(payment.user_group).to eq group
      expect(payment.price).to eq payment_params[:price].to_money
      expect(payment.reason).to eq payment_params[:reason]
    end
  end

  describe 'PATCH leave' do
    let(:user) { controller.current_user }
    subject { patch :leave, params: { id: @user_group } }

    before :each do
      @user_group = create(:user_group)
      user.user_groups << @user_group
      user.update_attribute(:default_group, @user_group)
    end

    it 'should reset the default group if left group is default' do
      expect(user.reload.default_group).to eq @user_group
      subject
      expect(user.reload.default_group).to eq nil
    end

    it 'should remove the user from the user group' do
      expect(user.user_groups).to include(@user_group)
      subject
      expect(user.reload.user_groups).to_not include(@user_group)
    end
  end
end
