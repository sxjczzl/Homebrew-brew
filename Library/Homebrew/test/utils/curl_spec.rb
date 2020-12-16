# typed: false
# frozen_string_literal: true

require "utils/curl"

describe "Utils::Curl" do
  let(:headers_ok) {
    <<~EOS
      HTTP/2 200\r
      cache-control: max-age=604800\r
      content-type: text/html; charset=UTF-8\r
      date: Wed, 1 Jan 2020 01:23:45 GMT\r
      expires: Wed, 31 Jan 2020 01:23:45 GMT\r
      last-modified: Thu, 1 Jan 2019 01:23:45 GMT\r
      content-length: 123\r
      \r
    EOS
  }
  let(:headers_ok_array) { [headers_ok.rstrip] }

  let(:location_urls) {
    %w[
      https://example.com/example/
      https://example.com/example1/
      https://example.com/example2/
      https://example.com/example3/
    ]
  }

  let(:headers_redirection) {
    headers_ok.sub(
      "HTTP/2 200\r\n",
      "HTTP/2 301\r\nlocation: #{location_urls[0]}\r\n",
    )
  }

  let(:headers_redirection_to_ok) { "#{headers_redirection}#{headers_ok}" }

  let(:headers_redirections_to_ok) {
    "#{headers_redirection.sub(location_urls[0], location_urls[3])}" \
      "#{headers_redirection.sub(location_urls[0], location_urls[3])}" \
      "#{headers_redirection.sub(location_urls[0], location_urls[1])}" \
      "#{headers_ok}"
  }

  let(:body_content) {
    <<~EOS
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Example</title>
        </head>
        <body>
          <h1>Example</h1>
          <p>Hello, world!</p>
        </body>
      </html>
    EOS
  }

  let(:body_content_with_carriage_returns) { body_content.sub("<html>\n", "<html>\r\n\r\n") }

  let(:body_content_with_http_status_line) { body_content.sub("<html>", "HTTP/2 200\r\n<html>") }

  let(:headers_and_body_content) { "#{headers_ok}#{body_content}" }

  describe "curl_args" do
    let(:args) { "foo" }
    let(:user_agent_string) { "Lorem ipsum dolor sit amet" }

    it "returns --disable as the first argument when HOMEBREW_CURLRC is not set" do
      # --disable must be the first argument according to "man curl"
      expect(curl_args(*args).first).to eq("--disable")
    end

    it "doesn't return `--disable` as the first argument when HOMEBREW_CURLRC is set" do
      ENV["HOMEBREW_CURLRC"] = "1"
      expect(curl_args(*args).first).not_to eq("--disable")
    end

    it "uses `--retry 3` when HOMEBREW_CURL_RETRIES is unset" do
      expect(curl_args(*args).join(" ")).to include("--retry 3")
    end

    it "uses the given value for `--retry` when HOMEBREW_CURL_RETRIES is set" do
      ENV["HOMEBREW_CURL_RETRIES"] = "10"
      expect(curl_args(*args).join(" ")).to include("--retry 10")
    end

    it "doesn't use `--retry` when `:retry` == `false`" do
      expect(curl_args(*args, retry: false).join(" ")).not_to include("--retry")
    end

    it "uses `--retry 3` when `:retry` == `true`" do
      expect(curl_args(*args, retry: true).join(" ")).to include("--retry 3")
    end

    it "uses HOMEBREW_USER_AGENT_FAKE_SAFARI when `:user_agent` is `:browser` or `:fake`" do
      expect(curl_args(*args, user_agent: :browser).join(" "))
        .to include("--user-agent #{HOMEBREW_USER_AGENT_FAKE_SAFARI}")
      expect(curl_args(*args, user_agent: :fake).join(" "))
        .to include("--user-agent #{HOMEBREW_USER_AGENT_FAKE_SAFARI}")
    end

    it "uses HOMEBREW_USER_AGENT_CURL when `:user_agent` is `:default` or omitted" do
      expect(curl_args(*args, user_agent: :default).join(" ")).to include("--user-agent #{HOMEBREW_USER_AGENT_CURL}")
      expect(curl_args(*args, user_agent: nil).join(" ")).to include("--user-agent #{HOMEBREW_USER_AGENT_CURL}")
      expect(curl_args(*args).join(" ")).to include("--user-agent #{HOMEBREW_USER_AGENT_CURL}")
    end

    it "uses provided user agent string when `:user_agent` is a `String`" do
      expect(curl_args(*args, user_agent: user_agent_string).join(" "))
        .to include("--user-agent #{user_agent_string}")
    end

    it "uses `--fail` unless `:show_output` is `true`" do
      expect(curl_args(*args, show_output: false).join(" ")).to include("--fail")
      expect(curl_args(*args, show_output: nil).join(" ")).to include("--fail")
      expect(curl_args(*args).join(" ")).to include("--fail")
      expect(curl_args(*args, show_output: true).join(" ")).not_to include("--fail")
    end
  end

  describe "#response_headers_and_body" do
    it "returns [[headers], \"\"] when response contains headers and no body" do
      expect(response_headers_and_body(headers_ok)).to eq([headers_ok_array, ""])
    end

    it "returns [[], body] when response contains body and no headers" do
      expect(response_headers_and_body(body_content)).to eq([[], body_content])
      expect(response_headers_and_body(body_content_with_carriage_returns))
        .to eq([[], body_content_with_carriage_returns])
      expect(response_headers_and_body(body_content_with_http_status_line))
        .to eq([[], body_content_with_http_status_line])
    end

    it "returns [[headers], body] when response contains headers and body" do
      expect(response_headers_and_body(headers_and_body_content))
        .to eq([headers_ok_array, body_content])
      expect(response_headers_and_body("#{headers_ok}#{body_content_with_carriage_returns}"))
        .to eq([headers_ok_array, body_content_with_carriage_returns])
      expect(response_headers_and_body("#{headers_ok}#{body_content_with_http_status_line}"))
        .to eq([headers_ok_array, body_content_with_http_status_line])
    end

    it "returns [[], \"\"] when response is empty" do
      expect(response_headers_and_body("")).to eq([[], ""])
    end
  end

  describe "#response_status_code_and_location" do
    it "returns [status_code, nil] with no location in headers" do
      expect(response_status_code_and_location(headers_ok_array)).to eq(["200", nil])
      expect(response_status_code_and_location(headers_ok)).to eq(["200", nil])
      expect(response_status_code_and_location(headers_and_body_content)).to eq(["200", nil])
    end

    it "returns [status_code, final_location] with location header(s) present" do
      expect(response_status_code_and_location(headers_redirection_to_ok))
        .to eq(["200", location_urls[0]])
      expect(response_status_code_and_location(headers_redirections_to_ok))
        .to eq(["200", location_urls[1]])
    end

    it "returns absolute location URL with absolutize set to true" do
      expect(response_status_code_and_location(
               headers_redirection_to_ok.sub(
                 location_urls[0],
                 location_urls[0].delete_prefix("https:"),
               ),
               url:        location_urls[0],
               absolutize: true,
             )).to eq(["200", location_urls[0]])

      expect(response_status_code_and_location(
               headers_redirection_to_ok.sub(
                 location_urls[0],
                 location_urls[0].delete_prefix("https://www.example.com"),
               ),
               url:        location_urls[0],
               absolutize: true,
             )).to eq(["200", location_urls[0]])

      expect(response_status_code_and_location(
               headers_redirection_to_ok.sub(
                 location_urls[0],
                 "./subexample/",
               ),
               url:        location_urls[0],
               absolutize: true,
             )).to eq(["200", "#{location_urls[0]}subexample/"])
    end

    it "returns [nil, nil] with body content and no headers" do
      expect(response_status_code_and_location(body_content)).to eq([nil, nil])
    end

    it "returns [nil, nil] when headers are empty" do
      expect(response_status_code_and_location([])).to eq([nil, nil])
      expect(response_status_code_and_location([""])).to eq([nil, nil])
      expect(response_status_code_and_location(["", "", ""])).to eq([nil, nil])
      expect(response_status_code_and_location("")).to eq([nil, nil])
    end
  end
end
