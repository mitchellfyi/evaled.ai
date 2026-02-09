# frozen_string_literal: true

FactoryBot.define do
  factory :certification do
    association :agent
    tier { :bronze }
    status { :pending }
    applied_at { Time.current }
    reviewer_notes { nil }
    expires_at { nil }

    trait :bronze do
      tier { :bronze }
    end

    trait :silver do
      tier { :silver }
    end

    trait :gold do
      tier { :gold }
    end

    trait :pending do
      status { :pending }
    end

    trait :in_review do
      status { :in_review }
    end

    trait :approved do
      status { :approved }
      expires_at { 90.days.from_now }
    end

    trait :rejected do
      status { :rejected }
      reviewer_notes { "Requirements not met" }
    end

    trait :expired do
      status { :expired }
      expires_at { 1.day.ago }
    end

    trait :active do
      status { :approved }
      expires_at { 30.days.from_now }
    end
  end
end
