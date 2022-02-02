require 'minitest/autorun'
require 'timeout'
require 'pry'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  # Returns the ID of the customer success with most customers
  def execute
    matching_hash = build_matching_hash

    @customers.each do |customer|
      # Find the customer success with least customers which has score greater than the customer success score
      available_cs = available_customer_success(matching_hash, customer)
      # Assign customer to customer success with least customers

      matching_hash[available_cs[0]][:customers] << customer[:id] if available_cs
    end

    customer_success_with_max_customers(matching_hash)
  end

  private def available_customer_success(matching_hash, customer)
    matching_hash
      .select { |_, v| v[:score] >= customer[:score] }
      .min_by { |_, v| v[:customers].length && v[:score] }
  end

  private def customer_success_with_max_customers(matching_hash)
    max_customers = matching_hash.group_by { |_, v| v[:customers].length }.max_by { |customers_size| customers_size }
    max_customers[1].length > 1 ? 0 : max_customers[1].first[0]
  end

  private def build_matching_hash
    matching_hash = {}
    @customer_success.each do |customer_success|
      next if @away_customer_success.include?(customer_success[:id])

      matching_hash[customer_success[:id]] = {
        score: customer_success[:score],
        customers: []
      }
    end

    matching_hash
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10_000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
