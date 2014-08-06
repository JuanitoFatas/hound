require "spec_helper"

describe RepoSubscriber do
  STRIPE_CUSTOMER_ID = "cus_2e3fqARc1uHtCv"
  STRIPE_SUBSCRIPTION_ID = "sub_488ZZngNkyRMiR"

  describe ".subscribe" do
    context "when Stripe customer exists" do
      it "creates a new Stripe subscription and repo subscription" do
        user = create(:user, stripe_customer_id: STRIPE_CUSTOMER_ID)
        repo = create(:repo)
        user.repos << repo
        stub_customer_find_request
        subscription_request = stub_subscription_create_request

        RepoSubscriber.subscribe(repo, user, "cardtoken")

        expect(subscription_request).to have_been_requested
        expect(repo.subscription.stripe_subscription_id).
          to eq(STRIPE_SUBSCRIPTION_ID)
      end
    end

    context "when Stripe customer does not exist" do
      it "creates a new Stripe subscription and repo subscription" do
        user = create(:user)
        repo = create(:repo)
        user.repos << repo
        stub_customer_create_request(user)
        subscription_request = stub_subscription_create_request

        RepoSubscriber.subscribe(repo, user, "cardtoken")

        expect(subscription_request).to have_been_requested
        expect(repo.subscription.stripe_subscription_id).
          to eq(STRIPE_SUBSCRIPTION_ID)
      end

      it "creates a Stripe customer" do
        user = create(:user)
        repo = create(:repo)
        user.repos << repo
        customer_request = stub_customer_create_request(user)
        stub_subscription_create_request

        RepoSubscriber.subscribe(repo, user, "cardtoken")

        expect(customer_request).to have_been_requested
        expect(user.reload.stripe_customer_id).to eq STRIPE_CUSTOMER_ID
      end
    end

    context "when Stripe subscription fails" do
      it "returns false" do
        user = create(:user)
        repo = create(:repo)
        user.repos << repo
        stub_customer_create_request(user)
        stub_failed_subscription_create_request

        result = RepoSubscriber.subscribe(repo, user, "cardtoken")

        expect(result).to be_false
      end
    end

    context "when repo subscription fails to create" do
      it "deleted the stripe subscription" do
        user = create(:user)
        repo = create(:repo)
        user.repos << repo
        stub_customer_create_request(user)
        stub_subscription_create_request
        stripe_delete_request = stub_subscription_delete_request
        repo.stub(:create_subscription!).and_raise(StandardError)

        result = RepoSubscriber.subscribe(repo, user, "cardtoken")

        expect(result).to be_false
        expect(stripe_delete_request).to have_been_requested
      end
    end
  end

  def stub_customer_create_request(user)
    stub_request(
      :post,
      "https://api.stripe.com/v1/customers"
    ).with(
      body: { "card" => "cardtoken", "metadata" => { "user_id"=>"#{user.id}" } },
      headers: { "Authorization" => "Bearer #{ENV["STRIPE_API_KEY"]}" }
    ).to_return(
      status: 200,
      body: File.read("spec/support/fixtures/stripe_customer_create.json"),
    )
  end

  def stub_customer_find_request
    stub_request(
      :get,
      "https://api.stripe.com/v1/customers/#{STRIPE_CUSTOMER_ID}"
    ).with(
      headers: { "Authorization" => "Bearer #{ENV["STRIPE_API_KEY"]}" }
    ).to_return(
      status: 200,
      body: File.read("spec/support/fixtures/stripe_customer_find.json"),
    )
  end

  def stub_subscription_create_request
    stub_request(
      :post,
      "https://api.stripe.com/v1/customers/#{STRIPE_CUSTOMER_ID}/subscriptions"
    ).with(
      body: { "plan" => "free" },
      headers: { "Authorization" => "Bearer #{ENV["STRIPE_API_KEY"]}",}
    ).to_return(
      status: 200,
      body: File.read("spec/support/fixtures/stripe_subscription_create.json"),
    )
  end

  def stub_subscription_delete_request
    stub_request(
      :delete,
      "https://api.stripe.com/v1/customers/#{STRIPE_CUSTOMER_ID}/subscriptions/#{STRIPE_SUBSCRIPTION_ID}"
    ).with(
      headers: { "Authorization" => "Bearer #{ENV["STRIPE_API_KEY"]}",}
    ).to_return(
      status: 200,
      body: "{}",
    )
  end

  def stub_failed_subscription_create_request
    stub_request(
      :post,
      "https://api.stripe.com/v1/customers/#{STRIPE_CUSTOMER_ID}/subscriptions"
    ).with(
      body: { "plan" => "free" },
      headers: { "Authorization" => "Bearer #{ENV["STRIPE_API_KEY"]}",}
    ).to_return(
      status: 402,
      body: {
        error: {
          message: "Your credit card was declined",
          type: "card_error",
          param: "number",
          code: "incorrect_number"
        }
      }.to_json
    )
  end
end
