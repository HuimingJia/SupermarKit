class ItemsController < ApplicationController
	extend HappyPath
  follow_happy_paths
  load_and_authorize_resource :grocery
  load_and_authorize_resource :item, through: :grocery, shallow: true

	def index
		respond_to do |format|
			format.json do
		    items = @items.map do |item|
		      info = [
		      	item.id,
		        "<a href='/items/#{item.id}'>#{item.name}</a>".html_safe,
		        item.description,
		        item.price.format,
		        item.updated_at.to_date,
		        "<a class='remove' href='#'><i class='fa fa-remove'></i></a>".html_safe
		      ]
		    end
    		render json: { data: items }
		  end
    end
	end

	def show
		@user_group = @item.groceries.first.user_group
	end

	def new
	end

	def create
		if @item.save
			@item.groceries << @grocery
			redirect_to @grocery
		else
			render action: :new
		end
	end

	def edit
	end

	def update
		if @item.update_attributes(item_params)
			redirect_to @item.groceries.first.user_group
		else
			render :edit
		end
	end

	def auto_complete
		items = @grocery.user_group.items.with_name(params[:q]) - @grocery.items
		items.map do |item|
		  {
				id: item.id,
			 	name: item.name,
				description: item.description
			}
		end

		render json: {
			total_items: items.count,
			items: items
		}
	end

	def add
		items = Item.find(params[:items][:ids].split(","))
		@grocery.items << items
		render json: { success: true }
	end

	def remove
		# the grocery is already loaded because grocery_id was passed with the request
		# cancancan picks up on the grocery_id being passed when using load_resource
		@grocery.items.delete(@item)
		render json: { success: true }
	end

private
	def item_params
		params.require(:item).permit(:name, :description, :price, :price_cents)
	end
end
