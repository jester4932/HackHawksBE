Rails.application.routes.draw do
  # get 'github/analytics/unique_authors', to: 'github_analytics#unique_authors'
  # get 'github/analytics/significant_commits', to: 'github_analytics#significant_commits'
  # get 'github/analytics/commit_metrics', to: 'github_analytics#commit_metrics'
  # get 'github/analytics/message_word_frequency', to: 'github_analytics#message_word_frequency'
  namespace :api do
    namespace :v1 do
      get 'github/analytics/unique_authors', to: 'github_analytics#unique_authors'
      get 'github/analytics/significant_commits', to: 'github_analytics#significant_commits'
      get 'github/analytics/commit_metrics', to: 'github_analytics#commit_metrics'
      get 'github/analytics/message_word_frequency', to: 'github_analytics#message_word_frequency'
    end
  end
end
# use namespaced routes for also use constants
