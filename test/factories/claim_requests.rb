FactoryBot.define do
  factory :claim_request do
    association :agent
    association :user
    status { :pending }
    requested_at { Time.current }

    trait :verified do
      status { :verified }
      verified_at { Time.current }
      github_verification { { method: "repo_access", github_username: "testuser" } }
    end

    trait :rejected do
      status { :rejected }
    end
  end
end
