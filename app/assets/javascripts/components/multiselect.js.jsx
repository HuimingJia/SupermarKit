var Multiselect = React.createClass({
    propTypes: {
        title: React.PropTypes.string,
        button: React.PropTypes.string,
        selection: React.PropTypes.array,
        handleRemove: React.PropTypes.func,
        hiddenField: React.PropTypes.string
    },

    getInitialState: function() {
        return {
            selection: []
        };
    },

    handleRemove: function(event) {
        var id = parseInt(event.target.closest('.chip').getAttribute('data-id'));
        this.props.handleRemove(id);
    },

    render: function() {
        var button, title, remove;
        if (this.props.button) {
            button = <a href='#' className='waves effect waves light btn secondary activator'>
                        {this.props.button}
                    </a>;
        }

        if (this.props.title) {
            title = <h3>{this.props.title}</h3>;
        }

        if (this.props.handleRemove) {
            remove = <i className='fa fa-close' onClick={this.handleRemove}/>;
        }

        var selection = this.state.selection.map(function(selected) {
            return (
                <div className='chip' data-id={selected.id} key={"selection-" + selected.id} >
                    <img src={selected.gravatar}/>
                    {selected.name}
                    {remove}
                </div>
            );
        });

        return (
            <div className='multiselect' ref='root'>
                {title}
                <div className='selection-container valign-wrapper'>
                    {selection}
                </div>
                {button}
            </div>
        );
    },

    componentDidMount: function() {
        if (!this.props.handleRemove) {
            this.refs.root.addEventListener('selection-updated', function(event) {
                this.setState({ selection: event.detail });
            }.bind(this));
        }
    },

    componentDidUpdate: function(prevProps, prevState) {
        if (this.props.selection !== prevProps.selection) {
            this.setState({ selection: this.props.selection });
        }
        if (this.state.selection !== prevState.selection) {
            if (this.props.hiddenField) {
                document.querySelector(this.props.hiddenField).value = this.state.selection.map(function(selected) {
                    return selected.id
                }).join(',');
            }
        }
    }
});