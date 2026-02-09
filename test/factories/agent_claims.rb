# frozen_string_literal: true
FactoryBot.define do
  factory :agent_claim do
    association :agent
    association :user
    verification_method { "github_file" }
    verification_data { { token: SecureRandom.hex(16) } }
    status { "pending" }

    trait :verified do
      status { "verified" }
      verified_at { Time.current }
    end

    trait :rejected do
      status { "rejected" }
    end

    trait :expired do
      status { "verified" }
      verified_at { 1.year.ago }
      expires_at { 1.day.ago }
    end

    trait :dns_verification do
      verification_method { "dns_txt" }
    end

    trait :api_key_verification do
      verification_method { "api_key" }
    end
  end
end
