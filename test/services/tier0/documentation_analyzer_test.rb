# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Tier0
  class DocumentationAnalyzerTest < ActiveSupport::TestCase
    setup do
      @agent = create(:agent, repo_url: "https://github.com/testowner/testrepo")
      WebMock.enable!
      stub_default_contents
    end

    teardown do
      WebMock.disable!
    end

    test "analyze returns hash with expected keys" do
      result = DocumentationAnalyzer.new(@agent).analyze

      assert result.key?(:readme_length)
      assert result.key?(:has_badges)
      assert result.key?(:sections_found)
      assert result.key?(:has_changelog)
      assert result.key?(:has_contributing)
      assert result.key?(:has_license)
      assert result.key?(:has_docs_folder)
      assert result.key?(:score)
    end

    test "readme_length reflects actual length" do
      readme = "# Project\n\nThis is a test readme with some content."
      stub_readme(readme)

      result = DocumentationAnalyzer.new(@agent).analyze

      assert_equal readme.length, result[:readme_length]
    end

    test "readme_length is 0 when no readme" do
      result = DocumentationAnalyzer.new(@agent).analyze

      assert_equal 0, result[:readme_length]
    end

    test "has_badges is true when badges present" do
      readme = "# Project\n\n![Build](https://badge.svg)"
      stub_readme(readme)

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:has_badges]
    end

    test "has_badges is false when no badges" do
      readme = "# Project\n\nNo badges here"
      stub_readme(readme)

      result = DocumentationAnalyzer.new(@agent).analyze

      assert_not result[:has_badges]
    end

    test "sections_found detects installation section" do
      readme = "# Project\n\n## Installation\n\nRun `npm install`"
      stub_readme(readme)

      result = DocumentationAnalyzer.new(@agent).analyze

      assert_includes result[:sections_found], "installation"
    end

    test "sections_found detects multiple sections" do
      readme = "# Project\n\n## Installation\n\n## Usage\n\n## API\n\n## Examples"
      stub_readme(readme)

      result = DocumentationAnalyzer.new(@agent).analyze

      assert_includes result[:sections_found], "installation"
      assert_includes result[:sections_found], "usage"
      assert_includes result[:sections_found], "api"
      assert_includes result[:sections_found], "examples"
    end

    test "has_changelog is true when CHANGELOG.md exists" do
      stub_file_exists("CHANGELOG.md")

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:has_changelog]
    end

    test "has_changelog is true when HISTORY.md exists" do
      stub_file_exists("HISTORY.md")

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:has_changelog]
    end

    test "has_contributing is true when CONTRIBUTING.md exists" do
      stub_file_exists("CONTRIBUTING.md")

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:has_contributing]
    end

    test "has_license is true when LICENSE exists" do
      stub_file_exists("LICENSE")

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:has_license]
    end

    test "has_docs_folder is true when docs folder exists" do
      stub_folder_exists("docs")

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:has_docs_folder]
    end

    test "score adds 10 for readme over 500 chars" do
      readme = "# Project\n\n" + "x" * 600
      stub_readme(readme)

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:score] >= 10
    end

    test "score adds 20 for readme over 2000 chars" do
      readme = "# Project\n\n" + "x" * 2500
      stub_readme(readme)

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:score] >= 20
    end

    test "score adds 10 for badges" do
      readme = "# Project\n\n![Badge](https://badge.svg)\n" + "x" * 600
      stub_readme(readme)

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:score] >= 20  # 10 for length + 10 for badges
    end

    test "score adds 10 for 3+ sections" do
      readme = "# Project\n\n## Installation\n\n## Usage\n\n## API\n" + "x" * 600
      stub_readme(readme)

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:score] >= 20  # 10 for length + 10 for sections
    end

    test "score adds 10 for changelog" do
      stub_file_exists("CHANGELOG.md")

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:score] >= 10
    end

    test "score adds 10 for contributing" do
      stub_file_exists("CONTRIBUTING.md")

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:score] >= 10
    end

    test "score adds 10 for license" do
      stub_file_exists("LICENSE")

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:score] >= 10
    end

    test "score adds 15 for docs folder" do
      stub_folder_exists("docs")

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:score] >= 15
    end

    test "score adds 15 for examples folder" do
      stub_folder_exists("examples")

      result = DocumentationAnalyzer.new(@agent).analyze

      assert result[:score] >= 15
    end

    test "score caps at 100" do
      readme = "# Project\n\n![Badge](https://badge.svg)\n## Installation\n## Usage\n## API\n" + "x" * 3000
      stub_readme(readme)
      stub_file_exists("CHANGELOG.md")
      stub_file_exists("CONTRIBUTING.md")
      stub_file_exists("LICENSE")
      stub_folder_exists("docs")
      stub_folder_exists("examples")

      result = DocumentationAnalyzer.new(@agent).analyze

      assert_equal 100, result[:score]
    end

    private

    def stub_readme(content)
      stub_request(:get, %r{api.github.com/repos/.*/contents/README\.md})
        .to_return(
          status: 200,
          body: { content: Base64.encode64(content) }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    def stub_file_exists(path)
      stub_request(:get, %r{api.github.com/repos/.*/contents/#{Regexp.escape(path)}})
        .to_return(
          status: 200,
          body: { content: Base64.encode64("content") }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    def stub_folder_exists(path)
      stub_request(:get, %r{api.github.com/repos/.*/contents/#{Regexp.escape(path)}})
        .to_return(
          status: 200,
          body: [ { name: "file1", type: "file" } ].to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    def stub_default_contents
      stub_request(:get, %r{api.github.com/repos/.*/contents/})
        .to_return(status: 404, body: { message: "Not Found" }.to_json)
    end
  end
end
