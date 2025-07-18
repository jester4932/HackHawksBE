
module Api
  module V1
    class GithubAnalyticsController < ApplicationController
      def unique_authors
        data = GithubAnalyticsService.new(params).unique_authors
        render json: data
      end

      def significant_commits
        data = GithubAnalyticsService.new(params).significant_commits
        render json: data
      end

      def commit_metrics
        data = GithubAnalyticsService.new(params).commit_metrics
        render json: data
      end

      def message_word_frequency
        data = GithubAnalyticsService.new(params).commit_message_frequency
        render json: data
      end  
    end
  end
end
