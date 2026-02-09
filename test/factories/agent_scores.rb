FactoryBot.define do
  factory :agent_score do
    association :agent
    tier { 0 }
    overall_score { 85.0 }
    score_at_eval { 85.0 }
    decay_rate { "standard" }
    evaluated_at { 30.days.ago }
    last_verified_at { 30.days.ago }
    expires_at { 1.year.from_now }

    trait :decayed do
      overall_score { 85.0 }
      score_at_eval { 85.0 }
      evaluated_at { 60.days.ago }
      last_verified_at { 60.days.ago }
    end

    trait :heavily_decayed do
      overall_score { 90.0 }
      score_at_eval { 90.0 }
      evaluated_at { 180.days.ago }
      last_verified_at { 180.days.ago }
    end
  end
end
