require "json"
require "date"

def compute_options(rental)
  if rental["deductible_reduction"]
    fee =  get_rental_days(rental) * 400
  else
    fee = 0
  end
  options = { "deductible_reduction" => fee } 
  return options
end

def compute_fees(total_profit, rental)
  commission = total_profit.to_f * 0.3
  insurance = (commission * 0.5).to_i
  roadside = (get_rental_days(rental) * 100)
  platform_fee = commission - roadside - insurance
  commission_hash = {
                      "insurance_fee": insurance.to_i,
                      "assistance_fee": roadside.to_i,
                      "platform_fee": platform_fee.to_i
                    }
  return commission_hash
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
    commission = compute_fees(price, rental)
    options = compute_options(rental)

    price_hash["rentals"][i] = { "id": i + 1,
                                  "price": price.to_i,
                                  "options": options,
                                  "commission": commission
                              }
  end

  #change json to output_test to make difference between actual and waited results clearer
  File.open("./output_test.json","w") do |f|
    f.puts(JSON.pretty_generate(price_hash))
  end
end

main