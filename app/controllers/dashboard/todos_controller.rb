class Dashboard::TodosController < Dashboard::ApplicationController
  before_action :find_todos, only: [:index, :destroy_all]

  def index
    @todos = @todos.page(params[:page])
  end

  def destroy
    TodoService.new.mark_todos_as_done([todo], current_user)

    respond_to do |format|
      format.html { redirect_to dashboard_todos_path, notice: '待办事项已完成。' }
      format.js { head :ok }
      format.json { render json: todos_counts }
    end
  end

  def destroy_all
    TodoService.new.mark_todos_as_done(@todos, current_user)

    respond_to do |format|
      format.html { redirect_to dashboard_todos_path, notice: '所有待办事项都已完成。' }
      format.js { head :ok }
      format.json { render json: todos_counts }
    end
  end

  private

  def todo
    @todo ||= find_todos.find(params[:id])
  end

  def find_todos
    @todos ||= TodosFinder.new(current_user, params).execute
  end

  def todos_counts
    {
      count: TodosFinder.new(current_user, state: :pending).execute.count,
      done_count: TodosFinder.new(current_user, state: :done).execute.count
    }
  end
end
