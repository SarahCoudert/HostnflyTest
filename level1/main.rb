require "json"
require "date"

def compute_price(c, r)
  start_date = DateTime.parse(r["start_date"]).to_date
  end_date = DateTime.parse(r["end_date"]).to_date
  days_of_rental = (end_date - start_date).to_i + 1
  price = days_of_rental * c["price_per_day"]
  price += r["distance"] * c["price_per_km"]
end

def get_car(cars, r)
  cars.each do |car|
    if car["id"] == r["car_id"] then return car end
  end
  return nil
end

file = File.read('data.json')
data = JSON.parse(file)
cars = data["cars"]
rentals = data["rentals"]

price_hash = {}
price_hash["rentals"] = []

rentals.each do |rental|
  i = rental["id"] - 1
  car = get_car(cars, rental)
  price = compute_price(car, rental)
  price_hash["rentals"][i] = { "id": i + 1, "price": price }
end

#change json name to output_test to make the compare between actual and waited result clearer
File.open("./output_test.json","w") do |f|
  f.puts(JSON.pretty_generate(price_hash))
end
