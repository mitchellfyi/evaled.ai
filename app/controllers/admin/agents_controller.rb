module Admin
  class AgentsController < BaseController
    before_action :set_agent, only: [:show, :edit, :update, :destroy]

    def index
      @agents = Agent.all.order(created_at: :desc)
    end

    def show
    end

    def edit
    end

    def update
      if @agent.update(agent_params)
        redirect_to admin_agent_path(@agent), notice: "Agent updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @agent.destroy
      redirect_to admin_agents_path, notice: "Agent deleted successfully."
    end

    private

    def set_agent
      @agent = Agent.find(params[:id])
    end

    def agent_params
      params.require(:agent).permit(:name, :slug, :description, :provider, :url, :active)
    end
  end
end
