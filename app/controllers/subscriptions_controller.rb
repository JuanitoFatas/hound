class SubscriptionsController < ApplicationController
  class FailedToActivate < StandardError; end

  respond_to :json

  def create
    if activator.activate(repo, github_token) && create_subscription
      render json: repo, status: :created
    else
      activator.deactivate(repo, github_token)
      report_activation_error('Failed to subscribe and activate repo')
      head 502
    end
  end

  def destroy
    repo = current_user.repos.find(params[:repo_id])

    if activator.deactivate(repo, session[:github_token]) && delete_subscription
      render json: repo, status: :created
    else
      report_activation_error('Failed to unsubscribe and deactivate repo')
      head 502
    end
  end

  private

  def report_activation_error(message)
    report_exception(
      FailedToActivate.new(message),
      user_id: current_user.id, repo_id: params[:repo_id]
    )
  end

  def repo
    @repo ||= current_user.repos.find(params[:repo_id])
  end

  def github_token
    session[:github_token]
  end

  def activator
    RepoActivator.new
  end

  def create_subscription
    RepoSubscriber.subscribe(repo, current_user, params[:card_token])
  end

  def delete_subscription
    RepoSubscriber.unsubscribe(repo, current_user)
  end
end
