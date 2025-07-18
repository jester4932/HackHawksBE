require 'net/http'
require 'uri'
require 'json'

class GithubAnalyticsService
  ENDPOINT = URI("https://api.github.com/graphql")
  METRIC_KEYS = %w[commits additions deletions total_changes].freeze
  STOP_WORDS = %w[the a an and or of to in on at for with by from is are was be this that has have it as you your I we us our their them].freeze

  def initialize(params)
    @owner = ENV.fetch("GITHUB_REPO_OWNER")
    @repo = ENV.fetch("GITHUB_REPO_NAME")
    @token = ENV.fetch("GITHUB_TOKEN")
    @from = normalize_date(params[:from])
    @to = normalize_date(params[:to])
    @metric_type = params[:metric_type]&.downcase
    @filter_author = params[:author]
  end

  def post_graphql(query:, variables:)
    http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(ENDPOINT)
    req["Authorization"] = "Bearer #{@token}"
    req["Content-Type"] = "application/json"
    req.body = { query: query, variables: variables }.to_json

    res = http.request(req)
    JSON.parse(res.body)
  end

  def commits_query(after: nil)
    after_clause = after ? ", after: \"#{after}\"" : ""
    <<~GRAPHQL
      query($owner: String!, $name: String!, $from: GitTimestamp!, $to: GitTimestamp!) {
        repository(owner: $owner, name: $name) {
          defaultBranchRef {
            target {
              ... on Commit {
                history(first: 100, since: $from, until: $to#{after_clause}) {
                  pageInfo {
                    hasNextPage
                    endCursor
                  }
                  edges {
                    node {
                      oid
                      message
                      committedDate
                      author {
                        name
                        email
                        user { login }
                      }
                      additions
                      deletions
                    }
                  }
                }
              }
            }
          }
        }
      }
    GRAPHQL
  end

  def fetch_all_commits
    commits = []
    cursor = nil

    loop do
      response = post_graphql(
        query: commits_query(after: cursor),
        variables: { owner: @owner, name: @repo, from: @from, to: @to }
      )

      edges = response.dig("data", "repository", "defaultBranchRef", "target", "history", "edges") || []
      commits += edges.map { |e| e["node"] }

      page_info = response.dig("data", "repository", "defaultBranchRef", "target", "history", "pageInfo")
      break unless page_info["hasNextPage"]

      cursor = page_info["endCursor"]
    end

    commits
  end

  def unique_authors
    commits = fetch_all_commits
    authors = commits.map { |c| c.dig("author", "user", "login") || c.dig("author", "email") }.compact.uniq
    { authors: authors }
  end

  def significant_commits
    commits = fetch_all_commits
    return { commits: [] } if commits.empty?

    total_changes = commits.map { |c| c["additions"].to_i + c["deletions"].to_i }
    mean = total_changes.sum / total_changes.size.to_f
    stddev = Math.sqrt(total_changes.map { |x| (x - mean)**2 }.sum / total_changes.size.to_f)

    significant = commits.select do |c|
      total = c["additions"].to_i + c["deletions"].to_i
      z_score = stddev.zero? ? 0 : (total - mean) / stddev
      z_score.abs > 2
    end

    significant.map { |c| { sha: c["oid"], message: c["message"] } }
  end

  def commit_metrics
    raise ArgumentError, "Invalid metric_type" unless METRIC_KEYS.include?(@metric_type)

    commits = fetch_all_commits
    commits.select! do |c|
      author_id = c.dig("author", "user", "login") || c.dig("author", "email")
      @filter_author.blank? || author_id == @filter_author
    end

    case @metric_type
    when "commits"
      { count: commits.size }
    when "additions"
      { additions: commits.sum { |c| c["additions"].to_i } }
    when "deletions"
      { deletions: commits.sum { |c| c["deletions"].to_i } }
    when "total_changes"
      { total_changes: commits.sum { |c| c["additions"].to_i + c["deletions"].to_i } }
    end
  end

  def commit_message_frequency
    commits = fetch_all_commits
    messages = commits.map { |c| c["message"] }.join(" ")

    words = messages.downcase.scan(/\b[a-z]{2,}\b/)
    words.reject! { |w| STOP_WORDS.include?(w) }

    freq = words.tally.sort_by { |_word, count| -count }.to_h
    { frequencies: freq }
  end

  private

  def normalize_date(date)
    return date if date.include?("T")

    begin
      Date.parse(date).to_time.utc.iso8601 # => "2025-07-01T00:00:00Z"
    rescue ArgumentError
      raise ArgumentError, "Invalid date format: #{date}"
    end
  end
end
