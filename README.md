from pathlib import Path

# Define the README content

This is a Ruby on Rails backend-only API application that provides analytics for commits on a given GitHub repository using the GitHub GraphQL API.

## 🔧 Features

- List unique commit authors within a given date range.
- Identify commit SHAs and titles that have significant changes (based on Z-score > 2).
- Filter metrics by type (commits, additions, deletions, total_changes) and optionally by author.
- Analyze word frequency in commit messages while ignoring stop words.

## 📦 Requirements

- Ruby 3.2+
- Rails 7+
- Bundler
- GitHub Personal Access Token with `repo` scope

## ⚙️ Setup

1. Clone the repository:

```bash
git clone https://github.com/jester4932/HackHawksBE.git
cd HackHawksBE
bundle install
Rails server
```
