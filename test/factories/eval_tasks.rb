# frozen_string_literal: true

FactoryBot.define do
  factory :eval_task do
    sequence(:name) { |n| "Task #{n}" }
    category { "coding" }
    difficulty { "medium" }
    prompt { "Write a function that adds two numbers" }
    description { "A test task" }

    trait :research do
      category { "research" }
      prompt { "Research the latest trends in AI" }
    end

    trait :workflow do
      category { "workflow" }
      prompt { "Automate a deployment pipeline" }
    end

    trait :hard do
      difficulty { "hard" }
    end
  end
end
