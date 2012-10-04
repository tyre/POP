class ProblemsController < ApplicationController
  before_filter :authenticate, :except => [:index, :show]

  def new
    @problem = Problem.new
    @solution = @problem.solutions.new
  end

  def create
    @problem = current_user.problems.new(params[:problem])
    @solution = @problem.solutions.new(params[:problem][:solution])
    if @problem.save
      @solution.save!
      @solution.update_attributes(
        problem_id: @problem.id,
        user_id:    current_user.id,
        original:   true
      )
      redirect_to(@problem, :notice => 'Problem was successfully created.')
      post_to_twitter(@problem) if params[:tweet].present?
    else
      render :action => "new"
    end
  end

  def edit
    @problem = current_user.problems.find(params[:id])
    @solution = @problem.original_solution
  end

  def update
    @problem = current_user.problems.find(params[:id])
    @solution = @problem.solutions.find(params[:id])
    if @problem.update_attributes(params[:problem])
      @solution.update_attributes(params[:problem][:solution])
      redirect_to problem_path(@problem), :alert => 'Problem updated successfully.'
    else
      render :edit, :alert => 'There was an error. Please try again.'
    end
  end

  def index
    @problems = Problem.votes.page(params[:page]).per(10)
  end

  def show
    @problem = Problem.find(params[:id])
  end

  def destroy
    @problem = current_user.problems.find(params[:id])
    if @problem.destroy
      redirect_to problems_path, :notice => "Problem successfully deleted."
    else
      redirect_to problem_path(@problem), :notice => "There was a problem. Try again."
    end
  end

private

  def post_to_twitter(problem)
    if problem.issue.present?
      message = "I just offered a solution to #{problem.issue.name}" +
              "  - #{problem_url(problem)}"
    else
      message = "I just offered a solution. Check it out:" +
                "  - #{problem_url(problem)}"
    end
    # current_user.post_to_twitter(message)
    Resque.enqueue(TwitterPoster, current_user.id, message)
  end
end