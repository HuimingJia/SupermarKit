var Checkout = React.createClass({
    propTypes: {
        users: React.PropTypes.array.isRequired,
        estimated_total: React.PropTypes.number.isRequired
    },

    getInitialState: function() {
        return {
            users: this.props.users.map(function(user) {
                return Object.assign(
                    user,
                    {
                        contributed: true,
                        contribution: 0
                    }
                )
            })
        };
    },

    getIndex: function(e) {
        return parseInt($(e.target).closest('li').data('index'));
    },

    handleContributionToggle: function(e) {
        this.toggleContribution(this.getIndex(e));
    },

    handleContribution: function(e) {
        this.updateContribution(this.getIndex(e), parseInt(e.target.value));
    },

    updateContribution: function(index, value) {
        this.setState({
            users: React.addons.update(
                this.state.users,
                {
                    [index]: {
                        contribution: {
                            $set: value
                        }
                    }
                }
            )
        });
    },

    toggleContribution: function(index) {
        this.setState({
            users: React.addons.update(
                this.state.users,
                {
                    [index]: {
                        contributed: {
                            $set: !this.state.users[index].contributed
                        },
                        contribution: {
                            $set: 0
                        }
                    }
                }
            )
        });
    },

    renderUsers: function() {
        var userContent = this.state.users.map(function(user, index) {
            var userPayment = 'user-' + user.id + '-payment',
                userContribution = 'user-' + user.id + '-contribution';

            var positiveBalance = user.balance > 0;

            return (
                <li
                    className='user-content'
                    key={index}
                    data-index={index}>
                    <div className='valign-wrapper'>
                        <img src={user.gravatar}/>
                        <p className='name'>{user.name}</p>
                    </div>
                    <div className={'balance-wrapper ' + (positiveBalance ? 'positive' : 'negative')}>
                        <label className='balance-label' htmlFor={'balance-section' + index}>Kit balance</label>
                        <div className='balance-section' id={'balance-section-' + index}>
                            <i className='material-icons'>{positiveBalance ? 'call_made' : 'call_received'}</i>
                            <div className='balance'>${user.balance}</div>
                        </div>
                    </div>
                    <div className='input-field'>
                        <label htmlFor={userPayment}>Contribution</label>
                        <input
                            disabled={!user.contributed}
                            id={userPayment}
                            onChange={this.handleContribution}
                            value={user.contribution}
                            type='number'>
                        </input>
                    </div>
                    <input
                        id={userContribution}
                        type='checkbox'
                        className='filled-in'
                        onChange={this.handleContributionToggle}
                        checked={user.contributed}/>
                    <label
                        className='contribution-checkbox'
                        htmlFor={userContribution}/>
                </li>
            );
        }.bind(this));

        return (
            <ul>
                {userContent}
            </ul>
        );
    },

    render: function() {
        var total = this.state.users.reduce(function(acc, user) {
            if (user.contributed && user.contribution) {
                acc += user.contribution;
            }
            return acc;
        }, 0);

        return (
            <div className='checkout'>
                <div className='card'>
                    <div className='card-content'>
                        <h3>Pay for your groceries</h3>
                        <div className='row'>
                            <div className='col l12'>
                                {this.renderUsers()}
                            </div>
                        </div>
                        <div className='totals'>
                            <div className='total'>Total: ${total}</div>
                            <div className='estimated-total'>Estimated Total: ${this.props.estimated_total}</div>
                        </div>
                    </div>
                    <div className='card-action'>
                        <div className='btn'>Checkout</div>
                    </div>
                </div>
            </div>
        );
    }
})