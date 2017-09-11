require "json"
require "date"

def get_deductible_fee(rental)
  if rental["deductible_reduction"]
    fee =  get_rental_days(rental) * 400
  else
    fee = 0
  end
  return fee
end

def generate_fee_hash(who, fee, is_debit)
  type = (is_debit == true) ? "debit" : "credit"
  return {"who": who, "type": type, "amount": fee.to_i}
end

def compute_fees(total_profit, rental)
  commission = total_profit.to_f * 0.3
  assistance = get_rental_days(rental) * 100
  insurance = commission * 0.5
  dedu = get_deductible_fee(rental)

  actions = []
  actions[0] = generate_fee_hash("driver", total_profit + dedu, true)
  actions[1] = generate_fee_hash("owner", total_profit.to_f * 0.7, false)
  actions[2] = generate_fee_hash("insurance", insurance, false)
  actions[3] = generate_fee_hash("assistance", assistance, false)
  actions[4] = generate_fee_hash("platform", commission - assistance - insurance + dedu, false)
  return actions
end

def get_rental_days(r)
  start_date = DateTime.parse(r["start_date"]).to_date
  end_date = DateTime.parse(r["end_date"]).to_date
  return ((end_date - start_date).to_i + 1)
end

def compute_total_price(c, r)
  days_of_rental = get_rental_days(r)
  reduc = 0
  
  #compute reduction
  for i in 1..days_of_rental
    if i > 10
      reduc += c["price_per_day"].to_f * 0.5
    elsif i > 4
      reduc += c["price_per_day"].to_f * 0.3
    elsif i > 1
      reduc += c["price_per_day"].to_f * 0.1
    else
      reduc += 0
    end
  end
  price = (days_of_rental * c['price_per_day']) - reduc
  price += r["distance"] * c["price_per_km"]
end

def get_car(cars, r)
  cars.each do |car|
    if car["id"] == r["car_id"] then return car end
  end
  return nil
end

def main

  file = File.read('data.json')
  data = JSON.parse(file)
  cars = data["cars"]
  rentals = data["rentals"]

  price_hash = {}
  price_hash["rentals"] = []

  rentals.each do |rental|
    i = rental["id"] - 1
    car = get_car(cars, rental)
    price = compute_total_price(car, rental)
    actions = compute_fees(price, rental)

    price_hash["rentals"][i] = { "id": i + 1,
                                  "actions": actions
                              }
  end

  #change json to output_test to make difference between actual and waited results clearer
  File.open("./output_test.json","w") do |f|
    f.puts(JSON.pretty_generate(price_hash))
  end
end

main